const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

const userRoutes = require("./routes/userRoutes");
const groupRoutes = require("./routes/groupRoutes");
const loanRoutes = require("./routes/loanRoutes");
const emiRoutes = require("./routes/emiRoutes");
const authRoutes = require("./routes/authRoutes");
const transactionRoutes = require("./routes/transactionRoutes");
const subsidyRoutes = require("./routes/subsidyRoutes");
const notificationRoutes = require("./routes/notificationRoutes");

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/groups", groupRoutes);
app.use("/api/loans", loanRoutes);
app.use("/api/emis", emiRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/subsidies", subsidyRoutes);
app.use("/api/notifications", notificationRoutes);

app.get("/api/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "DWCRA Connect API is running",
  });
});

module.exports = app;
