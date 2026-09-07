const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getSubsidies,
  createSubsidy,
} = require("../controllers/subsidyController");

const router = express.Router();

router.get("/", protect, getSubsidies);
router.post("/", protect, createSubsidy);

module.exports = router;
