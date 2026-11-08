const Notification = require("../models/Notification");
const Emi = require("../models/Emi");
const User = require("../models/User");
const { sendPushNotification } = require("./pushNotificationService");

const formatDate = (value) => {
  if (!value) return "";
  try {
    return new Date(value).toLocaleDateString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  } catch (_) {
    return String(value);
  }
};

/**
 * Calculate midnight IST Date for calendar day comparisons (Asia/Kolkata UTC+5:30)
 */
const getISTCalendarDate = (dateObj = new Date()) => {
  const d = new Date(dateObj);
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istDate = new Date(d.getTime() + istOffset);
  return new Date(Date.UTC(istDate.getUTCFullYear(), istDate.getUTCMonth(), istDate.getUTCDate()));
};

/**
 * Format IST Date string (YYYY-MM-DD)
 */
const getISTDateString = (dateObj = new Date()) => {
  const istDate = getISTCalendarDate(dateObj);
  return istDate.toISOString().split("T")[0];
};

/**
 * 10-Day Daily EMI Notification Sync Engine
 * Evaluates real MongoDB Atlas unpaid EMIs against today's IST calendar date.
 * Starts reminders 10 days before due date, sends 1 reminder daily, and
 * STOPS IMMEDIATELY once payment is confirmed (status === 'paid').
 */
const syncMemberNotifications = async (memberId, groupId) => {
  try {
    // Query ONLY unpaid EMIs (status !== 'paid'). Paid EMIs stop reminders immediately!
    const unpaidEmis = await Emi.find({ memberId, status: { $ne: "paid" } }).lean();
    if (!unpaidEmis || unpaidEmis.length === 0) return;

    const todayIST = getISTCalendarDate(new Date());
    const dateStr = getISTDateString(new Date());

    const user = await User.findOne({ userId: memberId }).select("deviceToken fcmToken").lean();
    const deviceToken = user?.deviceToken || user?.fcmToken;

    for (const emi of unpaidEmis) {
      if (!emi.dueDate) continue;

      // Re-verify EMI status directly from database to prevent race conditions
      const freshEmi = await Emi.findOne({ emiId: emi.emiId }).select("status").lean();
      if (!freshEmi || freshEmi.status === "paid") continue;

      const emiDueIST = getISTCalendarDate(new Date(emi.dueDate));
      const diffMs = emiDueIST.getTime() - todayIST.getTime();
      const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));

      // Reminders start 10 days before due date (diffDays <= 10)
      if (diffDays > 10) continue;

      let stage = null;
      let type = "emi_reminder";
      let title = "";
      let message = "";

      const formattedAmount = (emi.amount || 0).toLocaleString("en-IN");
      const formattedDueDate = formatDate(emi.dueDate);

      if (diffDays > 0) {
        // 10 days before due date down to 1 day before due date
        stage = `daily_reminder_due_in_${diffDays}d_${dateStr}`;
        type = "emi_upcoming";
        title = "EMI Payment Reminder";
        message = `Your EMI of ₹${formattedAmount} is due on ${formattedDueDate}. Please check your EMI details in DWCRA Connect.`;
      } else if (diffDays === 0) {
        // On due date
        stage = `due_today_${dateStr}`;
        type = "emi_due";
        title = "EMI Due Today";
        message = `Your EMI of ₹${formattedAmount} is due today. Open DWCRA Connect to check your payment details.`;
      } else {
        // Past due date / Overdue
        stage = `overdue_daily_${dateStr}`;
        type = "emi_overdue";
        title = "EMI Overdue Reminder";
        message = `Your EMI of ₹${formattedAmount} was due on ${formattedDueDate} and is still marked unpaid. Please check your EMI details.`;
      }

      if (stage) {
        // Daily Idempotent Notification Key: Unique per member, EMI, and calendar day
        const notificationId = `NOTIF-${memberId}-${emi.emiId}-${dateStr}`;

        // Uniqueness check to prevent duplicate reminders on the same day
        const existing = await Notification.findOne({ notificationId }).lean();
        if (!existing) {
          await Notification.create({
            notificationId,
            memberId,
            groupId: emi.groupId || groupId,
            title,
            message,
            type,
            stage,
            isRead: false,
            relatedId: emi.emiId,
          });

          // Dispatch Push Notification to Member Device
          if (deviceToken) {
            await sendPushNotification({
              deviceToken,
              title,
              message,
              dataPayload: {
                emiId: emi.emiId,
                loanId: emi.loanId || "",
                type,
              },
            });
          }
        }
      }
    }
  } catch (error) {
    console.error("Notification sync error:", error.message);
  }
};

/**
 * Syncs and returns sorted member notifications
 */
const getMemberNotifications = async (memberId, groupId, limit = 20) => {
  await syncMemberNotifications(memberId, groupId);

  const notifications = await Notification.find({ memberId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();

  return notifications;
};

/**
 * Immediate Payment Success Receipt & Reminder Invalidation
 */
const createPaymentSuccessNotification = async ({
  memberId,
  groupId,
  emi,
  transactionId,
  amount,
  session = null,
}) => {
  const notificationId = `NOTIF-${memberId}-${emi.emiId}-payment_success-${Date.now()}`;
  const formattedAmount = (amount || emi.amount || 0).toLocaleString("en-IN");

  const payload = {
    notificationId,
    memberId,
    groupId: emi.groupId || groupId,
    title: "EMI Payment Successful",
    message: `EMI installment #${emi.installmentNumber || 1} payment of ₹${formattedAmount} was successfully confirmed. Transaction ID: ${transactionId}.`,
    type: "payment_success",
    stage: "payment_success",
    isRead: false,
    relatedId: transactionId,
  };

  if (session) {
    await Notification.create([payload], { session });
  } else {
    await Notification.create(payload);
  }

  // Push notification for payment success
  try {
    const user = await User.findOne({ userId: memberId }).select("deviceToken fcmToken").lean();
    const deviceToken = user?.deviceToken || user?.fcmToken;
    if (deviceToken) {
      await sendPushNotification({
        deviceToken,
        title: "EMI Payment Successful",
        message: payload.message,
        dataPayload: {
          transactionId,
          emiId: emi.emiId,
          type: "payment_success",
        },
      });
    }
  } catch (_) {}
};

module.exports = {
  syncMemberNotifications,
  getMemberNotifications,
  createPaymentSuccessNotification,
};
