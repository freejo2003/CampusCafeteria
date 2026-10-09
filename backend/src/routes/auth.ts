import { Router } from "express";
import bcrypt from "bcryptjs";
import { pool } from "../db.js";
import jwt from "jsonwebtoken";

const router = Router();

router.post("/register", async (req, res) => {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
        return res.status(400).json({
            error: "fullName, email and password are required"
        });
    }

    if (typeof password !== "string" || password.length < 6) {
        return res.status(400).json({
            error: "Password must be at least 6 characters"
        });
    }

    const client = await pool.connect();

    try {
        const normalizedEmail = String(email).trim().toLowerCase();
        const normalizedName = String(fullName).trim();

        const existingUser = await client.query(
            `SELECT user_id
             FROM users
             WHERE LOWER(email) = $1`,
            [normalizedEmail]
        );

        if (existingUser.rows.length > 0) {
            return res.status(409).json({
                error: "Email is already registered"
            });
        }

        const roleResult = await client.query(
            `SELECT role_id
             FROM roles
             WHERE role_name = 'STUDENT'`
        );

        if (roleResult.rows.length === 0) {
            return res.status(500).json({
                error: "STUDENT role not found"
            });
        }

        const roleId = roleResult.rows[0].role_id;

        const passwordHash = await bcrypt.hash(password, 12);

        const result = await client.query(
            `INSERT INTO users
             (
                 role_id,
                 full_name,
                 email,
                 password_hash,
                 is_active
             )
             VALUES
             (
                 $1,
                 $2,
                 $3,
                 $4,
                 'Y'
             )
             RETURNING user_id`,
            [
                roleId,
                normalizedName,
                normalizedEmail,
                passwordHash
            ]
        );

        await client.query("COMMIT");

        const userId = result.rows[0].user_id;

        return res.status(201).json({
            message: "Registration successful",
            userId,
            fullName: normalizedName,
            email: normalizedEmail,
            role: "STUDENT"
        });

    } catch (error) {
        await client.query("ROLLBACK");

        console.error("REGISTRATION ERROR:");
        console.error(error);

        return res.status(500).json({
            error: "Registration failed"
        });

    } finally {
        client.release();
    }
});

router.post("/login", async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({
            error: "email and password are required"
        });
    }

    const client = await pool.connect();

    try {
        const normalizedEmail = String(email).trim().toLowerCase();

        const result = await client.query(
            `SELECT
                 u.user_id,
                 u.full_name,
                 u.email,
                 u.password_hash,
                 u.is_active,
                 r.role_name
             FROM users u
             JOIN roles r
                 ON r.role_id = u.role_id
             WHERE LOWER(u.email) = $1`,
            [normalizedEmail]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                error: "Invalid email or password"
            });
        }

        const row = result.rows[0];

        const userId = row.user_id;
        const fullName = row.full_name;
        const userEmail = row.email;
        const passwordHash = row.password_hash;
        const isActive = row.is_active;
        const role = row.role_name;

        if (isActive !== "Y") {
            return res.status(403).json({
                error: "Account is inactive"
            });
        }

        const passwordValid = await bcrypt.compare(
            password,
            passwordHash
        );

        if (!passwordValid) {
            return res.status(401).json({
                error: "Invalid email or password"
            });
        }

        const JWT_SECRET: string = process.env.JWT_SECRET ?? (() => {
            throw new Error("JWT_SECRET is not configured");
        })();

        const token = jwt.sign(
            {
                userId,
                email: userEmail,
                role
            },
            JWT_SECRET,
            {
                expiresIn: "2h"
            }
        );

        return res.json({
            message: "Login successful",
            token,
            userId,
            fullName,
            email: userEmail,
            role
        });

    } catch (error) {
        console.error("LOGIN ERROR:");
        console.error(error);

        return res.status(500).json({
            error: "Login failed"
        });

    } finally {
        client.release();
    }
});

export default router;