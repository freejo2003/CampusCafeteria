import { Router } from "express";
import { pool } from "../db.js";
import {
  authenticateToken,
  requireRole,
} from "../middleware/auth.js";

const router = Router();

interface MenuItemRow {
  menuItemId: number;
  itemName: string;
  description: string;
  price: number;
  isAvailable: string;
  stockQuantity?: number;
}

interface IngredientRow {
  menuItemId: number;
  ingredientName: string;
}

interface IngredientCatalogRow {
  ingredientId: number;
  ingredientName: string;
}

interface PickupWindowRow {
  pickupWindowId: number;
  startTime: string;
  endTime: string;
  capacity: number;
  reservedCount: number;
  availableCapacity: number;
}

interface AdminMenuDateRow {
  menuDateId: number;
  menuDate: string;
  isPublished: string;
}

function isValidDate(value: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function isValidTime(value: string): boolean {
  return /^([01]\d|2[0-3]):[0-5]\d$/.test(value);
}

/*
 * --------------------------------------------------------------------------
 * STUDENT / STAFF / ADMIN - PUBLISHED MENU
 * GET /api/menu?date=YYYY-MM-DD
 * --------------------------------------------------------------------------
 */
router.get(
  "/",
  authenticateToken,
  requireRole("STUDENT", "STAFF", "ADMIN"),
  async (req, res) => {
    try {
      const date = String(req.query.date ?? "");

      if (!date || !isValidDate(date)) {
        return res.status(400).json({
          error: "date query parameter is required. Use YYYY-MM-DD.",
        });
      }

      const menuResult = await pool.query(
        `
        SELECT
          mi.menu_item_id AS "menuItemId",
          mi.item_name AS "itemName",
          mi.description AS "description",
          mi.price AS "price",
          mi.is_available AS "isAvailable",
          COALESCE(s.available_qty, 0) AS "stockQuantity"
        FROM menu_dates md
        JOIN menu_items mi
          ON mi.menu_date_id = md.menu_date_id
        LEFT JOIN stock s
          ON s.menu_item_id = mi.menu_item_id
        WHERE md.menu_date = $1::date
          AND md.is_published = 'Y'
        ORDER BY mi.menu_item_id
        `,
        [date],
      );

      const ingredientResult = await pool.query(
        `
        SELECT
          ii.menu_item_id AS "menuItemId",
          i.ingredient_name AS "ingredientName"
        FROM item_ingredients ii
        JOIN ingredients i
          ON i.ingredient_id = ii.ingredient_id
        JOIN menu_items mi
          ON mi.menu_item_id = ii.menu_item_id
        JOIN menu_dates md
          ON md.menu_date_id = mi.menu_date_id
        WHERE md.menu_date = $1::date
        ORDER BY ii.menu_item_id, i.ingredient_name
        `,
        [date],
      );

      const pickupResult = await pool.query(
        `
        SELECT
          pickup_window_id AS "pickupWindowId",
          TO_CHAR(start_time, 'HH24:MI') AS "startTime",
          TO_CHAR(end_time, 'HH24:MI') AS "endTime",
          capacity AS "capacity",
          reserved_count AS "reservedCount",
          capacity - reserved_count AS "availableCapacity"
        FROM pickup_windows
        WHERE window_date = $1::date
        ORDER BY start_time
        `,
        [date],
      );

      const ingredientsByItem = new Map<number, string[]>();

      for (const ingredient of ingredientResult.rows as IngredientRow[]) {
        if (!ingredientsByItem.has(ingredient.menuItemId)) {
          ingredientsByItem.set(ingredient.menuItemId, []);
        }

        ingredientsByItem
          .get(ingredient.menuItemId)!
          .push(ingredient.ingredientName);
      }

      const items = (menuResult.rows as MenuItemRow[]).map((item) => ({
        ...item,
        price: Number(item.price),
        stockQuantity: Number(item.stockQuantity ?? 0),
        ingredients: ingredientsByItem.get(item.menuItemId) ?? [],
      }));

      return res.json({
        date,
        items,
        pickupWindows: pickupResult.rows.map((row) => ({
          ...row,
          capacity: Number(row.capacity),
          reservedCount: Number(row.reservedCount),
          availableCapacity: Number(row.availableCapacity),
        })),
      });
    } catch (error) {
      console.error("Menu API error:", error);

      return res.status(500).json({
        error: "Failed to retrieve menu.",
      });
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - MENU DATES
 * GET /api/menu/admin/dates
 * --------------------------------------------------------------------------
 */
router.get(
  "/admin/dates",
  authenticateToken,
  requireRole("ADMIN"),
  async (_req, res) => {
    try {
      const result = await pool.query(
        `
        SELECT
          md.menu_date_id AS "menuDateId",
          TO_CHAR(md.menu_date, 'YYYY-MM-DD') AS "menuDate",
          md.is_published AS "isPublished",
          COUNT(mi.menu_item_id) AS "itemCount"
        FROM menu_dates md
        LEFT JOIN menu_items mi
          ON mi.menu_date_id = md.menu_date_id
        GROUP BY
          md.menu_date_id,
          md.menu_date,
          md.is_published
        ORDER BY md.menu_date DESC
        `,
      );

      return res.json({
        dates: result.rows.map((row) => ({
          ...row,
          itemCount: Number(row.itemCount),
        })),
      });
    } catch (error) {
      console.error("Admin menu dates error:", error);

      return res.status(500).json({
        error: "Failed to retrieve menu dates.",
      });
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - CREATE MENU DATE
 * POST /api/menu/admin/dates
 * --------------------------------------------------------------------------
 */
router.post(
  "/admin/dates",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const menuDate = String(req.body.menuDate ?? "");
      const isPublished = String(
        req.body.isPublished ?? "N",
      ).toUpperCase();

      if (!isValidDate(menuDate)) {
        return res.status(400).json({
          error: "menuDate must use YYYY-MM-DD format.",
        });
      }

      if (!["Y", "N"].includes(isPublished)) {
        return res.status(400).json({
          error: "isPublished must be Y or N.",
        });
      }

      await client.query("BEGIN");

      const existing = await client.query(
        `
        SELECT menu_date_id
        FROM menu_dates
        WHERE menu_date = $1::date
        `,
        [menuDate],
      );

      if (existing.rows.length > 0) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error: "A menu date already exists for this date.",
        });
      }

      const created = await client.query(
        `
        INSERT INTO menu_dates (
          menu_date,
          is_published
        )
        VALUES (
          $1::date,
          $2
        )
        RETURNING
          menu_date_id AS "menuDateId",
          TO_CHAR(menu_date, 'YYYY-MM-DD') AS "menuDate",
          is_published AS "isPublished"
        `,
        [menuDate, isPublished],
      );

      await client.query("COMMIT");

      const row = created.rows[0] as
        | AdminMenuDateRow
        | undefined;

      if (!row) {
        return res.status(500).json({
          error: "Menu date was created but could not be retrieved.",
        });
      }

      return res.status(201).json({
        message: "Menu date created successfully.",
        menuDateId: Number(row.menuDateId),
        menuDate: row.menuDate,
        isPublished: row.isPublished,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Create menu date error:", error);

      return res.status(500).json({
        error: "Failed to create menu date.",
      });
    } finally {
      client.release();
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - PUBLISH / UNPUBLISH MENU DATE
 * PATCH /api/menu/admin/dates/:menuDateId
 * --------------------------------------------------------------------------
 */
router.patch(
  "/admin/dates/:menuDateId",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    try {
      const menuDateId = Number(req.params.menuDateId);
      const isPublished = String(
        req.body.isPublished ?? "",
      ).toUpperCase();

      if (!Number.isInteger(menuDateId) || menuDateId <= 0) {
        return res.status(400).json({
          error: "Invalid menu date ID.",
        });
      }

      if (!["Y", "N"].includes(isPublished)) {
        return res.status(400).json({
          error: "isPublished must be Y or N.",
        });
      }

      const result = await pool.query(
        `
        UPDATE menu_dates
        SET is_published = $1
        WHERE menu_date_id = $2
        `,
        [isPublished, menuDateId],
      );

      if (result.rowCount !== 1) {
        return res.status(404).json({
          error: "Menu date not found.",
        });
      }

      return res.json({
        message:
          isPublished === "Y"
            ? "Menu published successfully."
            : "Menu unpublished successfully.",
        menuDateId,
        isPublished,
      });
    } catch (error) {
      console.error("Update menu publication error:", error);

      return res.status(500).json({
        error: "Failed to update menu publication status.",
      });
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - MENU FOR A SPECIFIC DATE
 * GET /api/menu/admin?date=YYYY-MM-DD
 * --------------------------------------------------------------------------
 */
router.get(
  "/admin",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    try {
      const date = String(req.query.date ?? "");

      if (!date || !isValidDate(date)) {
        return res.status(400).json({
          error: "date query parameter is required. Use YYYY-MM-DD.",
        });
      }

      const dateResult = await pool.query(
        `
        SELECT
          menu_date_id AS "menuDateId",
          TO_CHAR(menu_date, 'YYYY-MM-DD') AS "menuDate",
          is_published AS "isPublished"
        FROM menu_dates
        WHERE menu_date = $1::date
        `,
        [date],
      );

      const menuDate = dateResult.rows[0];

      if (!menuDate) {
        return res.status(404).json({
          error: "Menu date not found.",
        });
      }

      const itemResult = await pool.query(
        `
        SELECT
          mi.menu_item_id AS "menuItemId",
          mi.item_name AS "itemName",
          mi.description AS "description",
          mi.price AS "price",
          mi.is_available AS "isAvailable",
          COALESCE(s.available_qty, 0) AS "stockQuantity"
        FROM menu_items mi
        LEFT JOIN stock s
          ON s.menu_item_id = mi.menu_item_id
        WHERE mi.menu_date_id = $1
        ORDER BY mi.menu_item_id
        `,
        [menuDate.menuDateId],
      );

      const ingredientResult = await pool.query(
        `
        SELECT
          ii.menu_item_id AS "menuItemId",
          i.ingredient_name AS "ingredientName"
        FROM item_ingredients ii
        JOIN ingredients i
          ON i.ingredient_id = ii.ingredient_id
        JOIN menu_items mi
          ON mi.menu_item_id = ii.menu_item_id
        WHERE mi.menu_date_id = $1
        ORDER BY ii.menu_item_id, i.ingredient_name
        `,
        [menuDate.menuDateId],
      );

      const ingredientsByItem = new Map<number, string[]>();

      for (const ingredient of ingredientResult.rows as IngredientRow[]) {
        if (!ingredientsByItem.has(ingredient.menuItemId)) {
          ingredientsByItem.set(ingredient.menuItemId, []);
        }

        ingredientsByItem
          .get(ingredient.menuItemId)!
          .push(ingredient.ingredientName);
      }

      const items = (itemResult.rows as MenuItemRow[]).map((item) => ({
        ...item,
        price: Number(item.price),
        stockQuantity: Number(item.stockQuantity ?? 0),
        ingredients: ingredientsByItem.get(item.menuItemId) ?? [],
      }));

      return res.json({
        ...menuDate,
        items,
      });
    } catch (error) {
      console.error("Admin menu error:", error);

      return res.status(500).json({
        error: "Failed to retrieve admin menu.",
      });
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - PICKUP WINDOW MANAGEMENT
 * --------------------------------------------------------------------------
 */

router.get(
  "/admin/pickup-windows",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    try {
      const date = String(req.query.date ?? "");

      if (!date || !isValidDate(date)) {
        return res.status(400).json({
          error: "date query parameter is required. Use YYYY-MM-DD.",
        });
      }

      const dateCheck = await pool.query(
        `
        SELECT menu_date_id
        FROM menu_dates
        WHERE menu_date = $1::date
        `,
        [date],
      );

      if (dateCheck.rows.length === 0) {
        return res.status(404).json({
          error: "Menu date not found.",
        });
      }

      const result = await pool.query(
        `
        SELECT
          pickup_window_id AS "pickupWindowId",
          TO_CHAR(start_time, 'HH24:MI') AS "startTime",
          TO_CHAR(end_time, 'HH24:MI') AS "endTime",
          capacity AS "capacity",
          reserved_count AS "reservedCount",
          capacity - reserved_count AS "availableCapacity"
        FROM pickup_windows
        WHERE window_date = $1::date
        ORDER BY start_time
        `,
        [date],
      );

      return res.json({
        date,
        pickupWindows: result.rows.map((row) => ({
          ...row,
          capacity: Number(row.capacity),
          reservedCount: Number(row.reservedCount),
          availableCapacity: Number(row.availableCapacity),
        })),
      });
    } catch (error) {
      console.error("Admin pickup windows error:", error);

      return res.status(500).json({
        error: "Failed to retrieve pickup windows.",
      });
    }
  },
);

router.post(
  "/admin/pickup-windows",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const menuDate = String(req.body.menuDate ?? "");
      const startTime = String(req.body.startTime ?? "");
      const endTime = String(req.body.endTime ?? "");
      const capacity = Number(req.body.capacity);

      if (!isValidDate(menuDate)) {
        return res.status(400).json({
          error: "menuDate must use YYYY-MM-DD format.",
        });
      }

      if (!isValidTime(startTime)) {
        return res.status(400).json({
          error: "startTime must use HH:MM format.",
        });
      }

      if (!isValidTime(endTime)) {
        return res.status(400).json({
          error: "endTime must use HH:MM format.",
        });
      }

      if (startTime >= endTime) {
        return res.status(400).json({
          error: "End time must be later than start time.",
        });
      }

      if (!Number.isInteger(capacity) || capacity <= 0) {
        return res.status(400).json({
          error: "capacity must be a positive integer.",
        });
      }

      await client.query("BEGIN");

      const dateCheck = await client.query(
        `
        SELECT menu_date_id
        FROM menu_dates
        WHERE menu_date = $1::date
        `,
        [menuDate],
      );

      if (dateCheck.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          error: "Menu date not found. Create the menu date first.",
        });
      }

      const overlap = await client.query(
        `
        SELECT pickup_window_id
        FROM pickup_windows
        WHERE window_date = $1::date
          AND start_time < ($1::date + $3::time)
          AND end_time > ($1::date + $2::time)
        `,
        [menuDate, startTime, endTime],
      );

      if (overlap.rows.length > 0) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error: "Pickup window overlaps an existing window for this date.",
        });
      }

      const result = await client.query(
        `
        INSERT INTO pickup_windows (
          window_date,
          start_time,
          end_time,
          capacity,
          reserved_count
        )
        VALUES (
          $1::date,
          $1::date + $2::time,
          $1::date + $3::time,
          $4,
          0
        )
        RETURNING pickup_window_id
        `,
        [
          menuDate,
          startTime,
          endTime,
          capacity,
        ],
      );

      await client.query("COMMIT");

      const pickupWindowId = Number(
        result.rows[0].pickup_window_id,
      );

      return res.status(201).json({
        message: "Pickup window created successfully.",
        pickupWindowId,
        menuDate,
        startTime,
        endTime,
        capacity,
        reservedCount: 0,
        availableCapacity: capacity,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Create pickup window error:", error);

      return res.status(500).json({
        error: "Failed to create pickup window.",
      });
    } finally {
      client.release();
    }
  },
);

router.patch(
  "/admin/pickup-windows/:pickupWindowId",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const pickupWindowId = Number(req.params.pickupWindowId);
      const startTime = String(req.body.startTime ?? "");
      const endTime = String(req.body.endTime ?? "");
      const capacity = Number(req.body.capacity);

      if (!Number.isInteger(pickupWindowId) || pickupWindowId <= 0) {
        return res.status(400).json({
          error: "Invalid pickup window ID.",
        });
      }

      if (!isValidTime(startTime)) {
        return res.status(400).json({
          error: "startTime must use HH:MM format.",
        });
      }

      if (!isValidTime(endTime)) {
        return res.status(400).json({
          error: "endTime must use HH:MM format.",
        });
      }

      if (startTime >= endTime) {
        return res.status(400).json({
          error: "End time must be later than start time.",
        });
      }

      if (!Number.isInteger(capacity) || capacity <= 0) {
        return res.status(400).json({
          error: "capacity must be a positive integer.",
        });
      }

      await client.query("BEGIN");

      const currentResult = await client.query(
        `
        SELECT
          pickup_window_id,
          reserved_count,
          TO_CHAR(window_date, 'YYYY-MM-DD') AS window_date
        FROM pickup_windows
        WHERE pickup_window_id = $1
        FOR UPDATE
        `,
        [pickupWindowId],
      );

      const current = currentResult.rows[0];

      if (!current) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          error: "Pickup window not found.",
        });
      }

      const reservedCount = Number(
        current.reserved_count ?? 0,
      );

      const windowDate = String(
        current.window_date ?? "",
      );

      if (capacity < reservedCount) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error: `Capacity cannot be reduced below the ${reservedCount} already reserved orders.`,
        });
      }

      const overlap = await client.query(
        `
        SELECT pickup_window_id
        FROM pickup_windows
        WHERE window_date = $1::date
          AND pickup_window_id <> $2
          AND start_time < ($1::date + $4::time)
          AND end_time > ($1::date + $3::time)
        `,
        [
          windowDate,
          pickupWindowId,
          startTime,
          endTime,
        ],
      );

      if (overlap.rows.length > 0) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error: "Pickup window overlaps another window for this date.",
        });
      }

      await client.query(
        `
        UPDATE pickup_windows
        SET
          start_time = $2::date + $3::time,
          end_time = $2::date + $4::time,
          capacity = $5
        WHERE pickup_window_id = $1
        `,
        [
          pickupWindowId,
          windowDate,
          startTime,
          endTime,
          capacity,
        ],
      );

      await client.query("COMMIT");

      return res.json({
        message: "Pickup window updated successfully.",
        pickupWindowId,
        menuDate: windowDate,
        startTime,
        endTime,
        capacity,
        reservedCount,
        availableCapacity: capacity - reservedCount,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Update pickup window error:", error);

      return res.status(500).json({
        error: "Failed to update pickup window.",
      });
    } finally {
      client.release();
    }
  },
);

router.delete(
  "/admin/pickup-windows/:pickupWindowId",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const pickupWindowId = Number(req.params.pickupWindowId);

      if (!Number.isInteger(pickupWindowId) || pickupWindowId <= 0) {
        return res.status(400).json({
          error: "Invalid pickup window ID.",
        });
      }

      await client.query("BEGIN");

      const currentResult = await client.query(
        `
        SELECT reserved_count
        FROM pickup_windows
        WHERE pickup_window_id = $1
        FOR UPDATE
        `,
        [pickupWindowId],
      );

      const current = currentResult.rows[0];

      if (!current) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          error: "Pickup window not found.",
        });
      }

      const reservedCount = Number(
        current.reserved_count ?? 0,
      );

      if (reservedCount > 0) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error:
            `This pickup window cannot be deleted because ${reservedCount} order(s) are already reserved in it.`,
        });
      }

      await client.query(
        `
        DELETE FROM pickup_windows
        WHERE pickup_window_id = $1
        `,
        [pickupWindowId],
      );

      await client.query("COMMIT");

      return res.json({
        message: "Pickup window deleted successfully.",
        pickupWindowId,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Delete pickup window error:", error);

      return res.status(500).json({
        error: "Failed to delete pickup window.",
      });
    } finally {
      client.release();
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - INGREDIENT CATALOG
 * GET /api/menu/admin/ingredients
 * --------------------------------------------------------------------------
 */
router.get(
  "/admin/ingredients",
  authenticateToken,
  requireRole("ADMIN"),
  async (_req, res) => {
    try {
      const result = await pool.query(
        `
        SELECT
          ingredient_id AS "ingredientId",
          ingredient_name AS "ingredientName"
        FROM ingredients
        ORDER BY ingredient_name
        `,
      );

      return res.json({
        ingredients: result.rows as IngredientCatalogRow[],
      });
    } catch (error) {
      console.error("Ingredient catalog error:", error);

      return res.status(500).json({
        error: "Failed to retrieve ingredients.",
      });
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - CREATE INGREDIENT
 * POST /api/menu/admin/ingredients
 * --------------------------------------------------------------------------
 */
router.post(
  "/admin/ingredients",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const ingredientName = String(
        req.body.ingredientName ?? "",
      ).trim();

      if (!ingredientName) {
        return res.status(400).json({
          error: "ingredientName is required.",
        });
      }

      if (ingredientName.length > 100) {
        return res.status(400).json({
          error: "ingredientName cannot exceed 100 characters.",
        });
      }

      await client.query("BEGIN");

      const duplicate = await client.query(
        `
        SELECT ingredient_id
        FROM ingredients
        WHERE UPPER(ingredient_name) = UPPER($1)
        `,
        [ingredientName],
      );

      if (duplicate.rows.length > 0) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error: "Ingredient already exists.",
        });
      }

      const result = await client.query(
        `
        INSERT INTO ingredients (
          ingredient_name
        )
        VALUES (
          $1
        )
        RETURNING ingredient_id
        `,
        [ingredientName],
      );

      await client.query("COMMIT");

      return res.status(201).json({
        message: "Ingredient created successfully.",
        ingredientId: Number(result.rows[0].ingredient_id),
        ingredientName,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Create ingredient error:", error);

      return res.status(500).json({
        error: "Failed to create ingredient.",
      });
    } finally {
      client.release();
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - CREATE MENU ITEM
 * POST /api/menu/admin/items
 * --------------------------------------------------------------------------
 */
router.post(
  "/admin/items",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const menuDateId = Number(req.body.menuDateId);
      const itemName = String(req.body.itemName ?? "").trim();
      const description = String(req.body.description ?? "").trim();
      const price = Number(req.body.price);
      const isAvailable = String(
        req.body.isAvailable ?? "Y",
      ).toUpperCase();
      const stockQuantity = Number(req.body.stockQuantity ?? 0);

      const ingredientIds: number[] = Array.isArray(
        req.body.ingredientIds,
      )
        ? req.body.ingredientIds
          .map(Number)
          .filter(
            (id: number) =>
              Number.isInteger(id) && id > 0,
          )
        : [];

      if (!Number.isInteger(menuDateId) || menuDateId <= 0) {
        return res.status(400).json({
          error: "Valid menuDateId is required.",
        });
      }

      if (!itemName) {
        return res.status(400).json({
          error: "itemName is required.",
        });
      }

      if (itemName.length > 100) {
        return res.status(400).json({
          error: "itemName cannot exceed 100 characters.",
        });
      }

      if (description.length > 500) {
        return res.status(400).json({
          error: "description cannot exceed 500 characters.",
        });
      }

      if (!Number.isFinite(price) || price <= 0) {
        return res.status(400).json({
          error: "price must be greater than 0.",
        });
      }

      if (!["Y", "N"].includes(isAvailable)) {
        return res.status(400).json({
          error: "isAvailable must be Y or N.",
        });
      }

      if (
        !Number.isInteger(stockQuantity) ||
        stockQuantity < 0
      ) {
        return res.status(400).json({
          error: "stockQuantity must be a non-negative integer.",
        });
      }

      await client.query("BEGIN");

      const dateCheck = await client.query(
        `
        SELECT menu_date_id
        FROM menu_dates
        WHERE menu_date_id = $1
        `,
        [menuDateId],
      );

      if (dateCheck.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          error: "Menu date not found.",
        });
      }

      const duplicate = await client.query(
        `
        SELECT menu_item_id
        FROM menu_items
        WHERE menu_date_id = $1
          AND UPPER(item_name) = UPPER($2)
        `,
        [menuDateId, itemName],
      );

      if (duplicate.rows.length > 0) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error: "A menu item with this name already exists for this date.",
        });
      }

      const itemResult = await client.query(
        `
        INSERT INTO menu_items (
          menu_date_id,
          item_name,
          description,
          price,
          is_available
        )
        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5
        )
        RETURNING menu_item_id
        `,
        [
          menuDateId,
          itemName,
          description,
          price,
          isAvailable,
        ],
      );

      const menuItemId = Number(
        itemResult.rows[0].menu_item_id,
      );

      await client.query(
        `
        INSERT INTO stock (
          menu_item_id,
          available_qty
        )
        VALUES (
          $1,
          $2
        )
        `,
        [
          menuItemId,
          stockQuantity,
        ],
      );

      for (const ingredientId of ingredientIds) {
        await client.query(
          `
          INSERT INTO item_ingredients (
            menu_item_id,
            ingredient_id
          )
          VALUES (
            $1,
            $2
          )
          `,
          [
            menuItemId,
            ingredientId,
          ],
        );
      }

      await client.query("COMMIT");

      return res.status(201).json({
        message: "Menu item created successfully.",
        menuItemId,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Create menu item error:", error);

      return res.status(500).json({
        error: "Failed to create menu item.",
      });
    } finally {
      client.release();
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - UPDATE MENU ITEM
 * PATCH /api/menu/admin/items/:menuItemId
 * --------------------------------------------------------------------------
 */
router.patch(
  "/admin/items/:menuItemId",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    try {
      const menuItemId = Number(req.params.menuItemId);
      const itemName = String(req.body.itemName ?? "").trim();
      const description = String(req.body.description ?? "").trim();
      const price = Number(req.body.price);
      const isAvailable = String(
        req.body.isAvailable ?? "Y",
      ).toUpperCase();

      if (!Number.isInteger(menuItemId) || menuItemId <= 0) {
        return res.status(400).json({
          error: "Invalid menu item ID.",
        });
      }

      if (!itemName) {
        return res.status(400).json({
          error: "itemName is required.",
        });
      }

      if (!Number.isFinite(price) || price <= 0) {
        return res.status(400).json({
          error: "price must be greater than 0.",
        });
      }

      if (!["Y", "N"].includes(isAvailable)) {
        return res.status(400).json({
          error: "isAvailable must be Y or N.",
        });
      }

      const result = await pool.query(
        `
        UPDATE menu_items
        SET
          item_name = $1,
          description = $2,
          price = $3,
          is_available = $4
        WHERE menu_item_id = $5
        `,
        [
          itemName,
          description,
          price,
          isAvailable,
          menuItemId,
        ],
      );

      if (result.rowCount !== 1) {
        return res.status(404).json({
          error: "Menu item not found.",
        });
      }

      return res.json({
        message: "Menu item updated successfully.",
        menuItemId,
      });
    } catch (error) {
      console.error("Update menu item error:", error);

      return res.status(500).json({
        error: "Failed to update menu item.",
      });
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - UPDATE STOCK
 * PUT /api/menu/admin/items/:menuItemId/stock
 * --------------------------------------------------------------------------
 */
router.put(
  "/admin/items/:menuItemId/stock",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    try {
      const menuItemId = Number(req.params.menuItemId);
      const availableQty = Number(req.body.availableQty);

      if (!Number.isInteger(menuItemId) || menuItemId <= 0) {
        return res.status(400).json({
          error: "Invalid menu item ID.",
        });
      }

      if (
        !Number.isInteger(availableQty) ||
        availableQty < 0
      ) {
        return res.status(400).json({
          error: "availableQty must be a non-negative integer.",
        });
      }

      const result = await pool.query(
        `
        UPDATE stock
        SET available_qty = $1
        WHERE menu_item_id = $2
        `,
        [
          availableQty,
          menuItemId,
        ],
      );

      if (result.rowCount !== 1) {
        return res.status(404).json({
          error: "Stock record not found for this menu item.",
        });
      }

      return res.json({
        message: "Stock updated successfully.",
        menuItemId,
        availableQty,
      });
    } catch (error) {
      console.error("Update stock error:", error);

      return res.status(500).json({
        error: "Failed to update stock.",
      });
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - REPLACE INGREDIENT ASSIGNMENTS
 * PUT /api/menu/admin/items/:menuItemId/ingredients
 * --------------------------------------------------------------------------
 */
router.put(
  "/admin/items/:menuItemId/ingredients",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const menuItemId = Number(req.params.menuItemId);

      if (!Number.isInteger(menuItemId) || menuItemId <= 0) {
        return res.status(400).json({
          error: "Invalid menu item ID.",
        });
      }
      const ingredientIds: number[] = Array.isArray(req.body.ingredientIds)
        ? [
          ...new Set(
            (req.body.ingredientIds as unknown[])
              .map((value): number => Number(value))
              .filter(
                (id: number) => Number.isInteger(id) && id > 0,
              ),
          ),
        ]
        : [];

      await client.query("BEGIN");

      const menuItemResult = await client.query(
        `
        SELECT menu_item_id
        FROM menu_items
        WHERE menu_item_id = $1
        `,
        [menuItemId],
      );

      if (menuItemResult.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          error: "Menu item not found.",
        });
      }

      if (ingredientIds.length > 0) {
        const ingredientResult = await client.query(
          `
          SELECT ingredient_id
          FROM ingredients
          WHERE ingredient_id = ANY($1::INTEGER[])
          `,
          [ingredientIds],
        );

        const existingIngredientIds = new Set(
          ingredientResult.rows.map(
            (row) => Number(row.ingredient_id),
          ),
        );

        const invalidIngredientIds =
          ingredientIds.filter(
            (id) => !existingIngredientIds.has(id),
          );

        if (invalidIngredientIds.length > 0) {
          await client.query("ROLLBACK");

          return res.status(400).json({
            error: "One or more ingredient IDs do not exist.",
            invalidIngredientIds,
          });
        }
      }

      await client.query(
        `
        DELETE FROM item_ingredients
        WHERE menu_item_id = $1
        `,
        [menuItemId],
      );

      for (const ingredientId of ingredientIds) {
        await client.query(
          `
          INSERT INTO item_ingredients (
            menu_item_id,
            ingredient_id
          )
          VALUES (
            $1,
            $2
          )
          `,
          [
            menuItemId,
            ingredientId,
          ],
        );
      }

      await client.query("COMMIT");

      return res.json({
        message:
          "Ingredient assignments updated successfully.",
        menuItemId,
        ingredientIds,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error(
        "Update ingredients error:",
        error,
      );

      return res.status(500).json({
        error:
          "Failed to update ingredient assignments.",
      });
    } finally {
      client.release();
    }
  },
);

/*
 * --------------------------------------------------------------------------
 * ADMIN - DELETE MENU ITEM
 * DELETE /api/menu/admin/items/:menuItemId
 * --------------------------------------------------------------------------
 */
router.delete(
  "/admin/items/:menuItemId",
  authenticateToken,
  requireRole("ADMIN"),
  async (req, res) => {
    const client = await pool.connect();

    try {
      const menuItemId = Number(req.params.menuItemId);

      if (!Number.isInteger(menuItemId) || menuItemId <= 0) {
        return res.status(400).json({
          error: "Invalid menu item ID.",
        });
      }

      await client.query("BEGIN");

      const itemCheck = await client.query(
        `
        SELECT menu_item_id
        FROM menu_items
        WHERE menu_item_id = $1
        FOR UPDATE
        `,
        [menuItemId],
      );

      if (itemCheck.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          error: "Menu item not found.",
        });
      }

      /*
       * Do not physically delete an item that has already
       * been included in an order.
       */
      const orderCheck = await client.query(
        `
        SELECT COUNT(*) AS order_count
        FROM order_lines
        WHERE menu_item_id = $1
        `,
        [menuItemId],
      );

      const orderCount = Number(
        orderCheck.rows[0]?.order_count ?? 0,
      );

      if (orderCount > 0) {
        await client.query("ROLLBACK");

        return res.status(409).json({
          error:
            "This menu item cannot be deleted because it has already been used in an order.",
        });
      }

      /*
       * Remove dependent records first.
       */
      await client.query(
        `
        DELETE FROM item_ingredients
        WHERE menu_item_id = $1
        `,
        [menuItemId],
      );

      await client.query(
        `
        DELETE FROM stock
        WHERE menu_item_id = $1
        `,
        [menuItemId],
      );

      await client.query(
        `
        DELETE FROM menu_items
        WHERE menu_item_id = $1
        `,
        [menuItemId],
      );

      await client.query("COMMIT");

      return res.json({
        message: "Menu item deleted successfully.",
        menuItemId,
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Delete menu item error:", error);

      return res.status(500).json({
        error: "Failed to delete menu item.",
      });
    } finally {
      client.release();
    }
  },
);

export default router;