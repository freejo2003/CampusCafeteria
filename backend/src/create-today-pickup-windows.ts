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
    const windows = [
      ["12:00", "12:30"],
      ["12:30", "13:00"],
      ["13:00", "13:30"]
    ];

    for (const [startTime, endTime] of windows) {
      await connection.execute(
        `
        INSERT INTO pickup_windows (
          window_date,
          start_time,
          end_time,
          capacity,
          reserved_count
        )
        VALUES (
          TO_DATE('2026-10-03', 'YYYY-MM-DD'),
          TO_DATE('2026-10-03 ${startTime}', 'YYYY-MM-DD HH24:MI'),
          TO_DATE('2026-10-03 ${endTime}', 'YYYY-MM-DD HH24:MI'),
          20,
          0
        )
        `
      );
    }

    await connection.commit();

    console.log("Created pickup windows for 2026-10-03.");
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    await connection.close();
  }
}

main().catch(console.error);