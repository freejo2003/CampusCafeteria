import oracledb from "oracledb";
import dotenv from "dotenv";

dotenv.config();

async function main() {
  const connection = await oracledb.getConnection({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECT_STRING
  });

  try {
    const result = await connection.execute(
      `
      SELECT
          pickup_window_id,
          TO_CHAR(window_date, 'YYYY-MM-DD') AS window_date,
          TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI') AS start_time,
          TO_CHAR(end_time, 'YYYY-MM-DD HH24:MI') AS end_time,
          capacity,
          reserved_count
      FROM pickup_windows
      ORDER BY window_date, start_time
      `,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    console.table(result.rows);
  } finally {
    await connection.close();
  }
}

main().catch(console.error);
