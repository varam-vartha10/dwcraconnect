const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getPersonalAccountSummary,
  getGroupFinancialSummary,
  getGroupMembersFinancialSummary,
} = require("../controllers/accountController");

const router = express.Router();

// Personal account summary for authenticated member
router.get("/summary", protect, getPersonalAccountSummary);

// Group-level financial summary (Leader/Secretary only)
router.get("/groups/:groupId/summary", protect, getGroupFinancialSummary);

// Member-wise financial breakdown (Leader/Secretary only)
router.get("/groups/:groupId/members/summary", protect, getGroupMembersFinancialSummary);

module.exports = router;
