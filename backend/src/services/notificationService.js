const Notification = require("../models/Notification");
const Emi = require("../models/Emi");

const formatDate = (value) => {
  if (!value) return "";
  try {
    return new Date(value).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  } catch (_) {
    return String(value);
  }
};

// Calculate midnight IST Date for calendar day comparisons
const getISTCalendarDate = (dateObj = new Date()) => {
  const d = new Date(dateObj);
  // Add 5.5 hours for IST
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istDate = new Date(d.getTime() + istOffset);
  return new Date(Date.UTC(istDate.getUTCFullYear(), istDate.getUTCMonth(), istDate.getUTCDate()));
};

/**
 * Idempotent Notification Sync Engine
 * Evaluates real MongoDB Atlas unpaid EMIs against today's date
 * and generates missing reminders with zero duplicate creation.
 */
const syncMemberNotifications = async (memberId, groupId) => {
  try {
    const unpaidEmis = await Emi.find({ memberId, status: { $ne: "paid" } }).lean();
    if (!unpaidEmis || unpaidEmis.length === 0) return;

    const todayIST = getISTCalendarDate(new Date());

    for (const emi of unpaidEmis) {
      if (!emi.dueDate) continue;

      const emiDueIST = getISTCalendarDate(new Date(emi.dueDate));
      const diffMs = emiDueIST.getTime() - todayIST.getTime();
      const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));

      let stage = null;
      let type = "general";
      let title = "";
      let message = "";

      const formattedAmount = (emi.amount || 0).toLocaleString('en-IN');
      const formattedDueDate = formatDate(emi.dueDate);

      if (diffDays === 7) {
        stage = "7_days";
        type = "emi_upcoming";
        title = "Upcoming EMI Reminder (7 Days)";
        message = `Your EMI of ₹${formattedAmount} is due in 7 days on ${formattedDueDate}.`;
      } else if (diffDays === 3) {
        stage = "3_days";
        type = "emi_upcoming";
        title = "Upcoming EMI Reminder (3 Days)";
        message = `Your EMI of ₹${formattedAmount} is due in 3 days on ${formattedDueDate}.`;
      } else if (diffDays === 1) {
        stage = "1_day";
        type = "emi_upcoming";
        title = "EMI Due Tomorrow";
        message = `Your EMI of ₹${formattedAmount} is due tomorrow on ${formattedDueDate}.`;
      } else if (diffDays === 0) {
        stage = "due_today";
        type = "emi_due";
        title = "EMI Due Today";
        message = `Your EMI installment #${emi.installmentNumber || 1} of ₹${formattedAmount} is due today.`;
      } else if (diffDays < 0) {
        stage = "overdue";
        type = "emi_overdue";
        title = "Overdue EMI Warning";
        message = `Your EMI of ₹${formattedAmount} was due on ${formattedDueDate} and is overdue. Please pay as soon as possible.`;
      }

      if (stage) {
        const notificationId = `NOTIF-${memberId}-${emi.emiId}-${stage}`;

        // Uniqueness check to prevent duplicates
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
        }
      }
    }
  } catch (error) {
    console.error("Notification sync error:", error.message);
  }
};

const getMemberNotifications = async (memberId, groupId, limit = 20) => {
  // 1. Sync reminders from real MongoDB EMIs
  await syncMemberNotifications(memberId, groupId);

  // 2. Fetch sorted notifications
  const notifications = await Notification.find({ memberId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();

  return notifications;
};

const createPaymentSuccessNotification = async ({
  memberId,
  groupId,
  emi,
  transactionId,
  amount,
  session = null,
}) => {
  const notificationId = `NOTIF-${memberId}-${emi.emiId}-payment_success-${Date.now()}`;
  const formattedAmount = (amount || emi.amount || 0).toLocaleString('en-IN');

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
};

module.exports = {
  syncMemberNotifications,
  getMemberNotifications,
  createPaymentSuccessNotification,
};
