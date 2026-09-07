const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getEmis,
} = require("../controllers/emiController");

const router = express.Router();

router.get("/", protect, getEmis);

module.exports = router;
