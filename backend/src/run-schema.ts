import oracledb from "oracledb";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const sql = fs.readFileSync(
  "../database/schema/01_tables.sql",
  "utf8"
);

// Remove SQL single-line comments before splitting statements.
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
    console.log("Executing:", statement.substring(0, 70).replace(/\s+/g, " "));
    await connection.execute(statement);
  }

  await connection.commit();
  console.log("\nSchema created successfully.");
} catch (error) {
  await connection.rollback();
  console.error("\nSchema creation failed:");
  console.error(error);
  process.exitCode = 1;
} finally {
  await connection.close();
}
