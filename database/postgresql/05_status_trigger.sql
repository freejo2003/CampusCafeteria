-- ============================================================
-- CAMPUS CAFETERIA
-- PostgreSQL Order Status History Trigger
-- ============================================================

-- ============================================================
-- TRIGGER FUNCTION
-- ============================================================
--
-- PostgreSQL equivalent of:
--
--     trg_order_status_history
--
-- Oracle behavior:
--   INSERT:
--       old_status = NULL
--       new_status = NEW.order_status
--       changed_by = NEW.user_id
--
--   UPDATE:
--       create history only when order_status changes
--       changed_by = authenticated staff/admin user when
--                    available
--       otherwise fall back to the order owner
-- ============================================================

CREATE OR REPLACE FUNCTION fn_order_status_history()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_changed_by INTEGER;
    v_actor TEXT;
BEGIN

    -- ========================================================
    -- INITIAL ORDER CREATION
    -- ========================================================

    IF TG_OP = 'INSERT' THEN

        INSERT INTO order_status_history (
            order_id,
            old_status,
            new_status,
            changed_by
        )
        VALUES (
            NEW.order_id,
            NULL,
            NEW.order_status,
            NEW.user_id
        );

        RETURN NEW;

    END IF;


    -- ========================================================
    -- STATUS UPDATE
    --
    -- Only create a history row when the status actually
    -- changes.
    -- ========================================================

    IF TG_OP = 'UPDATE' THEN

        IF OLD.order_status IS DISTINCT FROM NEW.order_status THEN

            -- ------------------------------------------------
            -- Read authenticated actor from PostgreSQL
            -- session setting.
            --
            -- The backend can set:
            --
            --   SET LOCAL app.changed_by = '51';
            --
            -- before updating the order.
            --
            -- If it is not present, use the order owner.
            -- ------------------------------------------------

            v_actor := current_setting(
                'app.changed_by',
                true
            );


            IF v_actor IS NOT NULL
               AND v_actor <> ''
            THEN

                BEGIN

                    v_changed_by := v_actor::INTEGER;

                EXCEPTION
                    WHEN invalid_text_representation THEN

                        v_changed_by := NEW.user_id;

                END;

            ELSE

                v_changed_by := NEW.user_id;

            END IF;


            -- ------------------------------------------------
            -- Insert status-history record.
            -- ------------------------------------------------

            INSERT INTO order_status_history (
                order_id,
                old_status,
                new_status,
                changed_by
            )
            VALUES (
                NEW.order_id,
                OLD.order_status,
                NEW.order_status,
                v_changed_by
            );

        END IF;


        RETURN NEW;

    END IF;


    RETURN NEW;

END;
$$;


-- ============================================================
-- REMOVE EXISTING TRIGGER
-- ============================================================

DROP TRIGGER IF EXISTS trg_order_status_history
ON orders;


-- ============================================================
-- CREATE TRIGGER
-- ============================================================

CREATE TRIGGER trg_order_status_history
AFTER INSERT OR UPDATE OF order_status
ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_order_status_history();