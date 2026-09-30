const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getEmis,
  payEmi,
} = require("../controllers/emiController");

const router = express.Router();

router.get("/", protect, getEmis);
router.post("/pay", protect, payEmi);

module.exports = router;
