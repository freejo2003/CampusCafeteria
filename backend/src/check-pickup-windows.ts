import dotenv from "dotenv";
import { pool } from "./db.js";

dotenv.config();

async function main() {
  try {
    const result = await pool.query(`
      SELECT
          pickup_window_id,
          TO_CHAR(window_date, 'YYYY-MM-DD') AS window_date,
          TO_CHAR(start_time, 'HH24:MI') AS start_time,
          TO_CHAR(end_time, 'HH24:MI') AS end_time,
          capacity,
          reserved_count
      FROM pickup_windows
      ORDER BY window_date, start_time
    `);

    console.table(result.rows);
  } finally {
    await pool.end();
  }
}

main().catch(console.error);