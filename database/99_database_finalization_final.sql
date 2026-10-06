-- ============================================================
-- CAMPUS CAFETERIA PREORDER & PICKUP
-- 99_DATABASE_FINALIZATION.SQL
-- Oracle AI Database Free 26ai
--
-- PURPOSE
--   1. Clean the demo data without dropping schema objects.
--   2. Load a deterministic demo dataset for 04-Oct-2026 to 06-Oct-2026.
--   3. Verify tables, relationships, sequences/identity generation,
--      constraints, foreign keys, indexes, PL/SQL objects, views,
--      trigger behavior, order lifecycle, stock protection and
--      pickup-window capacity behavior.
--   4. Create/finalize least-privilege database roles.
--
-- RUN THIS SCRIPT CONNECTED AS SYSTEM TO FREEPDB1.
-- It uses ALTER SESSION SET CURRENT_SCHEMA=CAFETERIA_APP so the
-- application tables are addressed without changing ownership.
--
-- IMPORTANT
--   This script intentionally does NOT drop/recreate tables.
--   It deletes demo data only.
--   Sequence values are NOT reset; generated IDs are verified instead.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET VERIFY OFF
SET FEEDBACK ON
SET PAGESIZE 200
SET LINESIZE 220
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT ============================================================
PROMPT 0. SESSION / SCHEMA CHECK
PROMPT ============================================================

SELECT USER AS connected_user,
       SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AS current_schema,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS service_name
FROM dual;

ALTER SESSION SET CURRENT_SCHEMA = CAFETERIA_APP;

SELECT USER AS connected_user,
       SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AS current_schema
FROM dual;

PROMPT ============================================================
PROMPT 1. VERIFY THE 11 REQUIRED TABLES EXIST
PROMPT ============================================================

SELECT table_name
FROM all_tables
WHERE owner = 'CAFETERIA_APP'
  AND table_name IN (
  'ROLES', 'USERS', 'MENU_DATES', 'MENU_ITEMS', 'INGREDIENTS',
  'ITEM_INGREDIENTS', 'STOCK', 'PICKUP_WINDOWS', 'ORDERS',
  'ORDER_LINES', 'ORDER_STATUS_HISTORY'
)
ORDER BY table_name;

SELECT COUNT(*) AS required_table_count
FROM all_tables
WHERE owner = 'CAFETERIA_APP'
  AND table_name IN (
  'ROLES', 'USERS', 'MENU_DATES', 'MENU_ITEMS', 'INGREDIENTS',
  'ITEM_INGREDIENTS', 'STOCK', 'PICKUP_WINDOWS', 'ORDERS',
  'ORDER_LINES', 'ORDER_STATUS_HISTORY'
);

PROMPT ============================================================
PROMPT 2. CLEAN DEMO DATA
PROMPT ============================================================

-- Child-to-parent order is required because of foreign keys.
DELETE FROM order_status_history;
DELETE FROM order_lines;
DELETE FROM orders;
DELETE FROM item_ingredients;
DELETE FROM stock;
DELETE FROM menu_items;
DELETE FROM menu_dates;
DELETE FROM ingredients;
DELETE FROM pickup_windows;
DELETE FROM users;
DELETE FROM roles;
COMMIT;

PROMPT Demo data cleared.

PROMPT ============================================================
PROMPT 3. LOAD CLEAN DEMO DATA
PROMPT ============================================================

-- ------------------------------------------------------------
-- ROLES
-- ------------------------------------------------------------
INSERT INTO roles (role_name) VALUES ('STUDENT');
INSERT INTO roles (role_name) VALUES ('STAFF');
INSERT INTO roles (role_name) VALUES ('ADMIN');

-- ------------------------------------------------------------
-- USERS
-- These bcrypt hashes correspond to the local demo passwords used
-- by the application:
--   Student: Student@123
--   Staff:   Staff@123
--   Admin:   Admin@123
-- ------------------------------------------------------------
INSERT INTO users (role_id, full_name, email, password_hash)
SELECT role_id, 'Test Student 2', 'teststudent2@cafeteria.local',
  '$2b$12$NwMYI6buAXqm.jSyhoA1keMmW8sejyunphKKn9sdPeGSFb75jOBP6'
FROM roles WHERE role_name = 'STUDENT';

INSERT INTO users (role_id, full_name, email, password_hash)
SELECT role_id, 'Demo Staff', 'staff@cafeteria.local',
  '$2b$12$J59CLbyFdIZP8eKDGApOje/J/mModaXZR4/6RIRYnQHfJv7opbcLi'
FROM roles WHERE role_name = 'STAFF';

INSERT INTO users (role_id, full_name, email, password_hash)
SELECT role_id, 'Demo Administrator', 'admin@cafeteria.local',
  '$2b$12$T6yfRUmS1RrNwx9pDN.IVe.P4MhGgXtVJkn9UDczuiJiuR7RGSx7G'
FROM roles WHERE role_name = 'ADMIN';

-- ------------------------------------------------------------
-- MENU DATES: 04-Oct-2026, 05-Oct-2026, 06-Oct-2026
-- ------------------------------------------------------------
INSERT INTO menu_dates (menu_date, is_published)
VALUES (DATE '2026-10-04', 'Y');

INSERT INTO menu_dates (menu_date, is_published)
VALUES (DATE '2026-10-05', 'Y');

INSERT INTO menu_dates (menu_date, is_published)
VALUES (DATE '2026-10-06', 'Y');

-- ------------------------------------------------------------
-- MENU ITEMS: 5 meals per day = 15 meals
-- ------------------------------------------------------------
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Chicken Biryani', 'Basmati rice with chicken and spices', 120
FROM menu_dates WHERE menu_date = DATE '2026-10-04';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Veg Fried Rice', 'Vegetable fried rice with fresh vegetables', 80
FROM menu_dates WHERE menu_date = DATE '2026-10-04';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Paneer Roll', 'Paneer and vegetables wrapped in flatbread', 70
FROM menu_dates WHERE menu_date = DATE '2026-10-04';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Masala Dosa', 'Crispy dosa with potato masala', 60
FROM menu_dates WHERE menu_date = DATE '2026-10-04';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Egg Rice', 'Spiced rice with egg and vegetables', 90
FROM menu_dates WHERE menu_date = DATE '2026-10-04';

INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Chicken Rice', 'Spiced chicken rice with vegetables', 110
FROM menu_dates WHERE menu_date = DATE '2026-10-05';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Veg Noodles', 'Stir-fried noodles with vegetables', 75
FROM menu_dates WHERE menu_date = DATE '2026-10-05';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Paneer Butter Masala', 'Paneer cooked in tomato-based gravy', 100
FROM menu_dates WHERE menu_date = DATE '2026-10-05';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Aloo Paratha', 'Indian flatbread stuffed with potato', 65
FROM menu_dates WHERE menu_date = DATE '2026-10-05';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Curd Rice', 'Rice with curd and mild seasoning', 55
FROM menu_dates WHERE menu_date = DATE '2026-10-05';

INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Chicken Meal', 'Rice, chicken curry and vegetables', 130
FROM menu_dates WHERE menu_date = DATE '2026-10-06';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Veg Meal', 'Rice, vegetable curry and side dish', 100
FROM menu_dates WHERE menu_date = DATE '2026-10-06';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Paneer Fried Rice', 'Fried rice with paneer and vegetables', 95
FROM menu_dates WHERE menu_date = DATE '2026-10-06';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Masala Dosa', 'Crispy dosa with potato masala', 60
FROM menu_dates WHERE menu_date = DATE '2026-10-06';
INSERT INTO menu_items (menu_date_id, item_name, description, price)
SELECT menu_date_id, 'Veg Sandwich', 'Grilled sandwich with fresh vegetables', 70
FROM menu_dates WHERE menu_date = DATE '2026-10-06';

-- ------------------------------------------------------------
-- INGREDIENTS
-- ------------------------------------------------------------
INSERT INTO ingredients (ingredient_name) VALUES ('Chicken');
INSERT INTO ingredients (ingredient_name) VALUES ('Rice');
INSERT INTO ingredients (ingredient_name) VALUES ('Paneer');
INSERT INTO ingredients (ingredient_name) VALUES ('Wheat');
INSERT INTO ingredients (ingredient_name) VALUES ('Potato');
INSERT INTO ingredients (ingredient_name) VALUES ('Carrot');
INSERT INTO ingredients (ingredient_name) VALUES ('Onion');
INSERT INTO ingredients (ingredient_name) VALUES ('Tomato');
INSERT INTO ingredients (ingredient_name) VALUES ('Capsicum');
INSERT INTO ingredients (ingredient_name) VALUES ('Egg');

-- ------------------------------------------------------------
-- ITEM / INGREDIENT RELATIONSHIPS
-- IMPORTANT: item_name is NOT globally unique because the same
-- meal can appear on multiple menu dates. Match by menu_date + item_name.
-- This avoids duplicate PK_ITEM_INGREDIENTS rows.
-- ------------------------------------------------------------
INSERT INTO item_ingredients (menu_item_id, ingredient_id)
SELECT m.menu_item_id, i.ingredient_id
FROM (
  SELECT DATE '2026-10-04' AS menu_date, 'Chicken Biryani' AS item_name, 'Chicken' AS ingredient_name FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Chicken Biryani', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Chicken Biryani', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Veg Fried Rice', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Veg Fried Rice', 'Carrot' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Veg Fried Rice', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Veg Fried Rice', 'Capsicum' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Paneer Roll', 'Paneer' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Paneer Roll', 'Wheat' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Paneer Roll', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Masala Dosa', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Masala Dosa', 'Potato' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Masala Dosa', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Egg Rice', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Egg Rice', 'Egg' FROM dual
  UNION ALL SELECT DATE '2026-10-04', 'Egg Rice', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Chicken Rice', 'Chicken' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Chicken Rice', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Chicken Rice', 'Carrot' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Veg Noodles', 'Wheat' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Veg Noodles', 'Carrot' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Veg Noodles', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Veg Noodles', 'Capsicum' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Paneer Butter Masala', 'Paneer' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Paneer Butter Masala', 'Tomato' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Paneer Butter Masala', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Aloo Paratha', 'Wheat' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Aloo Paratha', 'Potato' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Aloo Paratha', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Curd Rice', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-05', 'Curd Rice', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Chicken Meal', 'Chicken' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Chicken Meal', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Chicken Meal', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Veg Meal', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Veg Meal', 'Potato' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Veg Meal', 'Tomato' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Paneer Fried Rice', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Paneer Fried Rice', 'Paneer' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Paneer Fried Rice', 'Capsicum' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Masala Dosa', 'Rice' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Masala Dosa', 'Potato' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Masala Dosa', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Veg Sandwich', 'Wheat' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Veg Sandwich', 'Carrot' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Veg Sandwich', 'Onion' FROM dual
  UNION ALL SELECT DATE '2026-10-06', 'Veg Sandwich', 'Capsicum' FROM dual
) x
JOIN menu_dates md
  ON md.menu_date = x.menu_date
JOIN menu_items m
  ON m.menu_date_id = md.menu_date_id
 AND m.item_name = x.item_name
JOIN ingredients i
  ON i.ingredient_name = x.ingredient_name;
-- ------------------------------------------------------------
-- STOCK: 50 portions per menu item
-- ------------------------------------------------------------
INSERT INTO stock (menu_item_id, available_qty)
SELECT menu_item_id, 50
FROM menu_items;

-- ------------------------------------------------------------
-- PICKUP WINDOWS: 3 windows/day, capacity 20 each
-- ------------------------------------------------------------
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-04', DATE '2026-10-04' + INTERVAL '12' HOUR + INTERVAL '0' MINUTE, DATE '2026-10-04' + INTERVAL '12' HOUR + INTERVAL '30' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-04', DATE '2026-10-04' + INTERVAL '12' HOUR + INTERVAL '30' MINUTE, DATE '2026-10-04' + INTERVAL '13' HOUR + INTERVAL '0' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-04', DATE '2026-10-04' + INTERVAL '13' HOUR + INTERVAL '0' MINUTE, DATE '2026-10-04' + INTERVAL '13' HOUR + INTERVAL '30' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-05', DATE '2026-10-05' + INTERVAL '12' HOUR + INTERVAL '0' MINUTE, DATE '2026-10-05' + INTERVAL '12' HOUR + INTERVAL '30' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-05', DATE '2026-10-05' + INTERVAL '12' HOUR + INTERVAL '30' MINUTE, DATE '2026-10-05' + INTERVAL '13' HOUR + INTERVAL '0' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-05', DATE '2026-10-05' + INTERVAL '13' HOUR + INTERVAL '0' MINUTE, DATE '2026-10-05' + INTERVAL '13' HOUR + INTERVAL '30' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-06', DATE '2026-10-06' + INTERVAL '12' HOUR + INTERVAL '0' MINUTE, DATE '2026-10-06' + INTERVAL '12' HOUR + INTERVAL '30' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-06', DATE '2026-10-06' + INTERVAL '12' HOUR + INTERVAL '30' MINUTE, DATE '2026-10-06' + INTERVAL '13' HOUR + INTERVAL '0' MINUTE, 20, 0);
INSERT INTO pickup_windows (window_date, start_time, end_time, capacity, reserved_count)
VALUES (DATE '2026-10-06', DATE '2026-10-06' + INTERVAL '13' HOUR + INTERVAL '0' MINUTE, DATE '2026-10-06' + INTERVAL '13' HOUR + INTERVAL '30' MINUTE, 20, 0);

COMMIT;

PROMPT Clean demo dataset loaded.

PROMPT ============================================================
PROMPT 4. DATASET COUNTS
PROMPT ============================================================

SELECT 'ROLES' table_name, COUNT(*) row_count FROM roles
UNION ALL SELECT 'USERS', COUNT(*) FROM users
UNION ALL SELECT 'MENU_DATES', COUNT(*) FROM menu_dates
UNION ALL SELECT 'MENU_ITEMS', COUNT(*) FROM menu_items
UNION ALL SELECT 'INGREDIENTS', COUNT(*) FROM ingredients
UNION ALL SELECT 'ITEM_INGREDIENTS', COUNT(*) FROM item_ingredients
UNION ALL SELECT 'STOCK', COUNT(*) FROM stock
UNION ALL SELECT 'PICKUP_WINDOWS', COUNT(*) FROM pickup_windows
UNION ALL SELECT 'ORDERS', COUNT(*) FROM orders
UNION ALL SELECT 'ORDER_LINES', COUNT(*) FROM order_lines
UNION ALL SELECT 'ORDER_STATUS_HISTORY', COUNT(*) FROM order_status_history
ORDER BY table_name;

PROMPT ============================================================
PROMPT 5. VERIFY MENU / STOCK / PICKUP DATA
PROMPT ============================================================

SELECT md.menu_date_id,
       TO_CHAR(md.menu_date,'YYYY-MM-DD') AS menu_date,
       md.is_published,
       COUNT(mi.menu_item_id) AS meal_count
FROM menu_dates md
LEFT JOIN menu_items mi ON mi.menu_date_id = md.menu_date_id
GROUP BY md.menu_date_id, md.menu_date, md.is_published
ORDER BY md.menu_date;

SELECT mi.menu_item_id,
       TO_CHAR(md.menu_date,'YYYY-MM-DD') AS menu_date,
       mi.item_name,
       mi.price,
       mi.is_available,
       s.available_qty
FROM menu_items mi
JOIN menu_dates md ON md.menu_date_id = mi.menu_date_id
JOIN stock s ON s.menu_item_id = mi.menu_item_id
ORDER BY md.menu_date, mi.menu_item_id;

SELECT pickup_window_id,
       TO_CHAR(window_date,'YYYY-MM-DD') AS window_date,
       TO_CHAR(start_time,'HH24:MI') AS start_time,
       TO_CHAR(end_time,'HH24:MI') AS end_time,
       capacity,
       reserved_count,
       capacity - reserved_count AS available_capacity
FROM pickup_windows
ORDER BY window_date, start_time;

PROMPT ============================================================
PROMPT 6. VERIFY PRIMARY/UNIQUE/CHECK/FOREIGN KEY CONSTRAINTS
PROMPT ============================================================

SELECT constraint_name,
       table_name,
       constraint_type,
       status,
       r_constraint_name,
       delete_rule
FROM user_constraints
WHERE table_name IN (
  'ROLES','USERS','MENU_DATES','MENU_ITEMS','INGREDIENTS',
  'ITEM_INGREDIENTS','STOCK','PICKUP_WINDOWS','ORDERS',
  'ORDER_LINES','ORDER_STATUS_HISTORY'
)
ORDER BY table_name, constraint_type, constraint_name;

PROMPT --- Constraint columns ---
SELECT table_name,
       constraint_name,
       constraint_type,
       position,
       column_name
FROM user_cons_columns
WHERE table_name IN (
  'ROLES','USERS','MENU_DATES','MENU_ITEMS','INGREDIENTS',
  'ITEM_INGREDIENTS','STOCK','PICKUP_WINDOWS','ORDERS',
  'ORDER_LINES','ORDER_STATUS_HISTORY'
)
ORDER BY table_name, constraint_name, position;

PROMPT --- Disabled constraints ---
SELECT constraint_name, table_name, status
FROM user_constraints
WHERE status <> 'ENABLED'
  AND table_name IN (
    'ROLES','USERS','MENU_DATES','MENU_ITEMS','INGREDIENTS',
    'ITEM_INGREDIENTS','STOCK','PICKUP_WINDOWS','ORDERS',
    'ORDER_LINES','ORDER_STATUS_HISTORY'
  );

PROMPT ============================================================
PROMPT 7. VERIFY INDEXES
PROMPT ============================================================

SELECT index_name,
       table_name,
       index_type,
       uniqueness,
       status
FROM user_indexes
WHERE table_name IN (
  'ROLES','USERS','MENU_DATES','MENU_ITEMS','INGREDIENTS',
  'ITEM_INGREDIENTS','STOCK','PICKUP_WINDOWS','ORDERS',
  'ORDER_LINES','ORDER_STATUS_HISTORY'
)
ORDER BY table_name, index_name;

PROMPT --- Index columns ---
SELECT index_name,
       table_name,
       column_position,
       column_name
FROM user_ind_columns
WHERE table_name IN (
  'ROLES','USERS','MENU_DATES','MENU_ITEMS','INGREDIENTS',
  'ITEM_INGREDIENTS','STOCK','PICKUP_WINDOWS','ORDERS',
  'ORDER_LINES','ORDER_STATUS_HISTORY'
)
ORDER BY table_name, index_name, column_position;

PROMPT ============================================================
PROMPT 8. VERIFY SEQUENCES / IDENTITY GENERATION
PROMPT ============================================================

PROMPT --- User-owned sequences ---
SELECT sequence_name,
       min_value,
       max_value,
       increment_by,
       last_number,
       cache_size,
       cycle_flag
FROM user_sequences
ORDER BY sequence_name;

PROMPT --- Identity columns ---
SELECT table_name,
       column_name,
       generation_type,
       identity_options
FROM user_tab_identity_cols
WHERE table_name IN (
  'ROLES','USERS','MENU_DATES','MENU_ITEMS','INGREDIENTS',
  'ITEM_INGREDIENTS','STOCK','PICKUP_WINDOWS','ORDERS',
  'ORDER_LINES','ORDER_STATUS_HISTORY'
)
ORDER BY table_name, column_name;

PROMPT --- Maximum generated IDs currently present ---
SELECT 'ROLES' table_name, NVL(MAX(role_id),0) max_id FROM roles
UNION ALL SELECT 'USERS', NVL(MAX(user_id),0) FROM users
UNION ALL SELECT 'MENU_DATES', NVL(MAX(menu_date_id),0) FROM menu_dates
UNION ALL SELECT 'MENU_ITEMS', NVL(MAX(menu_item_id),0) FROM menu_items
UNION ALL SELECT 'INGREDIENTS', NVL(MAX(ingredient_id),0) FROM ingredients
UNION ALL SELECT 'PICKUP_WINDOWS', NVL(MAX(pickup_window_id),0) FROM pickup_windows
UNION ALL SELECT 'ORDERS', NVL(MAX(order_id),0) FROM orders
UNION ALL SELECT 'ORDER_STATUS_HISTORY', NVL(MAX(history_id),0) FROM order_status_history
ORDER BY table_name;

PROMPT ============================================================
PROMPT 9. VERIFY PL/SQL OBJECTS
PROMPT ============================================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
  'PLACE_ORDER','CANCEL_ORDER','GET_PICKUP_QUEUE','UPDATE_ORDER_STATUS'
)
ORDER BY object_type, object_name;

PROMPT --- PL/SQL signatures ---
SELECT object_name,
       overload,
       position,
       argument_name,
       in_out,
       data_type,
       type_name
FROM user_arguments
WHERE object_name IN (
  'PLACE_ORDER','CANCEL_ORDER','GET_PICKUP_QUEUE','UPDATE_ORDER_STATUS'
)
ORDER BY object_name, overload, position;

PROMPT ============================================================
PROMPT 10. VERIFY ORDER STATUS TRIGGER
PROMPT ============================================================

SELECT trigger_name,
       table_name,
       triggering_event,
       trigger_type,
       status
FROM user_triggers
WHERE table_name = 'ORDERS'
ORDER BY trigger_name;

PROMPT --- Trigger source ---
SELECT trigger_name,
       trigger_body
FROM user_triggers
WHERE table_name = 'ORDERS'
ORDER BY trigger_name;

PROMPT ============================================================
PROMPT 11. VERIFY REPORT VIEWS
PROMPT ============================================================

SELECT view_name
FROM user_views
ORDER BY view_name;

PROMPT --- Report/view definitions owned by this schema ---
SELECT view_name,
       text
FROM user_views
ORDER BY view_name;

PROMPT ============================================================
PROMPT 12. VERIFY REFERENTIAL INTEGRITY WITH ORPHAN CHECKS
PROMPT ============================================================

SELECT COUNT(*) AS orphan_users
FROM users u
LEFT JOIN roles r ON r.role_id = u.role_id
WHERE r.role_id IS NULL;

SELECT COUNT(*) AS orphan_menu_items
FROM menu_items mi
LEFT JOIN menu_dates md ON md.menu_date_id = mi.menu_date_id
WHERE md.menu_date_id IS NULL;

SELECT COUNT(*) AS orphan_item_ingredients
FROM item_ingredients ii
LEFT JOIN menu_items mi ON mi.menu_item_id = ii.menu_item_id
LEFT JOIN ingredients i ON i.ingredient_id = ii.ingredient_id
WHERE mi.menu_item_id IS NULL OR i.ingredient_id IS NULL;

SELECT COUNT(*) AS orphan_stock
FROM stock s
LEFT JOIN menu_items mi ON mi.menu_item_id = s.menu_item_id
WHERE mi.menu_item_id IS NULL;

SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN users u ON u.user_id = o.user_id
LEFT JOIN pickup_windows pw ON pw.pickup_window_id = o.pickup_window_id
WHERE u.user_id IS NULL OR pw.pickup_window_id IS NULL;

SELECT COUNT(*) AS orphan_order_lines
FROM order_lines ol
LEFT JOIN orders o ON o.order_id = ol.order_id
LEFT JOIN menu_items mi ON mi.menu_item_id = ol.menu_item_id
WHERE o.order_id IS NULL OR mi.menu_item_id IS NULL;

SELECT COUNT(*) AS orphan_status_history
FROM order_status_history h
LEFT JOIN orders o ON o.order_id = h.order_id
LEFT JOIN users u ON u.user_id = h.changed_by
WHERE o.order_id IS NULL OR u.user_id IS NULL;

PROMPT ============================================================
PROMPT 13. BEHAVIORAL TEST: PLACE_ORDER
PROMPT ============================================================

VARIABLE v_student_id NUMBER
VARIABLE v_staff_id NUMBER
VARIABLE v_test_order_id NUMBER
VARIABLE v_test_pickup_code VARCHAR2(50)
VARIABLE v_test_total NUMBER
VARIABLE v_test_window_id NUMBER
VARIABLE v_test_item_id NUMBER

BEGIN
  SELECT user_id INTO :v_student_id
  FROM users
  WHERE email = 'teststudent2@cafeteria.local';

  SELECT user_id INTO :v_staff_id
  FROM users
  WHERE email = 'staff@cafeteria.local';

  SELECT pickup_window_id INTO :v_test_window_id
  FROM pickup_windows
  WHERE window_date = DATE '2026-10-06'
    AND start_time = DATE '2026-10-06' + INTERVAL '12' HOUR;

  SELECT menu_item_id INTO :v_test_item_id
  FROM menu_items
  WHERE item_name = 'Chicken Meal'
    AND menu_date_id = (
      SELECT menu_date_id FROM menu_dates
      WHERE menu_date = DATE '2026-10-06'
    );

  place_order(
    p_user_id          => :v_student_id,
    p_pickup_window_id => :v_test_window_id,
    p_menu_item_ids    => SYS.ODCINUMBERLIST(:v_test_item_id),
    p_quantities       => SYS.ODCINUMBERLIST(1),
    p_order_id         => :v_test_order_id,
    p_pickup_code      => :v_test_pickup_code,
    p_total_amount     => :v_test_total
  );

  DBMS_OUTPUT.PUT_LINE(
    'PASS: PLACE_ORDER created order ' || :v_test_order_id ||
    ', pickup code ' || :v_test_pickup_code ||
    ', total ' || :v_test_total
  );
END;
/

PRINT v_test_order_id
PRINT v_test_pickup_code
PRINT v_test_total

SELECT order_id, user_id, pickup_window_id, pickup_code,
       order_status, total_amount, ordered_at, cancelled_at
FROM orders
WHERE order_id = :v_test_order_id;

SELECT order_id, menu_item_id, quantity, unit_price
FROM order_lines
WHERE order_id = :v_test_order_id;

PROMPT ============================================================
PROMPT 14. VERIFY STATUS TRIGGER ON INITIAL PLACED STATUS
PROMPT ============================================================

SELECT history_id, order_id, old_status, new_status,
       changed_by, changed_at
FROM order_status_history
WHERE order_id = :v_test_order_id
ORDER BY history_id;

PROMPT ============================================================
PROMPT 15. BEHAVIORAL TEST: UPDATE_ORDER_STATUS
PROMPT ============================================================

BEGIN
  update_order_status(:v_test_order_id, 'PREPARING', :v_staff_id);
  update_order_status(:v_test_order_id, 'READY', :v_staff_id);
  update_order_status(:v_test_order_id, 'COLLECTED', :v_staff_id);

  DBMS_OUTPUT.PUT_LINE('PASS: ORDER STATUS lifecycle PLACED -> PREPARING -> READY -> COLLECTED');
END;
/

SELECT order_id, order_status
FROM orders
WHERE order_id = :v_test_order_id;

SELECT history_id, order_id, old_status, new_status,
       changed_by, changed_at
FROM order_status_history
WHERE order_id = :v_test_order_id
ORDER BY history_id;

PROMPT ============================================================
PROMPT 16. VERIFY COLLECTED-ORDER CAPACITY BEHAVIOR
PROMPT ============================================================

SELECT pickup_window_id,
       capacity,
       reserved_count,
       capacity - reserved_count AS available_capacity
FROM pickup_windows
WHERE window_date = DATE '2026-10-06'
  AND start_time = DATE '2026-10-06' + INTERVAL '12' HOUR;

PROMPT Capacity behavior above is reported from the implemented procedure.
PROMPT If COLLECTED is designed to release capacity, reserved_count should
PROMPT return to the pre-order value. If not, the stored procedure retains
PROMPT the reservation by design.

PROMPT ============================================================
PROMPT 17. BEHAVIORAL TEST: CANCEL_ORDER
PROMPT ============================================================

VARIABLE v_cancel_order_id NUMBER
VARIABLE v_cancel_pickup_code VARCHAR2(50)
VARIABLE v_cancel_total NUMBER
VARIABLE v_cancel_window_id NUMBER
VARIABLE v_cancel_item_id NUMBER
VARIABLE v_stock_before_cancel NUMBER
VARIABLE v_reserved_before_cancel NUMBER
VARIABLE v_stock_after_cancel NUMBER
VARIABLE v_reserved_after_cancel NUMBER

BEGIN
  SELECT pickup_window_id INTO :v_cancel_window_id
  FROM pickup_windows
  WHERE window_date = DATE '2026-10-06'
    AND start_time = DATE '2026-10-06' + INTERVAL '12' HOUR + INTERVAL '30' MINUTE;

  SELECT menu_item_id INTO :v_cancel_item_id
  FROM menu_items
  WHERE item_name = 'Veg Meal'
    AND menu_date_id = (
      SELECT menu_date_id FROM menu_dates
      WHERE menu_date = DATE '2026-10-06'
    );

  SELECT available_qty INTO :v_stock_before_cancel
  FROM stock
  WHERE menu_item_id = :v_cancel_item_id;

  SELECT reserved_count INTO :v_reserved_before_cancel
  FROM pickup_windows
  WHERE pickup_window_id = :v_cancel_window_id;

  place_order(
    p_user_id          => :v_student_id,
    p_pickup_window_id => :v_cancel_window_id,
    p_menu_item_ids    => SYS.ODCINUMBERLIST(:v_cancel_item_id),
    p_quantities       => SYS.ODCINUMBERLIST(1),
    p_order_id         => :v_cancel_order_id,
    p_pickup_code      => :v_cancel_pickup_code,
    p_total_amount     => :v_cancel_total
  );

  cancel_order(
    p_order_id => :v_cancel_order_id,
    p_user_id  => :v_student_id
  );

  SELECT available_qty INTO :v_stock_after_cancel
  FROM stock
  WHERE menu_item_id = :v_cancel_item_id;

  SELECT reserved_count INTO :v_reserved_after_cancel
  FROM pickup_windows
  WHERE pickup_window_id = :v_cancel_window_id;

  DBMS_OUTPUT.PUT_LINE(
    'PASS: CANCEL_ORDER completed for order ' || :v_cancel_order_id
  );

  IF :v_stock_after_cancel = :v_stock_before_cancel
     AND :v_reserved_after_cancel = :v_reserved_before_cancel THEN
    DBMS_OUTPUT.PUT_LINE('PASS: cancellation restored stock and pickup capacity');
  ELSE
    DBMS_OUTPUT.PUT_LINE('CHECK: cancellation did not restore one or more counters');
  END IF;
END;
/

SELECT order_id, order_status, cancelled_at
FROM orders
WHERE order_id = :v_cancel_order_id;

PROMPT ============================================================
PROMPT 18. VERIFY PICKUP QUEUE CURSOR
PROMPT ============================================================

VARIABLE v_queue_order_id NUMBER
VARIABLE v_queue_pickup_code VARCHAR2(50)
VARIABLE v_queue_total NUMBER
VARIABLE v_queue_window_id NUMBER
VARIABLE v_queue_item_id NUMBER
VARIABLE v_queue REFCURSOR

BEGIN
  SELECT pickup_window_id INTO :v_queue_window_id
  FROM pickup_windows
  WHERE window_date = DATE '2026-10-06'
    AND start_time = DATE '2026-10-06' + INTERVAL '13' HOUR;

  SELECT menu_item_id INTO :v_queue_item_id
  FROM menu_items
  WHERE item_name = 'Veg Sandwich'
    AND menu_date_id = (
      SELECT menu_date_id FROM menu_dates
      WHERE menu_date = DATE '2026-10-06'
    );

  place_order(
    p_user_id          => :v_student_id,
    p_pickup_window_id => :v_queue_window_id,
    p_menu_item_ids    => SYS.ODCINUMBERLIST(:v_queue_item_id),
    p_quantities       => SYS.ODCINUMBERLIST(1),
    p_order_id         => :v_queue_order_id,
    p_pickup_code      => :v_queue_pickup_code,
    p_total_amount     => :v_queue_total
  );

  DBMS_OUTPUT.PUT_LINE('PASS: queue test order created: ' || :v_queue_order_id);

  get_pickup_queue(:v_queue_window_id, :v_queue);

END;
/

PRINT v_queue

PROMPT ============================================================
PROMPT 19. VERIFY STOCK / QUANTITY PROTECTION AT PROCEDURE LEVEL
PROMPT ============================================================

SELECT name, type, line, text
FROM user_source
WHERE name IN ('PLACE_ORDER','CANCEL_ORDER','UPDATE_ORDER_STATUS')
  AND type = 'PROCEDURE'
  AND (
       UPPER(text) LIKE '%FOR UPDATE%'
       OR UPPER(text) LIKE '%RESERVED_COUNT%'
       OR UPPER(text) LIKE '%AVAILABLE_QTY%'
       OR UPPER(text) LIKE '%ROLLBACK%'
       OR UPPER(text) LIKE '%RAISE_APPLICATION_ERROR%'
      )
ORDER BY name, line;

PROMPT ============================================================
PROMPT 20. NEGATIVE TEST: INSUFFICIENT STOCK
PROMPT ============================================================

VARIABLE v_negative_item_id NUMBER

BEGIN
  SELECT menu_item_id INTO :v_negative_item_id
  FROM menu_items
  WHERE item_name = 'Paneer Fried Rice'
    AND menu_date_id = (
      SELECT menu_date_id FROM menu_dates
      WHERE menu_date = DATE '2026-10-06'
    );

  UPDATE stock
  SET available_qty = 0
  WHERE menu_item_id = :v_negative_item_id;

  COMMIT;

  BEGIN
    place_order(
      p_user_id          => :v_student_id,
      p_pickup_window_id => :v_queue_window_id,
      p_menu_item_ids    => SYS.ODCINUMBERLIST(:v_negative_item_id),
      p_quantities       => SYS.ODCINUMBERLIST(1),
      p_order_id         => :v_test_order_id,
      p_pickup_code      => :v_test_pickup_code,
      p_total_amount     => :v_test_total
    );

    DBMS_OUTPUT.PUT_LINE('FAIL: insufficient-stock order unexpectedly succeeded.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('PASS: insufficient-stock order rejected: ' || SQLERRM);
  END;

  UPDATE stock SET available_qty = 50
  WHERE menu_item_id = :v_negative_item_id;
  COMMIT;
END;
/

PROMPT ============================================================
PROMPT 21. PICKUP CAPACITY NEGATIVE TEST
PROMPT ============================================================

-- The procedure must reject an order when reserved_count reaches capacity.
-- We temporarily fill one pickup window with 20 orders using one item.
DECLARE
  v_window NUMBER;
  v_item NUMBER;
  v_oid NUMBER;
  v_code VARCHAR2(50);
  v_total NUMBER;
  v_count NUMBER;
BEGIN
  SELECT pickup_window_id INTO v_window
  FROM pickup_windows
  WHERE window_date = DATE '2026-10-06'
    AND start_time = DATE '2026-10-06' + INTERVAL '12' HOUR;

  SELECT menu_item_id INTO v_item
  FROM menu_items
  WHERE item_name = 'Chicken Meal'
    AND menu_date_id = (
      SELECT menu_date_id FROM menu_dates
      WHERE menu_date = DATE '2026-10-06'
    );

  FOR i IN 1..20 LOOP
    place_order(
      p_user_id          => :v_student_id,
      p_pickup_window_id => v_window,
      p_menu_item_ids    => SYS.ODCINUMBERLIST(v_item),
      p_quantities       => SYS.ODCINUMBERLIST(1),
      p_order_id         => v_oid,
      p_pickup_code      => v_code,
      p_total_amount     => v_total
    );
  END LOOP;

  SELECT reserved_count INTO v_count
  FROM pickup_windows
  WHERE pickup_window_id = v_window;

  IF v_count = 20 THEN
    DBMS_OUTPUT.PUT_LINE('PASS: pickup capacity reached exactly 20.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('FAIL: expected reserved_count 20, got ' || v_count);
  END IF;

  BEGIN
    place_order(
      p_user_id          => :v_student_id,
      p_pickup_window_id => v_window,
      p_menu_item_ids    => SYS.ODCINUMBERLIST(v_item),
      p_quantities       => SYS.ODCINUMBERLIST(1),
      p_order_id         => v_oid,
      p_pickup_code      => v_code,
      p_total_amount     => v_total
    );

    DBMS_OUTPUT.PUT_LINE('FAIL: 21st pickup reservation unexpectedly succeeded.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('PASS: 21st pickup reservation rejected: ' || SQLERRM);
  END;
END;
/

PROMPT ============================================================
PROMPT 22. CLEAN TEST ORDERS AND RESTORE CLEAN DEMO STATE
PROMPT ============================================================

DELETE FROM order_status_history;
DELETE FROM order_lines;
DELETE FROM orders;

UPDATE stock SET available_qty = 50;
UPDATE pickup_windows SET reserved_count = 0;

COMMIT;

PROMPT ============================================================
PROMPT 23. VERIFY REPORT VIEWS AFTER CLEANUP
PROMPT ============================================================

SELECT view_name
FROM user_views
ORDER BY view_name;

PROMPT ============================================================
PROMPT 24. DCL / LEAST PRIVILEGE FINALIZATION
PROMPT ============================================================

BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE CAFETERIA_RUNTIME_ROLE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1921 THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE CAFETERIA_REPORT_ROLE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1921 THEN
      RAISE;
    END IF;
END;
/

GRANT SELECT ON cafeteria_app.roles TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.menu_dates TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.menu_items TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.ingredients TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.item_ingredients TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.stock TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.pickup_windows TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.orders TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.order_lines TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.order_status_history TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.place_order TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.cancel_order TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.get_pickup_queue TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.update_order_status TO cafeteria_runtime_role;

GRANT SELECT ON cafeteria_app.roles TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.menu_dates TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.menu_items TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.ingredients TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.item_ingredients TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.stock TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.pickup_windows TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.orders TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.order_lines TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.order_status_history TO cafeteria_report_role;

PROMPT --- Current role grants ---
SELECT grantee, granted_role, default_role
FROM dba_role_privs
WHERE grantee IN ('CAFETERIA_APP','CAFETERIA_RUNTIME_ROLE','CAFETERIA_REPORT_ROLE')
ORDER BY grantee, granted_role;

PROMPT --- Runtime object privileges ---
SELECT grantee, owner, table_name, privilege
FROM dba_tab_privs
WHERE grantee = 'CAFETERIA_RUNTIME_ROLE'
ORDER BY table_name, privilege;

PROMPT --- Reporting object privileges ---
SELECT grantee, owner, table_name, privilege
FROM dba_tab_privs
WHERE grantee = 'CAFETERIA_REPORT_ROLE'
ORDER BY table_name, privilege;

PROMPT ============================================================
PROMPT 25. FINAL CLEAN-STATE CHECK
PROMPT ============================================================

SELECT 'ROLES' table_name, COUNT(*) row_count FROM roles
UNION ALL SELECT 'USERS', COUNT(*) FROM users
UNION ALL SELECT 'MENU_DATES', COUNT(*) FROM menu_dates
UNION ALL SELECT 'MENU_ITEMS', COUNT(*) FROM menu_items
UNION ALL SELECT 'INGREDIENTS', COUNT(*) FROM ingredients
UNION ALL SELECT 'ITEM_INGREDIENTS', COUNT(*) FROM item_ingredients
UNION ALL SELECT 'STOCK', COUNT(*) FROM stock
UNION ALL SELECT 'PICKUP_WINDOWS', COUNT(*) FROM pickup_windows
UNION ALL SELECT 'ORDERS', COUNT(*) FROM orders
UNION ALL SELECT 'ORDER_LINES', COUNT(*) FROM order_lines
UNION ALL SELECT 'ORDER_STATUS_HISTORY', COUNT(*) FROM order_status_history
ORDER BY table_name;

SELECT 'FINAL DATASET CHECK' AS check_name,
       CASE
         WHEN (SELECT COUNT(*) FROM roles) = 3
          AND (SELECT COUNT(*) FROM users) = 3
          AND (SELECT COUNT(*) FROM menu_dates) = 3
          AND (SELECT COUNT(*) FROM menu_items) = 15
          AND (SELECT COUNT(*) FROM ingredients) = 10
          AND (SELECT COUNT(*) FROM item_ingredients) > 0
          AND (SELECT COUNT(*) FROM stock) = 15
          AND (SELECT COUNT(*) FROM pickup_windows) = 9
          AND (SELECT COUNT(*) FROM orders) = 0
          AND (SELECT COUNT(*) FROM order_lines) = 0
          AND (SELECT COUNT(*) FROM order_status_history) = 0
         THEN 'PASS'
         ELSE 'FAIL'
       END AS result
FROM dual;

SELECT 'FINAL PICKUP CAPACITY CHECK' AS check_name,
       CASE
         WHEN (SELECT COUNT(*) FROM pickup_windows
               WHERE capacity = 20 AND reserved_count = 0) = 9
         THEN 'PASS'
         ELSE 'FAIL'
       END AS result
FROM dual;

SELECT 'FINAL STOCK CHECK' AS check_name,
       CASE
         WHEN (SELECT COUNT(*) FROM stock WHERE available_qty = 50) = 15
         THEN 'PASS'
         ELSE 'FAIL'
       END AS result
FROM dual;

COMMIT;

PROMPT ============================================================
PROMPT DATABASE FINALIZATION COMPLETE
PROMPT ============================================================
PROMPT Schema preserved. Demo data cleaned and reseeded.
PROMPT Behavioral test orders removed after verification.
PROMPT Sequence values intentionally not reset.
PROMPT A true two-session concurrency test is still recommended for
PROMPT a formal race-condition demonstration; this script verifies
PROMPT stored locking source and sequential stock/capacity rejection.
PROMPT ============================================================

EXIT SUCCESS
PROMPT ============================================================
PROMPT 22. VERIFY REPORT VIEWS AFTER CLEANUP
PROMPT ============================================================

SELECT view_name
FROM all_views
WHERE owner = 'CAFETERIA_APP'
ORDER BY view_name;

PROMPT ============================================================
PROMPT 23. DCL / LEAST PRIVILEGE FINALIZATION
PROMPT ============================================================

-- Create separate database roles. They are intentionally separate from
-- the CAFETERIA_APP schema owner.
BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE CAFETERIA_RUNTIME_ROLE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1921 THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE CAFETERIA_REPORT_ROLE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1921 THEN
      RAISE;
    END IF;
END;
/

-- Runtime role: only the operations required by the web application.
GRANT SELECT ON cafeteria_app.roles TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.menu_dates TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.menu_items TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.ingredients TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.item_ingredients TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.stock TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.pickup_windows TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.orders TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.order_lines TO cafeteria_runtime_role;
GRANT SELECT ON cafeteria_app.order_status_history TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.place_order TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.cancel_order TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.get_pickup_queue TO cafeteria_runtime_role;
GRANT EXECUTE ON cafeteria_app.update_order_status TO cafeteria_runtime_role;

-- Reporting role: read-only reporting access.
GRANT SELECT ON cafeteria_app.roles TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.menu_dates TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.menu_items TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.ingredients TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.item_ingredients TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.stock TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.pickup_windows TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.orders TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.order_lines TO cafeteria_report_role;
GRANT SELECT ON cafeteria_app.order_status_history TO cafeteria_report_role;

-- NOTE: CAFETERIA_APP is the schema owner and therefore inherently has
-- owner privileges. Do NOT grant the runtime role to the owner as a way
-- of claiming least privilege. The role is finalized for a future
-- separate runtime account. The backend must be switched to that account
-- before least privilege is enforced at runtime.

PROMPT --- Current role grants ---
SELECT grantee,
       granted_role,
       default_role
FROM dba_role_privs
WHERE grantee IN ('CAFETERIA_APP','CAFETERIA_RUNTIME_ROLE','CAFETERIA_REPORT_ROLE')
ORDER BY grantee, granted_role;

PROMPT --- Runtime object privileges ---
SELECT grantee,
       owner,
       table_name,
       privilege
FROM dba_tab_privs
WHERE grantee = 'CAFETERIA_RUNTIME_ROLE'
ORDER BY table_name, privilege;

PROMPT --- Reporting object privileges ---
SELECT grantee,
       owner,
       table_name,
       privilege
FROM dba_tab_privs
WHERE grantee = 'CAFETERIA_REPORT_ROLE'
ORDER BY table_name, privilege;

PROMPT ============================================================
PROMPT 24. FINAL CLEAN-STATE CHECK
PROMPT ============================================================

SELECT 'ROLES' table_name, COUNT(*) row_count FROM roles
UNION ALL SELECT 'USERS', COUNT(*) FROM users
UNION ALL SELECT 'MENU_DATES', COUNT(*) FROM menu_dates
UNION ALL SELECT 'MENU_ITEMS', COUNT(*) FROM menu_items
UNION ALL SELECT 'INGREDIENTS', COUNT(*) FROM ingredients
UNION ALL SELECT 'ITEM_INGREDIENTS', COUNT(*) FROM item_ingredients
UNION ALL SELECT 'STOCK', COUNT(*) FROM stock
UNION ALL SELECT 'PICKUP_WINDOWS', COUNT(*) FROM pickup_windows
UNION ALL SELECT 'ORDERS', COUNT(*) FROM orders
UNION ALL SELECT 'ORDER_LINES', COUNT(*) FROM order_lines
UNION ALL SELECT 'ORDER_STATUS_HISTORY', COUNT(*) FROM order_status_history
ORDER BY table_name;

SELECT 'FINAL DATASET CHECK' AS check_name,
       CASE
         WHEN (SELECT COUNT(*) FROM roles) = 3
          AND (SELECT COUNT(*) FROM users) = 3
          AND (SELECT COUNT(*) FROM menu_dates) = 3
          AND (SELECT COUNT(*) FROM menu_items) = 15
          AND (SELECT COUNT(*) FROM ingredients) = 10
          AND (SELECT COUNT(*) FROM stock) = 15
          AND (SELECT COUNT(*) FROM pickup_windows) = 9
          AND (SELECT COUNT(*) FROM orders) = 0
          AND (SELECT COUNT(*) FROM order_lines) = 0
          AND (SELECT COUNT(*) FROM order_status_history) = 0
         THEN 'PASS'
         ELSE 'FAIL'
       END AS result
FROM dual;

SELECT 'FINAL PICKUP CAPACITY CHECK' AS check_name,
       CASE
         WHEN (SELECT COUNT(*) FROM pickup_windows WHERE capacity = 20 AND reserved_count = 0) = 9
         THEN 'PASS'
         ELSE 'FAIL'
       END AS result
FROM dual;

SELECT 'FINAL STOCK CHECK' AS check_name,
       CASE
         WHEN (SELECT COUNT(*) FROM stock WHERE available_qty = 50) = 15
         THEN 'PASS'
         ELSE 'FAIL'
       END AS result
FROM dual;

COMMIT;

PROMPT ============================================================
PROMPT DATABASE FINALIZATION COMPLETE
PROMPT ============================================================
PROMPT The schema was preserved. Demo data was cleaned and reseeded.
PROMPT Behavioral test orders were removed after verification.
PROMPT Sequence values were intentionally not reset.
PROMPT True two-session concurrency testing is still recommended for
PROMPT a formal overselling demonstration; this script performs source-
PROMPT level locking checks and sequential stock rejection testing.
PROMPT ============================================================

EXIT SUCCESS
