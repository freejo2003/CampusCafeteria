import oracledb from "oracledb";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const sql = fs.readFileSync(
  "../database/plsql/01_order_procedures.sql",
  "utf8"
);

const connection = await oracledb.getConnection({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING
});

try {
  const statements = sql
    .split(/\n\s*\/\s*(?:\r?\n|$)/)
    .map(statement => statement.trim())
    .filter(Boolean);

  for (const statement of statements) {
    await connection.execute(statement);
  }

  await connection.commit();

  console.log("Order procedures created successfully.");
} catch (error) {
  console.error(error);
  await connection.rollback();
  process.exitCode = 1;
} finally {
  await connection.close();
}
