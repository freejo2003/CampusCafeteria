import { pool } from "./db.js";

const connection = await pool.getConnection();

try {
  const tableResult = await connection.execute<[string]>(
    `
    SELECT table_name
    FROM user_tables
    ORDER BY table_name
    `
  );

  const tables = tableResult.rows ?? [];

  console.log("\n========================================");
  console.log("       ALL CAFETERIA_APP TABLES");
  console.log("========================================");

  for (const row of tables) {
    const tableName = row[0];

    console.log(`\n\n========================================`);
    console.log(`TABLE: ${tableName}`);
    console.log(`========================================`);

    const result = await connection.execute(
      `SELECT * FROM "${tableName}"`
    );

    console.table(result.rows ?? []);
  }

  console.log("\n========================================");
  console.log(`Total tables displayed: ${tables.length}`);
  console.log("========================================\n");

} catch (error) {
  console.error("Error:", error);
} finally {
  await connection.close();
  await pool.close();
}