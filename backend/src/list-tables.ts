import { pool } from "./db.js";

async function main() {
  try {
    const tableResult = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);

    const tables = tableResult.rows;

    console.log("\n========================================");
    console.log("       ALL CAFETERIA TABLES");
    console.log("========================================");

    for (const row of tables) {
      const tableName = row.table_name;

      console.log(`\n\n========================================`);
      console.log(`TABLE: ${tableName}`);
      console.log(`========================================`);

      const result = await pool.query(
        `SELECT * FROM "${tableName}"`
      );

      console.table(result.rows);
    }

    console.log("\n========================================");
    console.log(`Total tables displayed: ${tables.length}`);
    console.log("========================================\n");
  } catch (error) {
    console.error("Error:", error);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main().catch(console.error);