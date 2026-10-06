import bcrypt from "bcryptjs";
import oracledb from "oracledb";
import dotenv from "dotenv";

dotenv.config();

async function resetPassword() {
  const connection = await oracledb.getConnection({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECT_STRING,
  });

  try {
    const passwordHash = await bcrypt.hash("Student@123", 10);

    const result = await connection.execute(
      `UPDATE users
       SET password_hash = :passwordHash
       WHERE email = :email`,
      {
        passwordHash,
        email: "teststudent2@cafeteria.local",
      }
    );

    await connection.commit();

    console.log("Rows updated:", result.rowsAffected);
    console.log("Password reset to: Student@123");
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    await connection.close();
  }
}

resetPassword().catch((error) => {
  console.error(error);
  process.exit(1);
});
