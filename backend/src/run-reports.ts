import oracledb from "oracledb";
import dotenv from "dotenv";

dotenv.config();

const connection = await oracledb.getConnection({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING
});

const options = {
  outFormat: oracledb.OUT_FORMAT_OBJECT
};

async function runReport(title: string, sql: string) {
  console.log("\n========================================");
  console.log(title);
  console.log("========================================");

  const result = await connection.execute(sql, [], options);

  console.table(result.rows ?? []);
}

/* 1. ORDER DETAILS */
await runReport(
  "1. ORDER DETAILS",
  `
  SELECT
      o.order_id AS "Order ID",
      u.full_name AS "Student Name",
      o.pickup_code AS "Pickup Code",
      o.order_status AS "Order Status",
      o.total_amount AS "Total Amount",
      o.ordered_at AS "Ordered At",
      pw.start_time AS "Pickup Start",
      pw.end_time AS "Pickup End"
  FROM orders o
  JOIN users u
      ON u.user_id = o.user_id
  JOIN pickup_windows pw
      ON pw.pickup_window_id = o.pickup_window_id
  ORDER BY o.order_id
  `
);

/* 2. ORDER COUNT BY STATUS */
await runReport(
  "2. ORDER COUNT BY STATUS",
  `
  SELECT
      order_status AS "Order Status",
      COUNT(*) AS "Order Count"
  FROM orders
  GROUP BY order_status
  ORDER BY order_status
  `
);

/* 3. REVENUE BY PICKUP WINDOW */
await runReport(
  "3. REVENUE BY PICKUP WINDOW",
  `
  SELECT
      pw.pickup_window_id AS "Pickup Window ID",
      pw.start_time AS "Pickup Start",
      pw.end_time AS "Pickup End",
      COUNT(o.order_id) AS "Order Count",
      NVL(
          SUM(
              CASE
                  WHEN o.order_status <> 'CANCELLED'
                  THEN o.total_amount
                  ELSE 0
              END
          ),
          0
      ) AS "Net Revenue"
  FROM pickup_windows pw
  LEFT JOIN orders o
      ON o.pickup_window_id = pw.pickup_window_id
  GROUP BY
      pw.pickup_window_id,
      pw.start_time,
      pw.end_time
  ORDER BY pw.pickup_window_id
  `
);

/* 4. TOP-SELLING MENU ITEMS */
await runReport(
  "4. TOP-SELLING MENU ITEMS",
  `
  SELECT
      mi.menu_item_id AS "Menu Item ID",
      mi.item_name AS "Menu Item",
      SUM(ol.quantity) AS "Quantity Sold"
  FROM order_lines ol
  JOIN orders o
      ON o.order_id = ol.order_id
  JOIN menu_items mi
      ON mi.menu_item_id = ol.menu_item_id
  WHERE o.order_status <> 'CANCELLED'
  GROUP BY
      mi.menu_item_id,
      mi.item_name
  ORDER BY "Quantity Sold" DESC
  `
);

/* 5. ITEMS ABOVE AVERAGE PRICE */
await runReport(
  "5. ITEMS ABOVE AVERAGE PRICE",
  `
  SELECT
      menu_item_id AS "Menu Item ID",
      item_name AS "Menu Item",
      price AS "Price"
  FROM menu_items
  WHERE price > (
      SELECT AVG(price)
      FROM menu_items
  )
  ORDER BY price DESC
  `
);

/* 6. STUDENTS WITH AT LEAST ONE ORDER */
await runReport(
  "6. STUDENTS WITH AT LEAST ONE ORDER",
  `
  SELECT
      u.user_id AS "User ID",
      u.full_name AS "Student Name",
      u.email AS "Email"
  FROM users u
  JOIN roles r
      ON r.role_id = u.role_id
  WHERE r.role_name = 'STUDENT'
    AND EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.user_id = u.user_id
    )
  ORDER BY u.user_id
  `
);

/* 7. MENU ITEMS WITH INGREDIENTS */
await runReport(
  "7. MENU ITEMS WITH INGREDIENTS",
  `
  SELECT
      mi.item_name AS "Menu Item",
      i.ingredient_name AS "Ingredient"
  FROM menu_items mi
  JOIN item_ingredients ii
      ON ii.menu_item_id = mi.menu_item_id
  JOIN ingredients i
      ON i.ingredient_id = ii.ingredient_id
  ORDER BY
      mi.item_name,
      i.ingredient_name
  `
);

/* 8. STOCK REPORT */
await runReport(
  "8. STOCK REPORT",
  `
  SELECT
      mi.menu_item_id AS "Menu Item ID",
      mi.item_name AS "Menu Item",
      s.available_qty AS "Available Quantity",
      mi.is_available AS "Available"
  FROM stock s
  JOIN menu_items mi
      ON mi.menu_item_id = s.menu_item_id
  ORDER BY s.available_qty ASC, mi.item_name
  `
);

/* 9. PICKUP-WINDOW UTILIZATION */
await runReport(
  "9. PICKUP-WINDOW UTILIZATION",
  `
  SELECT
      pw.pickup_window_id AS "Pickup Window ID",
      pw.start_time AS "Pickup Start",
      pw.end_time AS "Pickup End",
      pw.capacity AS "Capacity",
      pw.reserved_count AS "Reserved",
      pw.capacity - pw.reserved_count AS "Available",
      ROUND(
          (pw.reserved_count / pw.capacity) * 100,
          2
      ) AS "Utilization %"
  FROM pickup_windows pw
  ORDER BY pw.pickup_window_id
  `
);

/* 10. STUDENT ORDER SUMMARY */
await runReport(
  "10. STUDENT ORDER SUMMARY",
  `
  SELECT
      u.user_id AS "User ID",
      u.full_name AS "Student Name",
      COUNT(o.order_id) AS "Total Orders",
      NVL(
          SUM(
              CASE
                  WHEN o.order_status <> 'CANCELLED'
                  THEN o.total_amount
                  ELSE 0
              END
          ),
          0
      ) AS "Net Spending"
  FROM users u
  JOIN roles r
      ON r.role_id = u.role_id
  LEFT JOIN orders o
      ON o.user_id = u.user_id
  WHERE r.role_name = 'STUDENT'
  GROUP BY
      u.user_id,
      u.full_name
  ORDER BY u.user_id
  `
);

await connection.close();