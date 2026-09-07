const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getTransactions,
  createTransaction,
} = require("../controllers/transactionController");

const router = express.Router();

router.get("/", protect, getTransactions);
router.post("/", protect, createTransaction);

module.exports = router;
