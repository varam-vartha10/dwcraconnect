const express = require("express");

const {
  getLoans,
  createLoan,
} = require("../controllers/loanController");

const router = express.Router();

router.get("/", getLoans);

router.post("/", createLoan);

module.exports = router;