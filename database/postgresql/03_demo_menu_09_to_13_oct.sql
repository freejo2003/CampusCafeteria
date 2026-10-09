-- ============================================================
-- CAMPUS CAFETERIA
-- DEMO MENU DATA
-- 09-Oct-2026 through 13-Oct-2026
--
-- 4 dishes per day
-- 6 pickup windows per day
-- 2 Morning + 2 Noon + 2 Evening
-- 50 portions per dish
-- 20 capacity per pickup window
--
-- PostgreSQL 18
-- ============================================================

BEGIN;

-- ============================================================
-- 1. INGREDIENT MASTER DATA
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
    ('Egg'),
    ('Green Peas'),
    ('Coriander'),
    ('Garlic'),
    ('Ginger'),
    ('Curd'),
    ('Lemon'),
    ('Coconut'),
    ('Lentils'),
    ('Chilli'),
    ('Cumin')
ON CONFLICT (ingredient_name) DO NOTHING;


-- ============================================================
-- 2. MENU DATES
-- ============================================================

INSERT INTO menu_dates (menu_date, is_published)
VALUES
    (DATE '2026-10-09', 'Y'),
    (DATE '2026-10-10', 'Y'),
    (DATE '2026-10-11', 'Y'),
    (DATE '2026-10-12', 'Y'),
    (DATE '2026-10-13', 'Y')
ON CONFLICT (menu_date) DO UPDATE
SET is_published = EXCLUDED.is_published;


-- ============================================================
-- 3. MENU ITEMS
-- ============================================================

-- 09-Oct-2026
INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    md.menu_date_id,
    x.item_name,
    x.description,
    x.price
FROM menu_dates md
CROSS JOIN (
    VALUES
        ('Chicken Biryani',
         'Basmati rice cooked with chicken, onion and aromatic spices',
         120),
        ('Paneer Fried Rice',
         'Fried rice with paneer, vegetables and mild spices',
         100),
        ('Masala Dosa',
         'Crispy dosa served with spiced potato filling',
         70),
        ('Egg Curry Rice',
         'Steamed rice served with egg in tomato and onion curry',
         90)
) AS x(item_name, description, price)
WHERE md.menu_date = DATE '2026-10-09'
  AND NOT EXISTS (
      SELECT 1
      FROM menu_items mi
      WHERE mi.menu_date_id = md.menu_date_id
        AND mi.item_name = x.item_name
  );


-- 10-Oct-2026
INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    md.menu_date_id,
    x.item_name,
    x.description,
    x.price
FROM menu_dates md
CROSS JOIN (
    VALUES
        ('Chicken Rice',
         'Spiced chicken rice with vegetables and herbs',
         110),
        ('Veg Noodles',
         'Stir-fried noodles with vegetables and sauces',
         80),
        ('Aloo Paratha',
         'Wheat flatbread stuffed with seasoned potato',
         65),
        ('Paneer Butter Masala',
         'Paneer cooked in tomato, onion and creamy gravy',
         110)
) AS x(item_name, description, price)
WHERE md.menu_date = DATE '2026-10-10'
  AND NOT EXISTS (
      SELECT 1
      FROM menu_items mi
      WHERE mi.menu_date_id = md.menu_date_id
        AND mi.item_name = x.item_name
  );


-- 11-Oct-2026
INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    md.menu_date_id,
    x.item_name,
    x.description,
    x.price
FROM menu_dates md
CROSS JOIN (
    VALUES
        ('Chicken Meal',
         'Rice, chicken curry, vegetables and dal',
         130),
        ('Veg Pulao',
         'Fragrant rice cooked with mixed vegetables and spices',
         85),
        ('Paneer Roll',
         'Wheat wrap filled with paneer, onion and capsicum',
         75),
        ('Egg Fried Rice',
         'Fried rice with egg, vegetables and mild seasoning',
         95)
) AS x(item_name, description, price)
WHERE md.menu_date = DATE '2026-10-11'
  AND NOT EXISTS (
      SELECT 1
      FROM menu_items mi
      WHERE mi.menu_date_id = md.menu_date_id
        AND mi.item_name = x.item_name
  );


-- 12-Oct-2026
INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    md.menu_date_id,
    x.item_name,
    x.description,
    x.price
FROM menu_dates md
CROSS JOIN (
    VALUES
        ('Chicken Kebab Rice',
         'Grilled chicken pieces served with seasoned rice',
         125),
        ('Dal Rice',
         'Steamed rice served with lentil dal and vegetables',
         70),
        ('Masala Paneer Wrap',
         'Wheat wrap filled with spiced paneer and vegetables',
         85),
        ('Curd Rice',
         'Rice mixed with curd, coriander and mild seasoning',
         55)
) AS x(item_name, description, price)
WHERE md.menu_date = DATE '2026-10-12'
  AND NOT EXISTS (
      SELECT 1
      FROM menu_items mi
      WHERE mi.menu_date_id = md.menu_date_id
        AND mi.item_name = x.item_name
  );


-- 13-Oct-2026
INSERT INTO menu_items
    (menu_date_id, item_name, description, price)
SELECT
    md.menu_date_id,
    x.item_name,
    x.description,
    x.price
FROM menu_dates md
CROSS JOIN (
    VALUES
        ('Chicken Curry Rice',
         'Rice served with chicken curry, onion and tomato',
         120),
        ('Veg Fried Rice',
         'Fried rice with carrot, peas, capsicum and onion',
         80),
        ('Paneer Masala Dosa',
         'Crispy dosa filled with spiced paneer and vegetables',
         90),
        ('Egg Paratha',
         'Wheat paratha prepared with egg, onion and spices',
         85)
) AS x(item_name, description, price)
WHERE md.menu_date = DATE '2026-10-13'
  AND NOT EXISTS (
      SELECT 1
      FROM menu_items mi
      WHERE mi.menu_date_id = md.menu_date_id
        AND mi.item_name = x.item_name
  );


-- ============================================================
-- 4. STOCK
-- 50 PORTIONS PER DISH
-- ============================================================

INSERT INTO stock (menu_item_id, available_qty)
SELECT
    mi.menu_item_id,
    50
FROM menu_items mi
JOIN menu_dates md
    ON md.menu_date_id = mi.menu_date_id
WHERE md.menu_date BETWEEN DATE '2026-10-09' AND DATE '2026-10-13'
  AND NOT EXISTS (
      SELECT 1
      FROM stock s
      WHERE s.menu_item_id = mi.menu_item_id
  );


-- ============================================================
-- 5. ITEM / INGREDIENT MAPPINGS
-- ============================================================

-- ------------------------------------------------------------
-- 09-Oct-2026
-- ------------------------------------------------------------

INSERT INTO item_ingredients (menu_item_id, ingredient_id)
SELECT mi.menu_item_id, i.ingredient_id
FROM menu_items mi
JOIN menu_dates md
    ON md.menu_date_id = mi.menu_date_id
JOIN (
    VALUES
        ('Chicken Biryani', 'Chicken'),
        ('Chicken Biryani', 'Rice'),
        ('Chicken Biryani', 'Onion'),
        ('Chicken Biryani', 'Garlic'),
        ('Chicken Biryani', 'Ginger'),

        ('Paneer Fried Rice', 'Paneer'),
        ('Paneer Fried Rice', 'Rice'),
        ('Paneer Fried Rice', 'Carrot'),
        ('Paneer Fried Rice', 'Capsicum'),
        ('Paneer Fried Rice', 'Onion'),

        ('Masala Dosa', 'Wheat'),
        ('Masala Dosa', 'Potato'),
        ('Masala Dosa', 'Onion'),
        ('Masala Dosa', 'Coconut'),
        ('Masala Dosa', 'Cumin'),

        ('Egg Curry Rice', 'Egg'),
        ('Egg Curry Rice', 'Rice'),
        ('Egg Curry Rice', 'Tomato'),
        ('Egg Curry Rice', 'Onion'),
        ('Egg Curry Rice', 'Garlic')
) AS x(item_name, ingredient_name)
    ON x.item_name = mi.item_name
JOIN ingredients i
    ON i.ingredient_name = x.ingredient_name
WHERE md.menu_date = DATE '2026-10-09'
ON CONFLICT DO NOTHING;


-- ------------------------------------------------------------
-- 10-Oct-2026
-- ------------------------------------------------------------

INSERT INTO item_ingredients (menu_item_id, ingredient_id)
SELECT mi.menu_item_id, i.ingredient_id
FROM menu_items mi
JOIN menu_dates md
    ON md.menu_date_id = mi.menu_date_id
JOIN (
    VALUES
        ('Chicken Rice', 'Chicken'),
        ('Chicken Rice', 'Rice'),
        ('Chicken Rice', 'Carrot'),
        ('Chicken Rice', 'Onion'),
        ('Chicken Rice', 'Garlic'),

        ('Veg Noodles', 'Wheat'),
        ('Veg Noodles', 'Carrot'),
        ('Veg Noodles', 'Capsicum'),
        ('Veg Noodles', 'Onion'),
        ('Veg Noodles', 'Green Peas'),

        ('Aloo Paratha', 'Wheat'),
        ('Aloo Paratha', 'Potato'),
        ('Aloo Paratha', 'Onion'),
        ('Aloo Paratha', 'Coriander'),
        ('Aloo Paratha', 'Cumin'),

        ('Paneer Butter Masala', 'Paneer'),
        ('Paneer Butter Masala', 'Tomato'),
        ('Paneer Butter Masala', 'Onion'),
        ('Paneer Butter Masala', 'Garlic'),
        ('Paneer Butter Masala', 'Ginger')
) AS x(item_name, ingredient_name)
    ON x.item_name = mi.item_name
JOIN ingredients i
    ON i.ingredient_name = x.ingredient_name
WHERE md.menu_date = DATE '2026-10-10'
ON CONFLICT DO NOTHING;


-- ------------------------------------------------------------
-- 11-Oct-2026
-- ------------------------------------------------------------

INSERT INTO item_ingredients (menu_item_id, ingredient_id)
SELECT mi.menu_item_id, i.ingredient_id
FROM menu_items mi
JOIN menu_dates md
    ON md.menu_date_id = mi.menu_date_id
JOIN (
    VALUES
        ('Chicken Meal', 'Chicken'),
        ('Chicken Meal', 'Rice'),
        ('Chicken Meal', 'Potato'),
        ('Chicken Meal', 'Tomato'),
        ('Chicken Meal', 'Lentils'),

        ('Veg Pulao', 'Rice'),
        ('Veg Pulao', 'Carrot'),
        ('Veg Pulao', 'Green Peas'),
        ('Veg Pulao', 'Capsicum'),
        ('Veg Pulao', 'Onion'),

        ('Paneer Roll', 'Paneer'),
        ('Paneer Roll', 'Wheat'),
        ('Paneer Roll', 'Onion'),
        ('Paneer Roll', 'Capsicum'),
        ('Paneer Roll', 'Tomato'),

        ('Egg Fried Rice', 'Egg'),
        ('Egg Fried Rice', 'Rice'),
        ('Egg Fried Rice', 'Carrot'),
        ('Egg Fried Rice', 'Capsicum'),
        ('Egg Fried Rice', 'Onion')
) AS x(item_name, ingredient_name)
    ON x.item_name = mi.item_name
JOIN ingredients i
    ON i.ingredient_name = x.ingredient_name
WHERE md.menu_date = DATE '2026-10-11'
ON CONFLICT DO NOTHING;


-- ------------------------------------------------------------
-- 12-Oct-2026
-- ------------------------------------------------------------

INSERT INTO item_ingredients (menu_item_id, ingredient_id)
SELECT mi.menu_item_id, i.ingredient_id
FROM menu_items mi
JOIN menu_dates md
    ON md.menu_date_id = mi.menu_date_id
JOIN (
    VALUES
        ('Chicken Kebab Rice', 'Chicken'),
        ('Chicken Kebab Rice', 'Rice'),
        ('Chicken Kebab Rice', 'Onion'),
        ('Chicken Kebab Rice', 'Garlic'),
        ('Chicken Kebab Rice', 'Cumin'),

        ('Dal Rice', 'Rice'),
        ('Dal Rice', 'Lentils'),
        ('Dal Rice', 'Tomato'),
        ('Dal Rice', 'Onion'),
        ('Dal Rice', 'Cumin'),

        ('Masala Paneer Wrap', 'Paneer'),
        ('Masala Paneer Wrap', 'Wheat'),
        ('Masala Paneer Wrap', 'Onion'),
        ('Masala Paneer Wrap', 'Capsicum'),
        ('Masala Paneer Wrap', 'Tomato'),

        ('Curd Rice', 'Rice'),
        ('Curd Rice', 'Curd'),
        ('Curd Rice', 'Coriander'),
        ('Curd Rice', 'Ginger'),
        ('Curd Rice', 'Cumin')
) AS x(item_name, ingredient_name)
    ON x.item_name = mi.item_name
JOIN ingredients i
    ON i.ingredient_name = x.ingredient_name
WHERE md.menu_date = DATE '2026-10-12'
ON CONFLICT DO NOTHING;


-- ------------------------------------------------------------
-- 13-Oct-2026
-- ------------------------------------------------------------

INSERT INTO item_ingredients (menu_item_id, ingredient_id)
SELECT mi.menu_item_id, i.ingredient_id
FROM menu_items mi
JOIN menu_dates md
    ON md.menu_date_id = mi.menu_date_id
JOIN (
    VALUES
        ('Chicken Curry Rice', 'Chicken'),
        ('Chicken Curry Rice', 'Rice'),
        ('Chicken Curry Rice', 'Tomato'),
        ('Chicken Curry Rice', 'Onion'),
        ('Chicken Curry Rice', 'Garlic'),

        ('Veg Fried Rice', 'Rice'),
        ('Veg Fried Rice', 'Carrot'),
        ('Veg Fried Rice', 'Green Peas'),
        ('Veg Fried Rice', 'Capsicum'),
        ('Veg Fried Rice', 'Onion'),

        ('Paneer Masala Dosa', 'Paneer'),
        ('Paneer Masala Dosa', 'Wheat'),
        ('Paneer Masala Dosa', 'Potato'),
        ('Paneer Masala Dosa', 'Onion'),
        ('Paneer Masala Dosa', 'Coriander'),

        ('Egg Paratha', 'Egg'),
        ('Egg Paratha', 'Wheat'),
        ('Egg Paratha', 'Onion'),
        ('Egg Paratha', 'Tomato'),
        ('Egg Paratha', 'Cumin')
) AS x(item_name, ingredient_name)
    ON x.item_name = mi.item_name
JOIN ingredients i
    ON i.ingredient_name = x.ingredient_name
WHERE md.menu_date = DATE '2026-10-13'
ON CONFLICT DO NOTHING;


-- ============================================================
-- 6. PICKUP WINDOWS
--
-- Morning:
--   08:00 - 08:30
--   08:30 - 09:00
--
-- Noon:
--   12:00 - 12:30
--   12:30 - 13:00
--
-- Evening:
--   17:00 - 17:30
--   17:30 - 18:00
--
-- Capacity = 20 each
-- ============================================================

INSERT INTO pickup_windows
    (window_date, start_time, end_time, capacity, reserved_count)
SELECT
    d.menu_date,
    d.menu_date + w.start_time::time,
    d.menu_date + w.end_time::time,
    20,
    0
FROM generate_series(
    DATE '2026-10-09',
    DATE '2026-10-13',
    INTERVAL '1 day'
) AS d(menu_date)
CROSS JOIN (
    VALUES
        ('08:00'::time, '08:30'::time),
        ('08:30'::time, '09:00'::time),

        ('12:00'::time, '12:30'::time),
        ('12:30'::time, '13:00'::time),

        ('17:00'::time, '17:30'::time),
        ('17:30'::time, '18:00'::time)
) AS w(start_time, end_time)
WHERE NOT EXISTS (
    SELECT 1
    FROM pickup_windows pw
    WHERE pw.window_date = d.menu_date
      AND pw.start_time::time = w.start_time::time
      AND pw.end_time::time = w.end_time::time
);


COMMIT;


-- ============================================================
-- 7. VERIFICATION
-- ============================================================

SELECT
    md.menu_date,
    COUNT(mi.menu_item_id) AS dishes
FROM menu_dates md
LEFT JOIN menu_items mi
    ON mi.menu_date_id = md.menu_date_id
WHERE md.menu_date BETWEEN DATE '2026-10-09' AND DATE '2026-10-13'
GROUP BY md.menu_date
ORDER BY md.menu_date;


SELECT
    pw.window_date,
    pw.start_time,
    pw.end_time,
    pw.capacity,
    pw.reserved_count
FROM pickup_windows pw
WHERE pw.window_date BETWEEN DATE '2026-10-09' AND DATE '2026-10-13'
ORDER BY pw.window_date, pw.start_time;


SELECT
    md.menu_date,
    mi.item_name,
    mi.price,
    s.available_qty,
    STRING_AGG(i.ingredient_name, ', ' ORDER BY i.ingredient_name)
        AS ingredients
FROM menu_items mi
JOIN menu_dates md
    ON md.menu_date_id = mi.menu_date_id
JOIN stock s
    ON s.menu_item_id = mi.menu_item_id
LEFT JOIN item_ingredients ii
    ON ii.menu_item_id = mi.menu_item_id
LEFT JOIN ingredients i
    ON i.ingredient_id = ii.ingredient_id
WHERE md.menu_date BETWEEN DATE '2026-10-09' AND DATE '2026-10-13'
GROUP BY
    md.menu_date,
    mi.menu_item_id,
    mi.item_name,
    mi.price,
    s.available_qty
ORDER BY md.menu_date, mi.menu_item_id;
