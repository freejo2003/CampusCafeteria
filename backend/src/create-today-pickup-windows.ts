import dotenv from "dotenv";
import { pool } from "./db.js";

dotenv.config();

async function main() {
  try {
    const windows = [
      ["12:00", "12:30"],
      ["12:30", "13:00"],
      ["13:00", "13:30"]
    ];

    for (const [startTime, endTime] of windows) {
      await pool.query(
        `
        INSERT INTO pickup_windows (
          window_date,
          start_time,
          end_time,
          capacity,
          reserved_count
        )
        VALUES (
          $1::date,
          $2::time,
          $3::time,
          20,
          0
        )
        `,
        ["2026-10-03", startTime, endTime]
      );
    }

    console.log("Created pickup windows for 2026-10-03.");
  } finally {
    await pool.end();
  }
}

main().catch(console.error);