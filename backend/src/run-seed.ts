import oracledb from "oracledb";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const sql = fs.readFileSync("../database/seed/01_seed_data.sql", "utf8");

const cleanedSql = sql
  .split(/\r?\n/)
  .filter(line => !line.trim().startsWith("--"))
  .join("\n");

const statements = cleanedSql
  .split(";")
  .map(s => s.trim())
  .filter(Boolean);

const connection = await oracledb.getConnection({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING
});

try {
  for (const statement of statements) {
    await connection.execute(statement);
  }

  await connection.commit();
  console.log("Seed data inserted successfully.");
} catch (error) {
  await connection.rollback();
  console.error(error);
  process.exitCode = 1;
} finally {
  await connection.close();
}
