const express = require("express");

const {
  getEmis,
} = require("../controllers/emiController");

const router = express.Router();

router.get("/", getEmis);

module.exports = router;