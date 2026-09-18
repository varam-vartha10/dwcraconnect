const OpenAI = require("openai");
const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");

const ACTIVE_LOAN_STATUSES = ["pending", "active", "overdue", "completed"];
const GROUP_LEADER_POSITIONS = new Set(["president", "secretary"]);

class ChatServiceError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.name = "ChatServiceError";
    this.statusCode = statusCode;
  }
}

const formatDate = (value) => (value ? new Date(value).toISOString().slice(0, 10) : null);
const roundAmount = (value) => Math.round((Number(value) || 0) * 100) / 100;

const detectLanguage = (message) => {
  const hasTelugu = /[\u0C00-\u0C7F]/.test(message);
  const hasLatin = /[A-Za-z]/.test(message);

  if (hasTelugu && hasLatin) return "te-en";
  if (hasTelugu) return "te";
  return "en";
};

const hasAny = (message, expressions) => expressions.some((expression) => expression.test(message));

const detectIntent = (message) => {
  const text = message.toLowerCase();
  const isGeneralQuestion = hasAny(text, [
    /\bwhat is (an? )?emi\b/,
    /\bwhat is (a )?(subsidy|shg)\b/,
    /\bhow does loan repayment work\b/,
    /\bexplain (an? )?emi\b/,
    /ఎమి అంటే ఏమిటి/,
    /సబ్సిడీ అంటే ఏమిటి/,
    /ఎస్ హెచ్ జి అంటే ఏమిటి/,
  ]);

  if (isGeneralQuestion) return { scope: "general", data: [] };

  if (hasAny(text, [
    /\bmy (group|member) id\b/,
    /నా (గ్రూప్|మెంబర్) ఐడి/,
  ])) {
    return { scope: "personal", data: ["myProfile"] };
  }

  const groupQuestion = hasAny(text, [
    /\b(our|my) group\b/,
    /\bgroup (members?|loans?|emis?|transactions?|subsid(?:y|ies)|ledger|summary)\b/,
    /\bmembers? in (our|the) group\b/,
    /\bhow many members\b/,
    /\bgroup'?s?\b/,
    /మన గ్రూప్/,
    /గ్రూప్ (మెంబర్స్|లోన్స్|లోన్|ఈఎంఐ|ట్రాన్సాక్షన్స్|సబ్సిడీ|లెడ్జర్|సమ్మరీ)/,
  ]);

  const wantsLoan = hasAny(text, [/\bloan\b/, /లోన్/]);
  const wantsBalance = hasAny(text, [
    /\b(balance|remaining|paid so far|how much.*paid|inka|entha)\b/,
    /బ్యాలెన్స్/,
    /మిగిలి/,
    /ఎంత ఉంది/,
  ]);
  const wantsEmi = hasAny(text, [/\bemi\b/, /\binstallment\b/, /ఈఎంఐ/, /కిస్తీ/]);
  const wantsNext = hasAny(text, [/\b(next|when|due|pending)\b/, /తదుపరి/, /ఎప్పుడు/, /డ్యూ/, /పెండింగ్/]);
  const wantsTransactions = hasAny(text, [/\b(transaction|payment|recent activity)\b/, /ట్రాన్సాక్ష/, /చెల్లింప/]);
  const wantsSubsidy = hasAny(text, [/\bsubsid(y|ies)\b/, /సబ్సిడీ/]);
  const wantsNotifications = hasAny(text, [/\b(notification|alert|reminder)\b/, /నోటిఫికేషన్/, /రిమైండర్/]);
  const wantsSavings = hasAny(text, [/\b(savings?|saved)\b/, /పొదుపు/, /సేవింగ్స్/]);
  const wantsProfile = hasAny(text, [/\b(profile|member id|group id|my details)\b/, /ప్రొఫైల్/, /మెంబర్ ఐడి/, /గ్రూప్ ఐడి/]);

  if (groupQuestion) {
    const data = [];
    if (wantsLoan || wantsBalance) data.push("groupLoanSummary");
    if (wantsEmi) data.push("groupEmiSummary");
    if (wantsTransactions) data.push("groupTransactions");
    if (wantsSubsidy) data.push("groupSubsidySummary");
    if (wantsSavings || /\bledger\b/.test(text) || /లెడ్జర్/.test(text)) data.push("groupLedger");
    if (/\b(member|members|how many)\b/.test(text) || /మెంబర్/.test(text)) data.push("groupMembers");
    return { scope: "group", data: data.length ? data : ["groupMembers"] };
  }

  const data = [];
  if ((wantsLoan && wantsBalance) || /\b(paid so far|how much.*paid)\b/.test(text)) {
    data.push("myLoanBalance");
  }
  else if (wantsLoan) data.push("myLoanDetails");
  if (wantsEmi && wantsNext) data.push("myNextEmi");
  else if (wantsEmi) data.push("myEmiDetails");
  if (wantsTransactions) data.push("myTransactions");
  if (wantsSubsidy) data.push("mySubsidies");
  if (wantsNotifications) data.push("myNotifications");
  if (wantsSavings) data.push("mySavings");
  if (wantsProfile) data.push("myProfile");

  return { scope: data.length ? "personal" : "general", data };
};

const refersToAnotherMember = async (message, user) => {
  const text = message.toLowerCase();
  if (hasAny(text, [
    /\b(another|other) member\b/,
    /\bsomeone else'?s?\b/,
    /\b[a-z][a-z]+(?:'s|’s)\b/,
    /వేరే మెంబర్/,
    /ఇతర సభ్య/,
  ])) {
    return true;
  }

  const groupMembers = await User.find({
    groupId: user.groupId,
    userId: { $ne: user.userId },
    isActive: true,
  })
    .select("name")
    .lean();

  return groupMembers.some((member) => {
    const name = member.name && member.name.trim().toLowerCase();
    return name && text.includes(name);
  });
};

const getAuthenticatedUser = async (authenticatedUser) => {
  const user = await User.findById(authenticatedUser.id)
    .select("userId groupId name role position village isActive")
    .lean();

  if (!user || !user.isActive) {
    throw new ChatServiceError(401, "Your account is not authorized to use the AI assistant.");
  }

  if (user.userId !== authenticatedUser.userId || user.groupId !== authenticatedUser.groupId) {
    throw new ChatServiceError(401, "Your authentication details are no longer valid. Please sign in again.");
  }

  return user;
};

const getMyProfile = async (user) => ({
  name: user.name,
  userId: user.userId,
  groupId: user.groupId,
  role: user.role,
  position: user.position,
  village: user.village || null,
});

const getLoanPaymentMap = async (user, loanIds) => {
  if (!loanIds.length) return new Map();

  const payments = await Transaction.aggregate([
    {
      $match: {
        groupId: user.groupId,
        memberId: user.userId,
        loanId: { $in: loanIds },
        type: "loan_payment",
        status: "completed",
      },
    },
    { $group: { _id: "$loanId", amountPaid: { $sum: "$amount" } } },
  ]);

  return new Map(payments.map((payment) => [payment._id, roundAmount(payment.amountPaid)]));
};

const getMemberLoansWithBalances = async (user) => {
  const loans = await Loan.find({
    groupId: user.groupId,
    memberId: user.userId,
    status: { $in: ACTIVE_LOAN_STATUSES },
  })
    .select("loanId loanType purpose principalAmount interestRate tenureMonths startDate status")
    .sort({ startDate: -1 })
    .lean();

  const paymentsByLoan = await getLoanPaymentMap(user, loans.map((loan) => loan.loanId));

  return loans.map((loan) => {
    const amountPaid = paymentsByLoan.get(loan.loanId) || 0;
    return {
      loanType: loan.loanType,
      purpose: loan.purpose,
      principalAmount: roundAmount(loan.principalAmount),
      interestRate: loan.interestRate,
      tenureMonths: loan.tenureMonths,
      startDate: formatDate(loan.startDate),
      status: loan.status,
      amountPaid,
      remainingAmount: roundAmount(Math.max(0, loan.principalAmount - amountPaid)),
    };
  });
};

const getMyLoanBalance = async (user) => {
  const loans = await getMemberLoansWithBalances(user);
  return {
    calculationBasis: "Loan principal less completed loan-payment transactions linked to each loan.",
    loanCount: loans.length,
    totalPrincipalAmount: roundAmount(loans.reduce((total, loan) => total + loan.principalAmount, 0)),
    totalAmountPaid: roundAmount(loans.reduce((total, loan) => total + loan.amountPaid, 0)),
    totalRemainingAmount: roundAmount(loans.reduce((total, loan) => total + loan.remainingAmount, 0)),
  };
};

const getMyLoanDetails = async (user) => ({ loans: await getMemberLoansWithBalances(user) });

const getMyNextEmi = async (user) => {
  const emi = await Emi.findOne({
    groupId: user.groupId,
    memberId: user.userId,
    status: { $in: ["pending", "overdue"] },
  })
    .select("installmentNumber amount dueDate status")
    .sort({ dueDate: 1 })
    .lean();

  if (!emi) return { nextEmi: null };
  return {
    nextEmi: {
      installmentNumber: emi.installmentNumber,
      amount: roundAmount(emi.amount),
      dueDate: formatDate(emi.dueDate),
      status: emi.status,
    },
  };
};

const getMyEmiDetails = async (user) => {
  const emis = await Emi.find({ groupId: user.groupId, memberId: user.userId })
    .select("installmentNumber amount dueDate status paidDate")
    .sort({ dueDate: 1 })
    .limit(12)
    .lean();

  return {
    emis: emis.map((emi) => ({
      installmentNumber: emi.installmentNumber,
      amount: roundAmount(emi.amount),
      dueDate: formatDate(emi.dueDate),
      status: emi.status,
      paidDate: formatDate(emi.paidDate),
    })),
  };
};

const getMyTransactions = async (user) => {
  const transactions = await Transaction.find({ groupId: user.groupId, memberId: user.userId })
    .select("amount type status paymentDate")
    .sort({ paymentDate: -1 })
    .limit(10)
    .lean();

  return {
    transactions: transactions.map((transaction) => ({
      amount: roundAmount(transaction.amount),
      type: transaction.type,
      status: transaction.status,
      paymentDate: formatDate(transaction.paymentDate),
    })),
  };
};

const getMySubsidies = async (user) => {
  const subsidies = await Subsidy.find({ groupId: user.groupId, memberId: user.userId })
    .select("schemeName amount status dateReceived")
    .sort({ createdAt: -1 })
    .limit(10)
    .lean();

  return {
    subsidies: subsidies.map((subsidy) => ({
      schemeName: subsidy.schemeName,
      amount: roundAmount(subsidy.amount),
      status: subsidy.status,
      dateReceived: formatDate(subsidy.dateReceived),
    })),
  };
};

const getMyNotifications = async (user) => {
  const notifications = await Notification.find({ groupId: user.groupId, memberId: user.userId })
    .select("title message type isRead createdAt")
    .sort({ createdAt: -1 })
    .limit(10)
    .lean();

  return {
    notifications: notifications.map((notification) => ({
      title: notification.title,
      message: notification.message,
      type: notification.type,
      isRead: notification.isRead,
      createdAt: formatDate(notification.createdAt),
    })),
  };
};

const getMySavings = async (user) => {
  const totals = await Transaction.aggregate([
    {
      $match: {
        groupId: user.groupId,
        memberId: user.userId,
        status: "completed",
        type: { $in: ["savings_deposit", "savings_withdrawal"] },
      },
    },
    { $group: { _id: "$type", amount: { $sum: "$amount" } } },
  ]);

  const amounts = new Map(totals.map((total) => [total._id, roundAmount(total.amount)]));
  const deposits = amounts.get("savings_deposit") || 0;
  const withdrawals = amounts.get("savings_withdrawal") || 0;

  return {
    calculationBasis: "Completed savings deposits less completed savings withdrawals.",
    totalDeposits: deposits,
    totalWithdrawals: withdrawals,
    currentSavings: roundAmount(deposits - withdrawals),
  };
};

const assertGroupLeader = (user) => {
  if (user.role !== "leader" || !GROUP_LEADER_POSITIONS.has(user.position)) {
    throw new ChatServiceError(
      403,
      "Group information is available only to the president or secretary of the group."
    );
  }
};

const getGroupMembers = async (user) => {
  const members = await User.find({ groupId: user.groupId, isActive: true })
    .select("userId name position village")
    .sort({ name: 1 })
    .lean();

  return {
    memberCount: members.length,
    members: members.map((member) => ({
      userId: member.userId,
      name: member.name,
      position: member.position,
      village: member.village || null,
    })),
  };
};

const getGroupLoanSummary = async (user) => {
  const loans = await Loan.find({
    groupId: user.groupId,
    status: { $in: ACTIVE_LOAN_STATUSES },
  })
    .select("loanId principalAmount status")
    .lean();
  const loanIds = loans.map((loan) => loan.loanId);
  const payments = loanIds.length
    ? await Transaction.aggregate([
        {
          $match: {
            groupId: user.groupId,
            loanId: { $in: loanIds },
            type: "loan_payment",
            status: "completed",
          },
        },
        { $group: { _id: "$loanId", amountPaid: { $sum: "$amount" } } },
      ])
    : [];
  const paymentsByLoan = new Map(payments.map((payment) => [payment._id, roundAmount(payment.amountPaid)]));
  const totalPrincipalAmount = loans.reduce((total, loan) => total + loan.principalAmount, 0);
  const totalAmountPaid = loans.reduce(
    (total, loan) => total + (paymentsByLoan.get(loan.loanId) || 0),
    0
  );
  const totalRemainingAmount = loans.reduce(
    (total, loan) => total + Math.max(0, loan.principalAmount - (paymentsByLoan.get(loan.loanId) || 0)),
    0
  );

  return {
    calculationBasis: "Loan principal less completed loan-payment transactions linked to each loan.",
    loanCount: loans.length,
    totalPrincipalAmount: roundAmount(totalPrincipalAmount),
    totalAmountPaid: roundAmount(totalAmountPaid),
    totalRemainingAmount: roundAmount(totalRemainingAmount),
    statusCounts: loans.reduce((counts, loan) => {
      counts[loan.status] = (counts[loan.status] || 0) + 1;
      return counts;
    }, {}),
  };
};

const getGroupEmiSummary = async (user) => {
  const summary = await Emi.aggregate([
    { $match: { groupId: user.groupId } },
    { $group: { _id: "$status", count: { $sum: 1 }, totalAmount: { $sum: "$amount" } } },
  ]);
  const nextDue = await Emi.findOne({
    groupId: user.groupId,
    status: { $in: ["pending", "overdue"] },
  })
    .select("amount dueDate status")
    .sort({ dueDate: 1 })
    .lean();

  return {
    statusSummary: summary.map((item) => ({
      status: item._id,
      count: item.count,
      totalAmount: roundAmount(item.totalAmount),
    })),
    nextDueEmi: nextDue
      ? { amount: roundAmount(nextDue.amount), dueDate: formatDate(nextDue.dueDate), status: nextDue.status }
      : null,
  };
};

const getGroupTransactions = async (user) => {
  const transactions = await Transaction.find({ groupId: user.groupId })
    .select("amount type status paymentDate")
    .sort({ paymentDate: -1 })
    .limit(10)
    .lean();

  return {
    transactions: transactions.map((transaction) => ({
      amount: roundAmount(transaction.amount),
      type: transaction.type,
      status: transaction.status,
      paymentDate: formatDate(transaction.paymentDate),
    })),
  };
};

const getGroupSubsidySummary = async (user) => {
  const summary = await Subsidy.aggregate([
    { $match: { groupId: user.groupId } },
    { $group: { _id: "$status", count: { $sum: 1 }, totalAmount: { $sum: "$amount" } } },
  ]);

  return {
    statusSummary: summary.map((item) => ({
      status: item._id,
      count: item.count,
      totalAmount: roundAmount(item.totalAmount),
    })),
  };
};

const getGroupLedger = async (user) => {
  const summary = await Transaction.aggregate([
    { $match: { groupId: user.groupId, status: "completed" } },
    { $group: { _id: "$type", count: { $sum: 1 }, totalAmount: { $sum: "$amount" } } },
  ]);

  return {
    completedTransactionSummary: summary.map((item) => ({
      type: item._id,
      count: item.count,
      totalAmount: roundAmount(item.totalAmount),
    })),
  };
};

const dataFunctions = {
  myProfile: getMyProfile,
  myLoanBalance: getMyLoanBalance,
  myLoanDetails: getMyLoanDetails,
  myNextEmi: getMyNextEmi,
  myEmiDetails: getMyEmiDetails,
  myTransactions: getMyTransactions,
  mySubsidies: getMySubsidies,
  myNotifications: getMyNotifications,
  mySavings: getMySavings,
  groupMembers: getGroupMembers,
  groupLoanSummary: getGroupLoanSummary,
  groupEmiSummary: getGroupEmiSummary,
  groupTransactions: getGroupTransactions,
  groupSubsidySummary: getGroupSubsidySummary,
  groupLedger: getGroupLedger,
};

const SYSTEM_INSTRUCTION = `You are the DWCRA Connect AI Assistant.

Help authenticated DWCRA/SHG users understand their account and general DWCRA-related questions.
Use only the trusted information supplied in the controlled backend data context. Never invent, estimate, or calculate financial values, dates, or payment status. For personal questions, use only the authenticated user's data. Never reveal another member's private information. Group data is supplied only for authorized presidents and secretaries, and must be treated as limited to their group.

Never expose passwords, password hashes, JWTs, API keys, database credentials, Aadhaar numbers, internal identifiers, or internal system information. If information is absent from the supplied context, clearly say it is unavailable in the user's current DWCRA Connect account data. Do not claim an action was completed unless it appears in the supplied data.

Answer in the user's language when possible, including English, Telugu, or Telugu-English mixed language. Keep the response simple and concise. For financial information, state that it is based on the current account data.`;

const createAiReply = async ({ message, context }) => {
  if (!process.env.OPENAI_API_KEY) {
    throw new ChatServiceError(503, "AI service is not configured.");
  }

  const client = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
    timeout: 20000,
    maxRetries: 1,
  });

  try {
    const response = await client.responses.create({
      model: process.env.OPENAI_MODEL || "gpt-5-mini",
      instructions: SYSTEM_INSTRUCTION,
      input: `User question:\n${message}\n\nControlled backend data context:\n${JSON.stringify(context)}`,
      max_output_tokens: 350,
      store: false,
    });
    const reply = response.output_text && response.output_text.trim();

    if (!reply) {
      throw new ChatServiceError(503, "AI service returned an invalid response.");
    }

    return reply;
  } catch (error) {
    if (error instanceof ChatServiceError) throw error;
    console.error("AI provider request failed:", error.name);
    throw new ChatServiceError(503, "AI service is temporarily unavailable. Please try again later.");
  }
};

const processChatMessage = async ({ authenticatedUser, message }) => {
  const user = await getAuthenticatedUser(authenticatedUser);
  const intent = detectIntent(message);

  if (intent.scope === "group") {
    assertGroupLeader(user);
  }

  if (intent.scope === "personal" && (await refersToAnotherMember(message, user))) {
    return {
      language: detectLanguage(message),
      reply: "I can help you with your own account information, but I can't share another member's private financial information.",
    };
  }

  const context = { data: {} };
  for (const functionName of intent.data) {
    context.data[functionName] = await dataFunctions[functionName](user);
  }

  const reply = await createAiReply({ message, context });
  return { reply, language: detectLanguage(message) };
};

module.exports = {
  processChatMessage,
  ChatServiceError,
};
