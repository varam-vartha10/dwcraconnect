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

app.use("/api/loans", loanRoutes);
app.use("/api/users", userRoutes);
app.use("/api/groups", groupRoutes);
app.use("/api/emis", emiRoutes);

app.get("/api/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "DWCRA Connect API is running",
  });
});

module.exports = app;