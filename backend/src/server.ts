import express from "express";
import cors from "cors";
import { pool } from "./db.js";
import menuRouter from "./routes/menu.js";
import ordersRouter from "./routes/orders.js";
import authRouter from "./routes/auth.js";
import reportsRouter from "./routes/reports.js";
import usersRouter from "./routes/users.js";

const app = express();

app.use(cors());
app.use(express.json());
app.use("/api/reports", reportsRouter);
app.use("/api/auth", authRouter);
app.use("/api/menu", menuRouter);
app.use("/api/orders", ordersRouter);
app.use("/api/users", usersRouter);

app.get("/api/health", async (_req, res) => {
    try {
      const connection = await pool.getConnection();
      await connection.execute("SELECT 1 FROM dual");
      await connection.close();

      res.json({
        status: "ok",
        database: "connected"
      });
    } catch (error) {
      console.error(error);

      res.status(500).json({
        status: "error",
        database: "disconnected"
      });
    }
  }
);

const PORT = 3000;

app.listen(PORT, () => {
  console.log("API running at http://localhost:" + PORT);
});
