import oracledb from "oracledb";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const sql = fs.readFileSync(
  "../database/queries/02_views.sql",
  "utf8"
);

const statements = sql
  .split(/;\s*(?:\r?\n|$)/)
  .map(statement => statement.trim())
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
  console.log("Reporting views installed successfully.");
} catch (error) {
  await connection.rollback();
  console.error(error);
  process.exitCode = 1;
} finally {
  await connection.close();
}
