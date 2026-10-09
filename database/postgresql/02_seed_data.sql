-- ============================================================
-- CAMPUS CAFETERIA PREORDER & PICKUP
-- PostgreSQL 18 Seed Data
-- ============================================================

BEGIN;

-- ============================================================
-- ROLES
-- ============================================================

INSERT INTO roles (role_name)
VALUES
    ('STUDENT'),
    ('STAFF'),
    ('ADMIN');

-- ============================================================
-- DEMO USERS
-- Passwords:
-- Student: Student@123
-- Staff:   Staff@123
-- Admin:   Admin@123
-- ============================================================

INSERT INTO users (
    role_id,
    full_name,
    email,
    password_hash
)
SELECT
    role_id,
    'Test Student 2',
    'teststudent2@cafeteria.local',
    '$2b$12$NwMYI6buAXqm.jSyhoA1keMmW8sejyunphKKn9sdPeGSFb75jOBP6'
FROM roles
WHERE role_name = 'STUDENT';

INSERT INTO users (
    role_id,
    full_name,
    email,
    password_hash
)
SELECT
    role_id,
    'Demo Staff',
    'staff@cafeteria.local',
    '$2b$12$J59CLbyFdIZP8eKDGApOje/J/mModaXZR4/6RIRYnQHfJv7opbcLi'
FROM roles
WHERE role_name = 'STAFF';

INSERT INTO users (
    role_id,
    full_name,
    email,
    password_hash
)
SELECT
    role_id,
    'Demo Administrator',
    'admin@cafeteria.local',
    '$2b$12$T6yfRUmS1RrNwx9pDN.IVe.P4MhGgXtVJkn9UDczuiJiuR7RGSx7G'
FROM roles
WHERE role_name = 'ADMIN';

-- ============================================================
-- MENU DATES
-- ============================================================

INSERT INTO menu_dates (menu_date, is_published)
VALUES
    ('2026-10-04', 'Y'),
    ('2026-10-05', 'Y'),
    ('2026-10-06', 'Y');

-- ============================================================
-- MENU ITEMS
-- 5 meals per day = 15 meals
-- ============================================================

-- 2026-10-04

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Chicken Biryani',
    'Basmati rice with chicken and spices',
    120
FROM menu_dates
WHERE menu_date = '2026-10-04';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Veg Fried Rice',
    'Vegetable fried rice with fresh vegetables',
    80
FROM menu_dates
WHERE menu_date = '2026-10-04';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Paneer Roll',
    'Paneer and vegetables wrapped in flatbread',
    70
FROM menu_dates
WHERE menu_date = '2026-10-04';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Masala Dosa',
    'Crispy dosa with potato masala',
    60
FROM menu_dates
WHERE menu_date = '2026-10-04';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Egg Rice',
    'Spiced rice with egg and vegetables',
    90
FROM menu_dates
WHERE menu_date = '2026-10-04';

-- 2026-10-05

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Chicken Rice',
    'Spiced chicken rice with vegetables',
    110
FROM menu_dates
WHERE menu_date = '2026-10-05';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Veg Noodles',
    'Stir-fried noodles with vegetables',
    75
FROM menu_dates
WHERE menu_date = '2026-10-05';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Paneer Butter Masala',
    'Paneer cooked in tomato-based gravy',
    100
FROM menu_dates
WHERE menu_date = '2026-10-05';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Aloo Paratha',
    'Indian flatbread stuffed with potato',
    65
FROM menu_dates
WHERE menu_date = '2026-10-05';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Curd Rice',
    'Rice with curd and mild seasoning',
    55
FROM menu_dates
WHERE menu_date = '2026-10-05';

-- 2026-10-06

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Chicken Meal',
    'Rice, chicken curry and vegetables',
    130
FROM menu_dates
WHERE menu_date = '2026-10-06';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Veg Meal',
    'Rice, vegetable curry and side dish',
    100
FROM menu_dates
WHERE menu_date = '2026-10-06';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Paneer Fried Rice',
    'Fried rice with paneer and vegetables',
    95
FROM menu_dates
WHERE menu_date = '2026-10-06';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Masala Dosa',
    'Crispy dosa with potato masala',
    60
FROM menu_dates
WHERE menu_date = '2026-10-06';

INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    menu_date_id,
    'Veg Sandwich',
    'Grilled sandwich with fresh vegetables',
    70
FROM menu_dates
WHERE menu_date = '2026-10-06';

-- ============================================================
-- INGREDIENTS
-- ============================================================

INSERT INTO ingredients (ingredient_name)
VALUES
    ('Chicken'),
    ('Rice'),
    ('Paneer'),
    ('Wheat'),
    ('Potato'),
    ('Carrot'),
    ('Onion'),
    ('Tomato'),
    ('Capsicum'),
    ('Egg');

-- ============================================================
-- ITEM / INGREDIENT RELATIONSHIPS
-- ============================================================

INSERT INTO item_ingredients (
    menu_item_id,
    ingredient_id
)
SELECT
    m.menu_item_id,
    i.ingredient_id
FROM (
    VALUES
        ('2026-10-04'::date, 'Chicken Biryani', 'Chicken'),
        ('2026-10-04'::date, 'Chicken Biryani', 'Rice'),
        ('2026-10-04'::date, 'Chicken Biryani', 'Onion'),

        ('2026-10-04'::date, 'Veg Fried Rice', 'Rice'),
        ('2026-10-04'::date, 'Veg Fried Rice', 'Carrot'),
        ('2026-10-04'::date, 'Veg Fried Rice', 'Onion'),
        ('2026-10-04'::date, 'Veg Fried Rice', 'Capsicum'),

        ('2026-10-04'::date, 'Paneer Roll', 'Paneer'),
        ('2026-10-04'::date, 'Paneer Roll', 'Wheat'),
        ('2026-10-04'::date, 'Paneer Roll', 'Onion'),

        ('2026-10-04'::date, 'Masala Dosa', 'Rice'),
        ('2026-10-04'::date, 'Masala Dosa', 'Potato'),
        ('2026-10-04'::date, 'Masala Dosa', 'Onion'),

        ('2026-10-04'::date, 'Egg Rice', 'Rice'),
        ('2026-10-04'::date, 'Egg Rice', 'Egg'),
        ('2026-10-04'::date, 'Egg Rice', 'Onion'),

        ('2026-10-05'::date, 'Chicken Rice', 'Chicken'),
        ('2026-10-05'::date, 'Chicken Rice', 'Rice'),
        ('2026-10-05'::date, 'Chicken Rice', 'Carrot'),

        ('2026-10-05'::date, 'Veg Noodles', 'Wheat'),
        ('2026-10-05'::date, 'Veg Noodles', 'Carrot'),
        ('2026-10-05'::date, 'Veg Noodles', 'Onion'),
        ('2026-10-05'::date, 'Veg Noodles', 'Capsicum'),

        ('2026-10-05'::date, 'Paneer Butter Masala', 'Paneer'),
        ('2026-10-05'::date, 'Paneer Butter Masala', 'Tomato'),
        ('2026-10-05'::date, 'Paneer Butter Masala', 'Onion'),

        ('2026-10-05'::date, 'Aloo Paratha', 'Wheat'),
        ('2026-10-05'::date, 'Aloo Paratha', 'Potato'),
        ('2026-10-05'::date, 'Aloo Paratha', 'Onion'),

        ('2026-10-05'::date, 'Curd Rice', 'Rice'),
        ('2026-10-05'::date, 'Curd Rice', 'Onion'),

        ('2026-10-06'::date, 'Chicken Meal', 'Chicken'),
        ('2026-10-06'::date, 'Chicken Meal', 'Rice'),
        ('2026-10-06'::date, 'Chicken Meal', 'Onion'),

        ('2026-10-06'::date, 'Veg Meal', 'Rice'),
        ('2026-10-06'::date, 'Veg Meal', 'Potato'),
        ('2026-10-06'::date, 'Veg Meal', 'Tomato'),

        ('2026-10-06'::date, 'Paneer Fried Rice', 'Rice'),
        ('2026-10-06'::date, 'Paneer Fried Rice', 'Paneer'),
        ('2026-10-06'::date, 'Paneer Fried Rice', 'Capsicum'),

        ('2026-10-06'::date, 'Masala Dosa', 'Rice'),
        ('2026-10-06'::date, 'Masala Dosa', 'Potato'),
        ('2026-10-06'::date, 'Masala Dosa', 'Onion'),

        ('2026-10-06'::date, 'Veg Sandwich', 'Wheat'),
        ('2026-10-06'::date, 'Veg Sandwich', 'Carrot'),
        ('2026-10-06'::date, 'Veg Sandwich', 'Onion'),
        ('2026-10-06'::date, 'Veg Sandwich', 'Capsicum')
) AS x(menu_date, item_name, ingredient_name)
JOIN menu_dates md
    ON md.menu_date = x.menu_date
JOIN menu_items m
    ON m.menu_date_id = md.menu_date_id
   AND m.item_name = x.item_name
JOIN ingredients i
    ON i.ingredient_name = x.ingredient_name;

-- ============================================================
-- STOCK
-- 50 portions per menu item
-- ============================================================

INSERT INTO stock (
    menu_item_id,
    available_qty
)
SELECT
    menu_item_id,
    50
FROM menu_items;

-- ============================================================
-- PICKUP WINDOWS
-- 3 windows/day
-- Capacity = 20 each
-- ============================================================

INSERT INTO pickup_windows
    (window_date, start_time, end_time, capacity, reserved_count)
VALUES
    (
        '2026-10-04',
        '2026-10-04 12:00:00',
        '2026-10-04 12:30:00',
        20,
        0
    ),
    (
        '2026-10-04',
        '2026-10-04 12:30:00',
        '2026-10-04 13:00:00',
        20,
        0
    ),
    (
        '2026-10-04',
        '2026-10-04 13:00:00',
        '2026-10-04 13:30:00',
        20,
        0
    ),
    (
        '2026-10-05',
        '2026-10-05 12:00:00',
        '2026-10-05 12:30:00',
        20,
        0
    ),
    (
        '2026-10-05',
        '2026-10-05 12:30:00',
        '2026-10-05 13:00:00',
        20,
        0
    ),
    (
        '2026-10-05',
        '2026-10-05 13:00:00',
        '2026-10-05 13:30:00',
        20,
        0
    ),
    (
        '2026-10-06',
        '2026-10-06 12:00:00',
        '2026-10-06 12:30:00',
        20,
        0
    ),
    (
        '2026-10-06',
        '2026-10-06 12:30:00',
        '2026-10-06 13:00:00',
        20,
        0
    ),
    (
        '2026-10-06',
        '2026-10-06 13:00:00',
        '2026-10-06 13:30:00',
        20,
        0
    );

COMMIT;