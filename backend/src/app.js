const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

const app = express();

// Trust proxy for deployment behind load balancers (e.g., Render cloud)
app.set("trust proxy", 1);

// Security Headers
app.use(helmet({
  contentSecurityPolicy: false, // Mobile API client compatibility
  crossOriginResourcePolicy: { policy: "cross-origin" },
}));

// CORS Configuration
const corsOptions = {
  origin: process.env.CLIENT_ORIGIN || "*",
  methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
};
app.use(cors(corsOptions));

// Request Body Limits (Prevent memory abuse)
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true, limit: "1mb" }));

// Rate Limiters
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 15 attempts per 15 mins
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many authentication attempts. Please try again in 15 minutes.",
  },
});

const sensitiveLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 60, // 60 sensitive actions (payments/chat) per 15 mins
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many requests. Please slow down.",
  },
});

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many requests from this IP. Please try again later.",
  },
});

// Apply rate limiters to routes
app.use("/api/auth", authLimiter);
app.use("/api/emis/pay", sensitiveLimiter);
app.use("/api/chat", sensitiveLimiter);
app.use("/api", generalLimiter);

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
const accountRoutes = require("./routes/accountRoutes");

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/groups", groupRoutes);
app.use("/api/loans", loanRoutes);
app.use("/api/emis", emiRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/subsidies", subsidyRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/account", accountRoutes);

// Health Check Endpoint
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

// Production-Safe Global Error Handler
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
    message: process.env.NODE_ENV === "production" ? "An internal server error occurred." : message,
  });
});

module.exports = app;
