const User = require("../models/User");
const Emi = require("../models/Emi");
const { syncMemberNotifications } = require("./notificationService");

let isRunning = false;

/**
 * Daily Persistent Notification Scheduler
 * Scans all members with unpaid EMIs and triggers daily reminders.
 */
const runDailyEmiReminderScheduler = async () => {
  if (isRunning) return;
  isRunning = true;

  try {
    const startTime = Date.now();
    console.log(`[Notification Scheduler] Starting daily EMI due reminder check at ${new Date().toISOString()}...`);

    // Find all distinct members with unpaid EMIs
    const unpaidMembers = await Emi.distinct("memberId", { status: { $ne: "paid" } });

    let evaluatedCount = 0;

    for (const memberId of unpaidMembers) {
      const user = await User.findOne({ userId: memberId }).select("groupId").lean();
      if (user) {
        await syncMemberNotifications(memberId, user.groupId);
        evaluatedCount++;
      }
    }

    const duration = Date.now() - startTime;
    console.log(`[Notification Scheduler] Daily EMI reminder run completed in ${duration}ms. Evaluated ${evaluatedCount} members.`);
  } catch (error) {
    console.error("[Notification Scheduler] Error running daily EMI reminders:", error.message);
  } finally {
    isRunning = false;
  }
};

/**
 * Initializes the scheduler to run once on server startup and every 24 hours
 */
const startNotificationScheduler = () => {
  console.log("[Notification Scheduler] Initialized daily persistent EMI reminder scheduler.");

  // Run on startup
  setTimeout(() => {
    runDailyEmiReminderScheduler().catch(console.error);
  }, 5000); // 5s after boot

  // Schedule to run every 24 hours (86,400,000 ms)
  const TWENTY_FOUR_HOURS = 24 * 60 * 60 * 1000;
  setInterval(() => {
    runDailyEmiReminderScheduler().catch(console.error);
  }, TWENTY_FOUR_HOURS);
};

module.exports = {
  runDailyEmiReminderScheduler,
  startNotificationScheduler,
};
