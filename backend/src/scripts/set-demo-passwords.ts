import bcrypt from "bcryptjs";
import { pool } from "../db.js";

const connection = await pool.getConnection();

try {
  const staffPasswordHash = await bcrypt.hash("Staff@123", 12);
  const adminPasswordHash = await bcrypt.hash("Admin@123", 12);
  const studentPasswordHash = await bcrypt.hash("Student@123", 12);

  const staffResult = await connection.execute(
    `
    UPDATE users
    SET password_hash = :password_hash
    WHERE email = 'staff@cafeteria.local'
    `,
    {
      password_hash: staffPasswordHash
    }
  );

  const adminResult = await connection.execute(
    `
    UPDATE users
    SET password_hash = :password_hash
    WHERE email = 'admin@cafeteria.local'
    `,
    {
      password_hash: adminPasswordHash
    }
  );

  const studentResult = await connection.execute(
    `
    UPDATE users
    SET password_hash = :password_hash
    WHERE email = 'teststudent2@cafeteria.local'
    `,
    {
      password_hash: studentPasswordHash
    }
  );

  await connection.commit();

  console.log(
    `STAFF password updated: ${staffResult.rowsAffected ?? 0} row(s)`
  );

  console.log(
    `ADMIN password updated: ${adminResult.rowsAffected ?? 0} row(s)`
  );

  console.log(
    `STUDENT password updated: ${studentResult.rowsAffected ?? 0} row(s)`
  );

  console.log("");
  console.log("Demo credentials:");
  console.log("STAFF   staff@cafeteria.local       Staff@123");
  console.log("ADMIN   admin@cafeteria.local       Admin@123");
  console.log("STUDENT teststudent2@cafeteria.local Student@123");

} catch (error) {
  await connection.rollback();
  console.error(error);
  process.exitCode = 1;
} finally {
  await connection.close();
  await pool.close();
}