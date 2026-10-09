import { Router } from "express";
import bcrypt from "bcryptjs";
import { pool } from "../db.js";
import {
  authenticateToken,
  requireRole,
  type AuthenticatedRequest,
} from "../middleware/auth.js";

const router = Router();

router.use(authenticateToken, requireRole("ADMIN"));

router.get("/", async (req, res) => {
  const search =
    typeof req.query.search === "string"
      ? req.query.search.trim()
      : "";

  const role =
    typeof req.query.role === "string"
      ? req.query.role.trim().toUpperCase()
      : "ALL";

  const status =
    typeof req.query.status === "string"
      ? req.query.status.trim().toUpperCase()
      : "ALL";

  if (!["ALL", "STUDENT", "STAFF", "ADMIN"].includes(role)) {
    return res.status(400).json({ error: "Invalid role filter" });
  }

  if (!["ALL", "ACTIVE", "INACTIVE"].includes(status)) {
    return res.status(400).json({ error: "Invalid status filter" });
  }

  try {
    const result = await pool.query(
      `
        SELECT
          u.user_id AS "userId",
          u.full_name AS "fullName",
          u.email,
          r.role_name AS "role",
          u.is_active AS "isActive",
          TO_CHAR(u.created_at, 'YYYY-MM-DD HH24:MI:SS') AS "createdAt"
        FROM users u
        JOIN roles r
          ON r.role_id = u.role_id
        WHERE
          (
            $1 = ''
            OR LOWER(u.full_name) LIKE '%' || LOWER($1) || '%'
            OR LOWER(u.email) LIKE '%' || LOWER($1) || '%'
          )
          AND ($2 = 'ALL' OR r.role_name = $2)
          AND (
            $3 = 'ALL'
            OR ($3 = 'ACTIVE' AND u.is_active = 'Y')
            OR ($3 = 'INACTIVE' AND u.is_active = 'N')
          )
        ORDER BY u.user_id
      `,
      [search, role, status],
    );

    const users = result.rows.map((row) => ({
      userId: Number(row.userId),
      fullName: row.fullName,
      email: row.email,
      role: row.role,
      status: row.isActive === "Y" ? "ACTIVE" : "INACTIVE",
      createdAt: row.createdAt,
    }));

    return res.json({ users });
  } catch (error) {
    console.error("USER LIST ERROR:", error);

    return res.status(500).json({
      error: "Unable to load users",
    });
  }
});

router.post("/staff", async (req, res) => {
  const { fullName, email, password } = req.body;

  if (!fullName || !email || !password) {
    return res.status(400).json({
      error: "fullName, email and password are required",
    });
  }

  if (typeof password !== "string" || password.length < 6) {
    return res.status(400).json({
      error: "Password must be at least 6 characters",
    });
  }

  const normalizedName = String(fullName).trim();
  const normalizedEmail = String(email).trim().toLowerCase();

  if (!normalizedName || !normalizedEmail) {
    return res.status(400).json({
      error: "Name and email are required",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const existing = await client.query(
      `
        SELECT user_id
        FROM users
        WHERE LOWER(email) = $1
      `,
      [normalizedEmail],
    );

    if (existing.rows.length > 0) {
      await client.query("ROLLBACK");

      return res.status(409).json({
        error: "Email is already registered",
      });
    }

    const roleResult = await client.query(
      `
        SELECT role_id
        FROM roles
        WHERE role_name = 'STAFF'
      `,
    );

    if (roleResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(500).json({
        error: "STAFF role not found",
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = await client.query(
      `
        INSERT INTO users (
          role_id,
          full_name,
          email,
          password_hash,
          is_active
        )
        VALUES ($1, $2, $3, $4, 'Y')
        RETURNING user_id
      `,
      [
        roleResult.rows[0].role_id,
        normalizedName,
        normalizedEmail,
        passwordHash,
      ],
    );

    await client.query("COMMIT");

    return res.status(201).json({
      userId: result.rows[0].user_id,
      fullName: normalizedName,
      email: normalizedEmail,
      role: "STAFF",
      status: "ACTIVE",
    });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error("STAFF CREATION ERROR:", error);

    return res.status(500).json({
      error: "Unable to create staff account",
    });
  } finally {
    client.release();
  }
});

router.patch(
  "/:userId/status",
  async (req: AuthenticatedRequest, res) => {
    const userId = Number(req.params.userId);
    const status = req.body?.status;

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        error: "Invalid user ID",
      });
    }

    if (status !== "Y" && status !== "N") {
      return res.status(400).json({
        error: "Status must be Y or N",
      });
    }

    if (req.user?.userId === userId) {
      return res.status(400).json({
        error: "You cannot change your own account status",
      });
    }

    try {
      const result = await pool.query(
        `
          UPDATE users
          SET is_active = $1
          WHERE user_id = $2
        `,
        [status, userId],
      );

      if (result.rowCount !== 1) {
        return res.status(404).json({
          error: "User not found",
        });
      }

      return res.json({
        message:
          status === "Y"
            ? "Account activated"
            : "Account deactivated",
      });
    } catch (error) {
      console.error("USER STATUS ERROR:", error);

      return res.status(500).json({
        error: "Unable to update account status",
      });
    }
  },
);

router.patch(
  "/:userId/role",
  async (req: AuthenticatedRequest, res) => {
    const userId = Number(req.params.userId);
    const role = req.body?.role;

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        error: "Invalid user ID",
      });
    }

    if (role !== "STUDENT" && role !== "STAFF") {
      return res.status(400).json({
        error:
          "Role can only be changed between STUDENT and STAFF",
      });
    }

    if (req.user?.userId === userId) {
      return res.status(400).json({
        error: "You cannot change your own role",
      });
    }

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      const roleResult = await client.query(
        `
          SELECT role_id
          FROM roles
          WHERE role_name = $1
        `,
        [role],
      );

      if (roleResult.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(400).json({
          error: "Selected role does not exist",
        });
      }

      const result = await client.query(
        `
          UPDATE users
          SET role_id = $1
          WHERE user_id = $2
            AND role_id IN (
              SELECT role_id
              FROM roles
              WHERE role_name IN ('STUDENT', 'STAFF')
            )
        `,
        [roleResult.rows[0].role_id, userId],
      );

      if (result.rowCount !== 1) {
        const target = await client.query(
          `
            SELECT r.role_name
            FROM users u
            JOIN roles r
              ON r.role_id = u.role_id
            WHERE u.user_id = $1
          `,
          [userId],
        );

        await client.query("ROLLBACK");

        if (target.rows.length === 0) {
          return res.status(404).json({
            error: "User not found",
          });
        }

        return res.status(400).json({
          error:
            "ADMIN accounts cannot be changed to STUDENT or STAFF here",
        });
      }

      await client.query("COMMIT");

      return res.json({
        message: `User role changed to ${role}`,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("USER ROLE ERROR:", error);

      return res.status(500).json({
        error: "Unable to update user role",
      });
    } finally {
      client.release();
    }
  },
);

router.patch(
  "/:userId/password",
  async (req: AuthenticatedRequest, res) => {
    const userId = Number(req.params.userId);
    const password = req.body?.password;

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        error: "Invalid user ID",
      });
    }

    if (typeof password !== "string" || password.length < 6) {
      return res.status(400).json({
        error: "Password must be at least 6 characters",
      });
    }

    if (req.user?.userId === userId) {
      return res.status(400).json({
        error:
          "Use the account recovery/password change flow for your own account",
      });
    }

    try {
      const passwordHash = await bcrypt.hash(password, 12);

      const result = await pool.query(
        `
          UPDATE users
          SET password_hash = $1
          WHERE user_id = $2
        `,
        [passwordHash, userId],
      );

      if (result.rowCount !== 1) {
        return res.status(404).json({
          error: "User not found",
        });
      }

      return res.json({
        message: "Password reset successfully",
      });
    } catch (error) {
      console.error("PASSWORD RESET ERROR:", error);

      return res.status(500).json({
        error: "Unable to reset password",
      });
    }
  },
);

export default router;