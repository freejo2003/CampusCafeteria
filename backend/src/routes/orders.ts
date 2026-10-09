import { Router } from "express";
import { pool } from "../db.js";
import {
  authenticateToken,
  requireRole,
  AuthenticatedRequest
} from "../middleware/auth.js";

const router = Router();

interface OrderItem {
  menuItemId: number;
  quantity: number;
}

interface PlaceOrderBody {
  pickupWindowId: number;
  items: OrderItem[];
}

/*
 * STUDENT
 * Place a new order
 */
router.post(
  "/",
  authenticateToken,
  requireRole("STUDENT"),
  async (req: AuthenticatedRequest, res) => {
    const body = req.body as PlaceOrderBody;
    const userId = req.user!.userId;

    if (
      !Number.isInteger(body.pickupWindowId) ||
      !Array.isArray(body.items) ||
      body.items.length === 0
    ) {
      return res.status(400).json({
        error: "pickupWindowId and at least one item are required."
      });
    }

    for (const item of body.items) {
      if (
        !Number.isInteger(item.menuItemId) ||
        !Number.isInteger(item.quantity) ||
        item.quantity <= 0
      ) {
        return res.status(400).json({
          error:
            "Each item must have a valid menuItemId and positive quantity."
        });
      }
    }

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      const menuItemIds = body.items.map(
        (item) => item.menuItemId
      );

      const quantities = body.items.map(
        (item) => item.quantity
      );

      const result = await client.query(
        `
        SELECT *
        FROM place_order(
          $1,
          $2,
          $3::INTEGER[],
          $4::INTEGER[]
        )
        `,
        [
          userId,
          body.pickupWindowId,
          menuItemIds,
          quantities
        ]
      );

      await client.query("COMMIT");

      const row = result.rows[0];

      return res.status(201).json({
        orderId: row.order_id,
        pickupCode: row.pickup_code,
        totalAmount: Number(row.total_amount)
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error("Order API error:", error);

      const message =
        error instanceof Error
          ? error.message
          : "Failed to place order.";

      return res.status(400).json({
        error: message
      });
    } finally {
      client.release();
    }
  }
);

/*
 * STUDENT
 * View own order history
 */
router.get(
  "/history",
  authenticateToken,
  requireRole("STUDENT"),
  async (req: AuthenticatedRequest, res) => {
    const userId = req.user!.userId;

    try {
      const result = await pool.query(
        `
        SELECT
          o.order_id,
          o.pickup_code,
          o.order_status,
          o.total_amount,
          o.ordered_at,
          TO_CHAR(pw.start_time, 'HH24:MI') AS start_time,
          TO_CHAR(pw.end_time, 'HH24:MI') AS end_time
        FROM orders o
        JOIN pickup_windows pw
          ON pw.pickup_window_id = o.pickup_window_id
        WHERE o.user_id = $1
        ORDER BY o.ordered_at DESC
        `,
        [userId]
      );

      const orders = result.rows.map((row) => ({
        orderId: row.order_id,
        pickupCode: row.pickup_code,
        orderStatus: row.order_status,
        totalAmount: Number(row.total_amount),
        orderedAt: row.ordered_at,
        startTime: row.start_time,
        endTime: row.end_time
      }));

      return res.json({
        userId,
        orders
      });
    } catch (error) {
      console.error(
        "Order history API error:",
        error
      );

      return res.status(500).json({
        error: "Unable to retrieve order history."
      });
    }
  }
);

/*
 * STUDENT
 * Cancel own order
 */
router.post(
  "/:orderId/cancel",
  authenticateToken,
  requireRole("STUDENT"),
  async (req: AuthenticatedRequest, res) => {
    const orderId = Number(req.params.orderId);
    const userId = req.user!.userId;

    if (
      !Number.isInteger(orderId) ||
      orderId <= 0
    ) {
      return res.status(400).json({
        error: "Invalid order ID."
      });
    }

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      await client.query(
        `
        SELECT cancel_order($1, $2)
        `,
        [orderId, userId]
      );

      await client.query("COMMIT");

      return res.json({
        orderId,
        status: "CANCELLED"
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error(
        "Cancel order API error:",
        error
      );

      const message =
        error instanceof Error
          ? error.message
          : "Failed to cancel order.";

      return res.status(400).json({
        error: message
      });
    } finally {
      client.release();
    }
  }
);

/*
 * STAFF / ADMIN
 * View pickup queue
 */
router.get(
  "/queue",
  authenticateToken,
  requireRole("STAFF", "ADMIN"),
  async (req: AuthenticatedRequest, res) => {
    const pickupWindowId =
      Number(req.query.pickupWindowId);

    if (
      !Number.isInteger(pickupWindowId) ||
      pickupWindowId <= 0
    ) {
      return res.status(400).json({
        error: "Invalid pickup window ID."
      });
    }

    try {
      const result = await pool.query(
        `
        SELECT *
        FROM get_pickup_queue($1)
        `,
        [pickupWindowId]
      );

      const queue = result.rows.map((row) => ({
        orderId: row.order_id,
        fullName: row.full_name,
        pickupCode: row.pickup_code,
        startTime: row.start_time,
        endTime: row.end_time,
        orderStatus: row.order_status,
        totalAmount: Number(row.total_amount),
        orderedAt: row.ordered_at
      }));

      return res.json({
        pickupWindowId,
        queue
      });
    } catch (error) {
      console.error(
        "Pickup queue API error:",
        error
      );

      return res.status(400).json({
        error:
          error instanceof Error
            ? error.message
            : "Unable to retrieve pickup queue."
      });
    }
  }
);

/*
 * STAFF / ADMIN
 * Update order status
 */
router.patch(
  "/:orderId/status",
  authenticateToken,
  requireRole("STAFF", "ADMIN"),
  async (req: AuthenticatedRequest, res) => {
    const orderId = Number(req.params.orderId);
    const { status } = req.body;
    const changedBy = req.user!.userId;

    if (
      !Number.isInteger(orderId) ||
      orderId <= 0
    ) {
      return res.status(400).json({
        error: "Invalid order ID."
      });
    }

    if (
      status !== "PREPARING" &&
      status !== "READY" &&
      status !== "COLLECTED"
    ) {
      return res.status(400).json({
        error: "Invalid status."
      });
    }

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      await client.query(
        `
        SELECT update_order_status(
          $1,
          $2,
          $3
        )
        `,
        [
          orderId,
          status,
          changedBy
        ]
      );

      await client.query("COMMIT");

      return res.json({
        orderId,
        status
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error(
        "Update order status API error:",
        error
      );

      return res.status(400).json({
        error:
          error instanceof Error
            ? error.message
            : "Unable to update order status."
      });
    } finally {
      client.release();
    }
  }
);

export default router;