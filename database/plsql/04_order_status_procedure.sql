CREATE OR REPLACE PROCEDURE update_order_status (
    p_order_id   IN NUMBER,
    p_new_status IN VARCHAR2,
    p_changed_by IN NUMBER
)
AS
    v_old_status orders.order_status%TYPE;
BEGIN
    SELECT order_status
    INTO v_old_status
    FROM orders
    WHERE order_id = p_order_id
    FOR UPDATE;

    IF p_new_status NOT IN ('PREPARING', 'READY', 'COLLECTED') THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Invalid staff order status.'
        );
    END IF;

    IF (v_old_status = 'PLACED' AND p_new_status <> 'PREPARING')
       OR (v_old_status = 'PREPARING' AND p_new_status <> 'READY')
       OR (v_old_status = 'READY' AND p_new_status <> 'COLLECTED') THEN
        RAISE_APPLICATION_ERROR(
            -20021,
            'Invalid order status transition.'
        );
    END IF;

    UPDATE orders
    SET order_status = p_new_status
    WHERE order_id = p_order_id;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20022,
            'Order not found.'
        );

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
