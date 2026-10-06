import { Router } from "express";
import oracledb from "oracledb";
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

interface PlaceOrderOutBinds {
  order_id: number;
  pickup_code: string;
  total_amount: number;
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
    let connection;

    try {
      const body = req.body as PlaceOrderBody;
      const userId = req.user!.userId;

      if (
        !Number.isInteger(body.pickupWindowId) ||
        !Array.isArray(body.items) ||
        body.items.length === 0
      ) {
        return res.status(400).json({
          error:
            "pickupWindowId and at least one item are required."
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

      connection = await pool.getConnection();

      const menuItemIds = body.items.map(
        (item) => item.menuItemId
      );

      const quantities = body.items.map(
        (item) => item.quantity
      );

      const ODCINUMBERLIST =
        await connection.getDbObjectClass(
          "SYS.ODCINUMBERLIST"
        );

      const menuItemIdsObject =
        new ODCINUMBERLIST(menuItemIds);

      const quantitiesObject =
        new ODCINUMBERLIST(quantities);

      const result = await connection.execute(
        `
        BEGIN
          place_order(
            p_user_id           => :user_id,
            p_pickup_window_id  => :pickup_window_id,
            p_menu_item_ids     => :menu_item_ids,
            p_quantities        => :quantities,
            p_order_id          => :order_id,
            p_pickup_code       => :pickup_code,
            p_total_amount      => :total_amount
          );
        END;
        `,
        {
          user_id: userId,

          pickup_window_id: body.pickupWindowId,

          menu_item_ids: {
            dir: oracledb.BIND_IN,
            val: menuItemIdsObject
          },

          quantities: {
            dir: oracledb.BIND_IN,
            val: quantitiesObject
          },

          order_id: {
            dir: oracledb.BIND_OUT,
            type: oracledb.NUMBER
          },

          pickup_code: {
            dir: oracledb.BIND_OUT,
            type: oracledb.STRING,
            maxSize: 50
          },

          total_amount: {
            dir: oracledb.BIND_OUT,
            type: oracledb.NUMBER
          }
        }
      );

      const outBinds =
        result.outBinds as PlaceOrderOutBinds;

      return res.status(201).json({
        orderId: outBinds.order_id,
        pickupCode: outBinds.pickup_code,
        totalAmount: outBinds.total_amount
      });
    } catch (error) {
      console.error("Order API error:", error);

      const message =
        error instanceof Error
          ? error.message
          : "Failed to place order.";

      return res.status(400).json({
        error: message
      });
    } finally {
      if (connection) {
        await connection.close();
      }
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

    let connection;

    try {
      connection = await pool.getConnection();

      const result = await connection.execute(
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
        WHERE o.user_id = :user_id
        ORDER BY o.ordered_at DESC
        `,
        {
          user_id: userId
        }
      );

      const rows = result.rows as any[];

      const orders = rows.map((row) => ({
        orderId: row[0],
        pickupCode: row[1],
        orderStatus: row[2],
        totalAmount: row[3],
        orderedAt: row[4],
        startTime: row[5],
        endTime: row[6]
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
    } finally {
      if (connection) {
        await connection.close();
      }
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
    let connection;

    try {
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

      connection = await pool.getConnection();

      await connection.execute(
        `
        BEGIN
          cancel_order(
            p_order_id => :order_id,
            p_user_id  => :user_id
          );
        END;
        `,
        {
          order_id: orderId,
          user_id: userId
        }
      );

      return res.json({
        orderId,
        status: "CANCELLED"
      });
    } catch (error) {
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
      if (connection) {
        await connection.close();
      }
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

    let connection;

    try {
      connection = await pool.getConnection();

      const result = await connection.execute(
        `
        BEGIN
          get_pickup_queue(
            :pickup_window_id,
            :queue
          );
        END;
        `,
        {
          pickup_window_id: pickupWindowId,

          queue: {
            dir: oracledb.BIND_OUT,
            type: oracledb.CURSOR
          }
        }
      );

      const outBinds = result.outBinds as {
        queue: oracledb.ResultSet<any>;
      };

      const resultSet = outBinds.queue;

      const rows = await resultSet.getRows();

      await resultSet.close();

      const queue = rows.map((row: any) => ({
        orderId: row[0],
        fullName: row[1],
        pickupCode: row[2],
        startTime: row[3],
        endTime: row[4],
        orderStatus: row[5],
        totalAmount: row[6],
        orderedAt: row[7]
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
    } finally {
      if (connection) {
        await connection.close();
      }
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

    let connection;

    try {
      connection = await pool.getConnection();

      await connection.execute(
        `
        BEGIN
          update_order_status(
            :order_id,
            :new_status,
            :changed_by
          );
        END;
        `,
        {
          order_id: orderId,
          new_status: status,
          changed_by: changedBy
        }
      );

      return res.json({
        orderId,
        status
      });
    } catch (error) {
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
      if (connection) {
        await connection.close();
      }
    }
  }
);

export default router;