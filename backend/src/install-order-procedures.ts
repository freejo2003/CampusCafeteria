import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { pool } from "./db.js";

dotenv.config();

const sqlPath = path.resolve(
  process.cwd(),
  "../database/postgresql/03_order_functions.sql"
);

const sql = fs.readFileSync(sqlPath, "utf8");

async function main() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    await client.query(sql);

    await client.query("COMMIT");

    console.log("PostgreSQL order functions created successfully.");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error(error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(console.error);