const Notification = require("../models/Notification");

const getNotifications = async (req, res) => {
  try {
    const { userId, groupId: userGroupId } = req.user;

    const notifications = await Notification.find({
      memberId: userId,
      groupId: userGroupId
    }).sort({ createdAt: -1 }).limit(20).lean();

    res.status(200).json({
      success: true,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed" });
  }
};

const markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    await Notification.updateOne(
      { notificationId, memberId: req.user.userId },
      { $set: { isRead: true } }
    );
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false });
  }
};

module.exports = { getNotifications, markAsRead };
