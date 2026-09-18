const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const app = express();

// Security Headers
app.use(helmet());

// CORS Configuration
const corsOptions = {
  origin: process.env.CLIENT_ORIGIN || "*", // In production, replace * with your app domain if needed
  methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
};
app.use(cors(corsOptions));

app.use(express.json());

// Routes
const userRoutes = require("./routes/userRoutes");
const groupRoutes = require("./routes/groupRoutes");
const loanRoutes = require("./routes/loanRoutes");
const emiRoutes = require("./routes/emiRoutes");
const authRoutes = require("./routes/authRoutes");
const transactionRoutes = require("./routes/transactionRoutes");
const subsidyRoutes = require("./routes/subsidyRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const chatRoutes = require("./routes/chatRoutes");

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/groups", groupRoutes);
app.use("/api/loans", loanRoutes);
app.use("/api/emis", emiRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/subsidies", subsidyRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/chat", chatRoutes);

// Health Check
app.get("/api/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "DWCRA Connect API is running",
    environment: process.env.NODE_ENV || "development",
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

// Global Error Handler
app.use((error, req, res, next) => {
  if (error instanceof SyntaxError && "body" in error) {
    return res.status(400).json({
      success: false,
      message: "Invalid JSON request body.",
    });
  }

  const statusCode = error.statusCode || 500;
  const message = error.message || "An internal server error occurred.";

  if (process.env.NODE_ENV !== "production") {
    console.error(`[Error] ${statusCode} - ${message}`);
    console.error(error.stack);
  }

  res.status(statusCode).json({
    success: false,
    message: process.env.NODE_ENV === "production" ? "Internal server error" : message,
    // stack: process.env.NODE_ENV === "production" ? null : error.stack,
  });
});

module.exports = app;
