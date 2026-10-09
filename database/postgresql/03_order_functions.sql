-- ============================================================
-- CAMPUS CAFETERIA
-- PostgreSQL Order Functions
-- ============================================================

-- Remove the function if it already exists.
DROP FUNCTION IF EXISTS place_order(
    INTEGER,
    INTEGER,
    INTEGER[],
    INTEGER[]
);


-- ============================================================
-- PLACE ORDER
-- ============================================================
--
-- PostgreSQL equivalent of the Oracle PLACE_ORDER procedure.
--
-- Responsibilities:
--   1. Validate order contents.
--   2. Lock pickup window.
--   3. Check pickup-window capacity.
--   4. Validate menu items.
--   5. Lock stock rows.
--   6. Prevent overselling.
--   7. Calculate order total.
--   8. Create order.
--   9. Generate deterministic pickup code.
--  10. Create order lines.
--  11. Deduct stock.
--  12. Reserve one pickup-window slot.
--
-- Transaction behavior:
--   PostgreSQL functions cannot issue COMMIT/ROLLBACK.
--   The transaction is therefore controlled by the caller
--   (the backend application).
--
-- Parameters:
--   p_user_id
--   p_pickup_window_id
--   p_menu_item_ids
--   p_quantities
--
-- Returns:
--   order_id
--   pickup_code
--   total_amount
-- ============================================================

CREATE OR REPLACE FUNCTION place_order(
    p_user_id          INTEGER,
    p_pickup_window_id INTEGER,
    p_menu_item_ids    INTEGER[],
    p_quantities       INTEGER[]
)
RETURNS TABLE (
    order_id     INTEGER,
    pickup_code  VARCHAR(100),
    total_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_window_capacity INTEGER;
    v_reserved_count  INTEGER;

    v_item_price      NUMERIC;
    v_available_qty   INTEGER;

    v_order_id        INTEGER;
    v_pickup_code     VARCHAR(100);

    v_total_amount    NUMERIC := 0;

    v_index           INTEGER;
BEGIN

    -- ========================================================
    -- BASIC VALIDATION
    -- ========================================================

    IF p_menu_item_ids IS NULL
       OR p_quantities IS NULL
       OR cardinality(p_menu_item_ids) = 0
    THEN
        RAISE EXCEPTION
            'Order must contain at least one item.'
            USING ERRCODE = 'P2001';
    END IF;


    IF cardinality(p_menu_item_ids)
       <> cardinality(p_quantities)
    THEN
        RAISE EXCEPTION
            'Item and quantity counts must match.'
            USING ERRCODE = 'P2002';
    END IF;


    -- ========================================================
    -- LOCK PICKUP WINDOW
    --
    -- This prevents concurrent orders from exceeding the
    -- pickup-window capacity.
    -- ========================================================

    SELECT
        pw.capacity,
        pw.reserved_count
    INTO
        v_window_capacity,
        v_reserved_count
    FROM pickup_windows pw
    WHERE pw.pickup_window_id = p_pickup_window_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Pickup window or required order data was not found.'
            USING ERRCODE = 'P2007';
    END IF;


    -- Only one reservation is created per order.
    IF v_reserved_count + 1 > v_window_capacity THEN
        RAISE EXCEPTION
            'Pickup window is full.'
            USING ERRCODE = 'P2006';
    END IF;


    -- ========================================================
    -- VALIDATE EVERY REQUESTED ITEM
    --
    -- Menu item and stock rows are locked before the order is
    -- created so concurrent orders cannot oversell stock.
    -- ========================================================

    FOR v_index IN 1..cardinality(p_menu_item_ids)
    LOOP

        -- ----------------------------------------------------
        -- Quantity validation
        -- ----------------------------------------------------

        IF p_quantities[v_index] IS NULL
           OR p_quantities[v_index] <= 0
        THEN
            RAISE EXCEPTION
                'Order quantity must be greater than zero.'
                USING ERRCODE = 'P2003';
        END IF;


        -- ----------------------------------------------------
        -- Lock menu item and obtain current price
        -- ----------------------------------------------------

        SELECT
            mi.price
        INTO
            v_item_price
        FROM menu_items mi
        WHERE mi.menu_item_id = p_menu_item_ids[v_index]
          AND mi.is_available = 'Y'
        FOR UPDATE;


        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Menu item is unavailable or does not exist.'
                USING ERRCODE = 'P2004';
        END IF;


        -- ----------------------------------------------------
        -- Lock stock row
        -- ----------------------------------------------------

        SELECT
            s.available_qty
        INTO
            v_available_qty
        FROM stock s
        WHERE s.menu_item_id = p_menu_item_ids[v_index]
        FOR UPDATE;


        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Stock record does not exist for menu item.'
                USING ERRCODE = 'P2005';
        END IF;


        -- ----------------------------------------------------
        -- Prevent overselling
        -- ----------------------------------------------------

        IF v_available_qty < p_quantities[v_index] THEN
            RAISE EXCEPTION
                'Insufficient stock for menu item %. Available: %',
                p_menu_item_ids[v_index],
                v_available_qty
                USING ERRCODE = 'P2005';
        END IF;


        -- ----------------------------------------------------
        -- Calculate total
        -- ----------------------------------------------------

        v_total_amount :=
            v_total_amount
            + (
                v_item_price
                * p_quantities[v_index]
            );

    END LOOP;


    -- ========================================================
    -- CREATE ORDER
    --
    -- PostgreSQL identity column generates order_id.
    -- A temporary unique pickup code is used during INSERT.
    -- ========================================================

    INSERT INTO orders (
        user_id,
        pickup_window_id,
        pickup_code,
        order_status,
        total_amount
    )
    VALUES (
        p_user_id,
        p_pickup_window_id,
        'CAF' || substr(
            md5(
                random()::text
                || clock_timestamp()::text
                || p_user_id::text
            ),
            1,
            17
        ),
        'PLACED',
        v_total_amount
    )
    RETURNING orders.order_id
    INTO v_order_id;


    -- ========================================================
    -- FINAL DETERMINISTIC PICKUP CODE
    --
    -- Format:
    --     CAF + 17 digit ORDER_ID
    --
    -- Example:
    --     CAF00000000000000141
    -- ========================================================

    v_pickup_code :=
        'CAF'
        || lpad(
            v_order_id::TEXT,
            17,
            '0'
        );


    UPDATE orders
    SET pickup_code = v_pickup_code
    WHERE orders.order_id = v_order_id;


    -- ========================================================
    -- INSERT ORDER LINES AND CONSUME STOCK
    -- ========================================================

    FOR v_index IN 1..cardinality(p_menu_item_ids)
    LOOP

        -- Obtain the current menu-item price.
        SELECT
            mi.price
        INTO
            v_item_price
        FROM menu_items mi
        WHERE mi.menu_item_id = p_menu_item_ids[v_index];


        -- Create order line.
        INSERT INTO order_lines (
            order_id,
            menu_item_id,
            quantity,
            unit_price
        )
        VALUES (
            v_order_id,
            p_menu_item_ids[v_index],
            p_quantities[v_index],
            v_item_price
        );


        -- Consume stock.
        UPDATE stock
        SET available_qty =
            available_qty - p_quantities[v_index]
        WHERE menu_item_id = p_menu_item_ids[v_index];

    END LOOP;


    -- ========================================================
    -- RESERVE ONE PICKUP-WINDOW SLOT
    -- ========================================================

    UPDATE pickup_windows
    SET reserved_count = reserved_count + 1
    WHERE pickup_window_id = p_pickup_window_id;


    -- ========================================================
    -- RETURN VALUES
    -- ========================================================

    order_id     := v_order_id;
    pickup_code  := v_pickup_code;
    total_amount := v_total_amount;

    RETURN NEXT;

END;
$$;
