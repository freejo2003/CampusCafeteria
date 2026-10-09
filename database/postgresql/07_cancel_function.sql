DROP FUNCTION IF EXISTS cancel_order(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION cancel_order(
    p_order_id INTEGER,
    p_user_id INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
    v_pickup_window_id INTEGER;
    v_current_status VARCHAR(20);
BEGIN
    SELECT user_id, pickup_window_id, order_status
    INTO v_user_id, v_pickup_window_id, v_current_status
    FROM orders
    WHERE order_id = p_order_id
    FOR UPDATE;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Order not found.'
            USING ERRCODE = 'P2001';
    END IF;

    IF v_user_id <> p_user_id THEN
        RAISE EXCEPTION 'You are not authorized to cancel this order.'
            USING ERRCODE = 'P2002';
    END IF;

    IF v_current_status <> 'PLACED' THEN
        RAISE EXCEPTION 'Only PLACED orders can be cancelled.'
            USING ERRCODE = 'P2003';
    END IF;

    FOR v_user_id IN
        SELECT menu_item_id
        FROM order_lines
        WHERE order_id = p_order_id
        ORDER BY menu_item_id
    LOOP
        UPDATE stock
        SET available_qty = available_qty + (
            SELECT quantity
            FROM order_lines
            WHERE order_id = p_order_id
              AND menu_item_id = v_user_id
        )
        WHERE menu_item_id = v_user_id;
    END LOOP;

    UPDATE pickup_windows
    SET reserved_count = GREATEST(reserved_count - 1, 0)
    WHERE pickup_window_id = v_pickup_window_id;

    UPDATE orders
    SET order_status = 'CANCELLED',
        cancelled_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
END;
$$;
