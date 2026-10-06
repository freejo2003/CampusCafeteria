-- ============================================================
-- CAMPUS CAFETERIA
-- Clean Demo Seed
-- Dates: 04/10/2026 - 06/10/2026
-- 5 meals per day
-- 3 pickup windows per day
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- 1. ROLES
-- ============================================================

INSERT INTO roles (role_id, role_name)
VALUES (1, 'STUDENT');

INSERT INTO roles (role_id, role_name)
VALUES (2, 'STAFF');

INSERT INTO roles (role_id, role_name)
VALUES (3, 'ADMIN');


-- ============================================================
-- 2. USERS
-- Passwords are intended for local academic/demo use.
--
-- Student: teststudent2@cafeteria.local
-- Staff:   staff@cafeteria.local
-- Admin:   admin@cafeteria.local
--
-- Passwords will be set through the existing backend
-- password utility rather than storing plaintext here.
-- ============================================================

INSERT INTO users (
    user_id,
    full_name,
    email,
    password_hash,
    role_id,
    is_active
)
VALUES (
    21,
    'Test Student 2',
    'teststudent2@cafeteria.local',
    'TEMP_PASSWORD',
    1,
    'Y'
);

INSERT INTO users (
    user_id,
    full_name,
    email,
    password_hash,
    role_id,
    is_active
)
VALUES (
    22,
    'Demo Staff',
    'staff@cafeteria.local',
    'TEMP_PASSWORD',
    2,
    'Y'
);

INSERT INTO users (
    user_id,
    full_name,
    email,
    password_hash,
    role_id,
    is_active
)
VALUES (
    23,
    'Demo Administrator',
    'admin@cafeteria.local',
    'TEMP_PASSWORD',
    3,
    'Y'
);


-- ============================================================
-- 3. MENU DATES
-- ============================================================

INSERT INTO menu_dates (
    menu_date_id,
    menu_date,
    is_published
)
VALUES (
    1,
    DATE '2026-10-04',
    'Y'
);

INSERT INTO menu_dates (
    menu_date_id,
    menu_date,
    is_published
)
VALUES (
    2,
    DATE '2026-10-05',
    'Y'
);

INSERT INTO menu_dates (
    menu_date_id,
    menu_date,
    is_published
)
VALUES (
    3,
    DATE '2026-10-06',
    'Y'
);


-- ============================================================
-- 4. INGREDIENTS
-- ============================================================

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (1, 'Chicken');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (2, 'Rice');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (3, 'Paneer');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (4, 'Wheat');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (5, 'Potato');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (6, 'Carrot');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (7, 'Onion');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (8, 'Tomato');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (9, 'Capsicum');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (10, 'Egg');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (11, 'Chickpeas');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (12, 'Cauliflower');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (13, 'Peas');

INSERT INTO ingredients (ingredient_id, ingredient_name)
VALUES (14, 'Cabbage');


-- ============================================================
-- 5. MENU ITEMS
-- 04/10/2026
-- ============================================================

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    1,
    1,
    'Chicken Biryani',
    'Fragrant basmati rice with spiced chicken',
    120,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    2,
    1,
    'Veg Fried Rice',
    'Fried rice with mixed vegetables',
    80,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    3,
    1,
    'Paneer Roll',
    'Paneer and vegetables wrapped in wheat flatbread',
    70,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    4,
    1,
    'Masala Dosa',
    'Crispy dosa served with spiced potato filling',
    60,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    5,
    1,
    'Chicken Noodles',
    'Stir-fried noodles with chicken and vegetables',
    110,
    'Y'
);


-- ============================================================
-- 6. MENU ITEMS
-- 05/10/2026
-- ============================================================

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    6,
    2,
    'Chicken Rice',
    'Spiced chicken rice with vegetables',
    110,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    7,
    2,
    'Veg Noodles',
    'Stir-fried noodles with vegetables',
    75,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    8,
    2,
    'Paneer Butter Masala',
    'Paneer cooked in tomato-based gravy',
    100,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    9,
    2,
    'Masala Dosa',
    'Crispy dosa with potato masala',
    60,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    10,
    2,
    'Egg Fried Rice',
    'Fried rice prepared with egg and vegetables',
    90,
    'Y'
);


-- ============================================================
-- 7. MENU ITEMS
-- 06/10/2026
-- ============================================================

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    11,
    3,
    'Chicken Biryani',
    'Fragrant rice with spiced chicken',
    120,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    12,
    3,
    'Veg Pulao',
    'Basmati rice cooked with vegetables',
    85,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    13,
    3,
    'Paneer Fried Rice',
    'Fried rice with paneer and vegetables',
    95,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    14,
    3,
    'Chole Bhatura',
    'Spiced chickpeas served with bhatura',
    90,
    'Y'
);

INSERT INTO menu_items (
    menu_item_id,
    menu_date_id,
    item_name,
    description,
    price,
    is_available
)
VALUES (
    15,
    3,
    'Chicken Wrap',
    'Chicken and vegetables wrapped in wheat flatbread',
    100,
    'Y'
);


-- ============================================================
-- 8. ITEM-INGREDIENT MAPPINGS
-- ============================================================

-- 1 Chicken Biryani
INSERT INTO item_ingredients VALUES (1, 1);
INSERT INTO item_ingredients VALUES (1, 2);
INSERT INTO item_ingredients VALUES (1, 7);

-- 2 Veg Fried Rice
INSERT INTO item_ingredients VALUES (2, 2);
INSERT INTO item_ingredients VALUES (2, 6);
INSERT INTO item_ingredients VALUES (2, 7);
INSERT INTO item_ingredients VALUES (2, 9);

-- 3 Paneer Roll
INSERT INTO item_ingredients VALUES (3, 3);
INSERT INTO item_ingredients VALUES (3, 4);
INSERT INTO item_ingredients VALUES (3, 7);

-- 4 Masala Dosa
INSERT INTO item_ingredients VALUES (4, 2);
INSERT INTO item_ingredients VALUES (4, 5);
INSERT INTO item_ingredients VALUES (4, 7);

-- 5 Chicken Noodles
INSERT INTO item_ingredients VALUES (5, 1);
INSERT INTO item_ingredients VALUES (5, 4);
INSERT INTO item_ingredients VALUES (5, 6);
INSERT INTO item_ingredients VALUES (5, 9);

-- 6 Chicken Rice
INSERT INTO item_ingredients VALUES (6, 1);
INSERT INTO item_ingredients VALUES (6, 2);
INSERT INTO item_ingredients VALUES (6, 6);

-- 7 Veg Noodles
INSERT INTO item_ingredients VALUES (7, 4);
INSERT INTO item_ingredients VALUES (7, 6);
INSERT INTO item_ingredients VALUES (7, 7);
INSERT INTO item_ingredients VALUES (7, 9);

-- 8 Paneer Butter Masala
INSERT INTO item_ingredients VALUES (8, 3);
INSERT INTO item_ingredients VALUES (8, 7);
INSERT INTO item_ingredients VALUES (8, 8);

-- 9 Masala Dosa
INSERT INTO item_ingredients VALUES (9, 2);
INSERT INTO item_ingredients VALUES (9, 5);
INSERT INTO item_ingredients VALUES (9, 7);

-- 10 Egg Fried Rice
INSERT INTO item_ingredients VALUES (10, 2);
INSERT INTO item_ingredients VALUES (10, 6);
INSERT INTO item_ingredients VALUES (10, 7);
INSERT INTO item_ingredients VALUES (10, 10);

-- 11 Chicken Biryani
INSERT INTO item_ingredients VALUES (11, 1);
INSERT INTO item_ingredients VALUES (11, 2);
INSERT INTO item_ingredients VALUES (11, 7);

-- 12 Veg Pulao
INSERT INTO item_ingredients VALUES (12, 2);
INSERT INTO item_ingredients VALUES (12, 6);
INSERT INTO item_ingredients VALUES (12, 7);
INSERT INTO item_ingredients VALUES (12, 13);

-- 13 Paneer Fried Rice
INSERT INTO item_ingredients VALUES (13, 2);
INSERT INTO item_ingredients VALUES (13, 3);
INSERT INTO item_ingredients VALUES (13, 6);
INSERT INTO item_ingredients VALUES (13, 9);

-- 14 Chole Bhatura
INSERT INTO item_ingredients VALUES (14, 4);
INSERT INTO item_ingredients VALUES (14, 7);
INSERT INTO item_ingredients VALUES (14, 8);
INSERT INTO item_ingredients VALUES (14, 11);

-- 15 Chicken Wrap
INSERT INTO item_ingredients VALUES (15, 1);
INSERT INTO item_ingredients VALUES (15, 4);
INSERT INTO item_ingredients VALUES (15, 7);
INSERT INTO item_ingredients VALUES (15, 9);


-- ============================================================
-- 9. STOCK
-- 50 portions initially for every meal
-- ============================================================

INSERT INTO stock VALUES (1, 50);
INSERT INTO stock VALUES (2, 50);
INSERT INTO stock VALUES (3, 50);
INSERT INTO stock VALUES (4, 50);
INSERT INTO stock VALUES (5, 50);
INSERT INTO stock VALUES (6, 50);
INSERT INTO stock VALUES (7, 50);
INSERT INTO stock VALUES (8, 50);
INSERT INTO stock VALUES (9, 50);
INSERT INTO stock VALUES (10, 50);
INSERT INTO stock VALUES (11, 50);
INSERT INTO stock VALUES (12, 50);
INSERT INTO stock VALUES (13, 50);
INSERT INTO stock VALUES (14, 50);
INSERT INTO stock VALUES (15, 50);


-- ============================================================
-- 10. PICKUP WINDOWS
-- 04/10/2026
-- ============================================================

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    1,
    DATE '2026-10-04',
    TO_DATE('12:00', 'HH24:MI'),
    TO_DATE('12:30', 'HH24:MI'),
    20,
    0
);

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    2,
    DATE '2026-10-04',
    TO_DATE('12:30', 'HH24:MI'),
    TO_DATE('13:00', 'HH24:MI'),
    20,
    0
);

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    3,
    DATE '2026-10-04',
    TO_DATE('13:00', 'HH24:MI'),
    TO_DATE('13:30', 'HH24:MI'),
    20,
    0
);


-- ============================================================
-- 11. PICKUP WINDOWS
-- 05/10/2026
-- ============================================================

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    4,
    DATE '2026-10-05',
    TO_DATE('12:00', 'HH24:MI'),
    TO_DATE('12:30', 'HH24:MI'),
    20,
    0
);

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    5,
    DATE '2026-10-05',
    TO_DATE('12:30', 'HH24:MI'),
    TO_DATE('13:00', 'HH24:MI'),
    20,
    0
);

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    6,
    DATE '2026-10-05',
    TO_DATE('13:00', 'HH24:MI'),
    TO_DATE('13:30', 'HH24:MI'),
    20,
    0
);


-- ============================================================
-- 12. PICKUP WINDOWS
-- 06/10/2026
-- ============================================================

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    7,
    DATE '2026-10-06',
    TO_DATE('12:00', 'HH24:MI'),
    TO_DATE('12:30', 'HH24:MI'),
    20,
    0
);

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    8,
    DATE '2026-10-06',
    TO_DATE('12:30', 'HH24:MI'),
    TO_DATE('13:00', 'HH24:MI'),
    20,
    0
);

INSERT INTO pickup_windows (
    pickup_window_id,
    window_date,
    start_time,
    end_time,
    capacity,
    reserved_count
)
VALUES (
    9,
    DATE '2026-10-06',
    TO_DATE('13:00', 'HH24:MI'),
    TO_DATE('13:30', 'HH24:MI'),
    20,
    0
);


-- ============================================================
-- 13. COMMIT
-- ============================================================

COMMIT;

PROMPT
PROMPT ============================================
PROMPT CLEAN DEMO DATA INSERTED
PROMPT ============================================
PROMPT Dates: 04/10/2026 - 06/10/2026
PROMPT Meals: 15
PROMPT Pickup windows: 9
PROMPT Orders: 0
PROMPT ============================================