-- ============================================================
-- CAMPUS CAFETERIA
-- PostgreSQL Pickup Queue Function
-- ============================================================

DROP FUNCTION IF EXISTS get_pickup_queue(INTEGER);


-- ============================================================
-- GET PICKUP QUEUE
-- ============================================================
--
-- PostgreSQL equivalent of the Oracle GET_PICKUP_QUEUE
-- procedure that returned SYS_REFCURSOR.
--
-- Returns active orders for one pickup window.
--
-- Included statuses:
--   PLACED
--   PREPARING
--   READY
--
-- Ordered by the time the order was placed.
-- ============================================================

CREATE OR REPLACE FUNCTION get_pickup_queue(
    p_pickup_window_id INTEGER
)
RETURNS TABLE (
    order_id        INTEGER,
    full_name       VARCHAR(255),
    pickup_code     VARCHAR(100),
    start_time      TIMESTAMP,
    end_time        TIMESTAMP,
    order_status    VARCHAR(20),
    total_amount    NUMERIC,
    ordered_at      TIMESTAMP
)
LANGUAGE sql
AS $$
    SELECT
        o.order_id,
        u.full_name,
        o.pickup_code,
        pw.start_time,
        pw.end_time,
        o.order_status,
        o.total_amount,
        o.ordered_at
    FROM orders o
    JOIN users u
        ON u.user_id = o.user_id
    JOIN pickup_windows pw
        ON pw.pickup_window_id = o.pickup_window_id
    WHERE o.pickup_window_id = p_pickup_window_id
      AND o.order_status IN (
          'PLACED',
          'PREPARING',
          'READY'
      )
    ORDER BY o.ordered_at;
$$;