const express = require("express");
const rateLimit = require("express-rate-limit");
const { protect } = require("../middleware/auth");
const { sendChatMessage } = require("../controllers/chatController");

const router = express.Router();

const chatLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many chat requests. Please try again in a few minutes.",
  },
});

router.post("/", chatLimiter, protect, sendChatMessage);

module.exports = router;
