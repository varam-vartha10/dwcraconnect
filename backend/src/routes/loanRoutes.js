const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getLoans,
  createLoan,
} = require("../controllers/loanController");

const router = express.Router();

router.get("/", protect, getLoans);
router.post("/", protect, createLoan);

module.exports = router;
