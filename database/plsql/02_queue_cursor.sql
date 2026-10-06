CREATE OR REPLACE PROCEDURE get_pickup_queue (
    p_pickup_window_id IN NUMBER,
    p_queue OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_queue FOR
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
          AND o.order_status IN ('PLACED', 'PREPARING', 'READY')
        ORDER BY o.ordered_at;
END;
/
