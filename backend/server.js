const dns = require("node:dns");

// Use public DNS servers for MongoDB SRV lookups (often needed in some environments)
dns.setServers(["8.8.8.8", "1.1.1.1"]);

require("dotenv").config();

const app = require("./src/app");
const connectDatabase = require("./src/config/database");

const PORT = process.env.PORT || 5000;
const NODE_ENV = process.env.NODE_ENV || "development";

const startServer = async () => {
  try {
    // 1. Verify critical environment variables in production
    if (NODE_ENV === "production") {
      if (!process.env.MONGO_URI) {
        throw new Error("MONGO_URI is not defined in environment variables");
      }
      if (!process.env.JWT_SECRET) {
        throw new Error("JWT_SECRET is not defined in environment variables");
      }
    }

    // 2. Connect to Database
    await connectDatabase();

    // 3. Start Express Server
    const server = app.listen(PORT, "0.0.0.0", () => {
      console.log(`DWCRA Connect API running in ${NODE_ENV} mode on port ${PORT}`);
    });

    // 4. Handle unhandled promise rejections
    process.on("unhandledRejection", (err, promise) => {
      console.error(`Error: ${err.message}`);
      // Close server & exit process
      server.close(() => process.exit(1));
    });

  } catch (error) {
    console.error("Failed to start server:", error.message);
    process.exit(1);
  }
};

startServer();
