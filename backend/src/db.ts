import oracledb from "oracledb";
import dotenv from "dotenv";

dotenv.config();

export const pool = await oracledb.createPool({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING
});
