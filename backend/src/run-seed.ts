import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { pool } from "./db.js";

dotenv.config();

const sqlPath = path.resolve(
  process.cwd(),
  "../database/postgresql/02_seed_data.sql"
);

const sql = fs.readFileSync(sqlPath, "utf8");

async function main() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    console.log("Executing PostgreSQL seed data...");

    await client.query(sql);

    await client.query("COMMIT");

    console.log("Seed data inserted successfully.");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Seed data insertion failed:");
    console.error(error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(console.error);