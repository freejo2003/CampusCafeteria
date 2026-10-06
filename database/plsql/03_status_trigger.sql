CREATE OR REPLACE TRIGGER trg_order_status_history
AFTER INSERT OR UPDATE OF order_status
ON orders
FOR EACH ROW
BEGIN

    /*
        Initial order creation.

        There is no previous status, so the order's
        owner/user is recorded as the actor.
    */

    IF INSERTING THEN

        INSERT INTO order_status_history (
            order_id,
            old_status,
            new_status,
            changed_by
        )
        VALUES (
            :NEW.order_id,
            NULL,
            :NEW.order_status,
            :NEW.user_id
        );


    /*
        Status transition.

        Only create a history row when the status actually
        changes.
    */

    ELSIF UPDATING THEN

        IF NVL(:OLD.order_status, 'NULL')
           <>
           NVL(:NEW.order_status, 'NULL')
        THEN

            INSERT INTO order_status_history (
                order_id,
                old_status,
                new_status,
                changed_by
            )
            VALUES (
                :NEW.order_id,
                :OLD.order_status,
                :NEW.order_status,

                /*
                    UPDATE_ORDER_STATUS sets CLIENT_IDENTIFIER
                    to the authenticated staff/admin user ID.

                    If no identifier is present, fall back
                    to the order owner.
                */
                CASE
                    WHEN SYS_CONTEXT(
                             'USERENV',
                             'CLIENT_IDENTIFIER'
                         ) IS NOT NULL
                    THEN
                        TO_NUMBER(
                            SYS_CONTEXT(
                                'USERENV',
                                'CLIENT_IDENTIFIER'
                            )
                        )
                    ELSE
                        :NEW.user_id
                END
            );

        END IF;

    END IF;

END;
/