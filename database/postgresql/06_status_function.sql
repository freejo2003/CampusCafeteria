-- ============================================================
-- CAMPUS CAFETERIA
-- PostgreSQL Order Status Function
-- ============================================================

DROP FUNCTION IF EXISTS update_order_status(
    INTEGER,
    VARCHAR,
    INTEGER
);


-- ============================================================
-- UPDATE ORDER STATUS
-- ============================================================
--
-- PostgreSQL equivalent of the Oracle UPDATE_ORDER_STATUS
-- procedure.
--
-- Allowed transitions:
--
--     PLACED     -> PREPARING
--     PREPARING  -> READY
--     READY      -> COLLECTED
--
-- Additional behavior:
--
--     COLLECTED:
--         releases one pickup-window reservation.
--
-- Status-history insertion is handled automatically by:
--
--     trg_order_status_history
--
-- from 05_status_trigger.sql.
--
-- Transaction control is intentionally NOT performed here.
-- The backend controls BEGIN / COMMIT / ROLLBACK.
-- ============================================================

CREATE OR REPLACE FUNCTION update_order_status(
    p_order_id   INTEGER,
    p_new_status VARCHAR,
    p_changed_by INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(20);
    v_pickup_window  INTEGER;
BEGIN

    -- ========================================================
    -- LOCK ORDER
    -- ========================================================
    --
    -- Prevent concurrent status changes to the same order.
    -- ========================================================

    SELECT
        o.order_status,
        o.pickup_window_id
    INTO
        v_current_status,
        v_pickup_window
    FROM orders o
    WHERE o.order_id = p_order_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Order not found.'
            USING ERRCODE = 'P2025';
    END IF;


    -- ========================================================
    -- VALIDATE STATUS
    -- ========================================================

    IF p_new_status NOT IN (
        'PREPARING',
        'READY',
        'COLLECTED'
    )
    THEN

        RAISE EXCEPTION
            'Invalid staff order status.'
            USING ERRCODE = 'P2020';

    END IF;


    -- ========================================================
    -- VALIDATE STATUS TRANSITION
    -- ========================================================

    IF (
        v_current_status = 'PLACED'
        AND p_new_status <> 'PREPARING'
    )
    OR (
        v_current_status = 'PREPARING'
        AND p_new_status <> 'READY'
    )
    OR (
        v_current_status = 'READY'
        AND p_new_status <> 'COLLECTED'
    )
    THEN

        RAISE EXCEPTION
            'Invalid order status transition.'
            USING ERRCODE = 'P2021';

    END IF;


    -- ========================================================
    -- SET AUTHENTICATED ACTOR
    -- ========================================================
    --
    -- The status-history trigger reads this transaction-local
    -- setting.
    --
    -- SET LOCAL app.changed_by = '51';
    --
    -- is equivalent in purpose to the Oracle
    -- DBMS_SESSION.SET_IDENTIFIER mechanism.
    -- ========================================================

    PERFORM set_config(
        'app.changed_by',
        p_changed_by::TEXT,
        true
    );


    -- ========================================================
    -- UPDATE ORDER STATUS
    -- ========================================================
    --
    -- The trigger from 05_status_trigger.sql automatically
    -- inserts the status-history record.
    -- ========================================================

    UPDATE orders
    SET order_status = p_new_status
    WHERE order_id = p_order_id;


    -- ========================================================
    -- RELEASE PICKUP-WINDOW RESERVATION
    --
    -- When the order is collected, its reserved pickup slot
    -- becomes available again.
    --
    -- Stock is NOT restored because the order has already
    -- been fulfilled.
    -- ========================================================

    IF p_new_status = 'COLLECTED' THEN

        UPDATE pickup_windows
        SET reserved_count =
            CASE
                WHEN reserved_count > 0
                THEN reserved_count - 1
                ELSE 0
            END
        WHERE pickup_window_id = v_pickup_window;

    END IF;

END;
$$;