import oracledb from "oracledb";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const files = [
  "../database/plsql/01_order_procedures.sql",
  "../database/plsql/03_status_trigger.sql"
];

const connection = await oracledb.getConnection({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING
});

try {
  for (const file of files) {
    const sql = fs.readFileSync(file, "utf8");

    const statements = sql
      .split(/\n\s*\/\s*(?:\r?\n|$)/)
      .map(statement => statement.trim())
      .filter(Boolean);

    for (const statement of statements) {
      await connection.execute(statement);
    }

    console.log("Installed:", file);
  }

  await connection.commit();
  console.log("Procedures and trigger installed successfully.");
} catch (error) {
  console.error(error);
  await connection.rollback();
  process.exitCode = 1;
} finally {
  await connection.close();
}
