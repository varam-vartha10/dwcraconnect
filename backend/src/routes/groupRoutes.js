const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getGroups,
  createGroup,
  getPendingRegistrations,
  approveRegistration,
} = require("../controllers/groupController");

const {
  getGroupRoster,
  addRosterMember,
  verifyMemberIdentityAndMobile,
  supervisedInPersonActivation,
  bulkImportRoster,
} = require("../controllers/leaderRosterController");

const router = express.Router();

router.get("/", protect, getGroups);
router.post("/", createGroup);

// Leader Registration Approval Routes
router.get("/:groupId/pending-registrations", protect, getPendingRegistrations);
router.post("/:groupId/approve-registration", protect, approveRegistration);

// Leader Member Roster & Assisted Identity Verification Routes
router.get("/:groupId/roster", protect, getGroupRoster);
router.post("/:groupId/roster", protect, addRosterMember);
router.post("/:groupId/roster/bulk", protect, bulkImportRoster);
router.post("/:groupId/members/:userId/verify-identity", protect, verifyMemberIdentityAndMobile);
router.post("/:groupId/members/:userId/supervised-activation", protect, supervisedInPersonActivation);

module.exports = router;
