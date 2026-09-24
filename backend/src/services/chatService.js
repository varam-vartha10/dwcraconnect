const OpenAI = require("openai");
const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");

const ACTIVE_LOAN_STATUSES = ["pending", "active", "overdue"];

class ChatServiceError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.name = "ChatServiceError";
    this.statusCode = statusCode;
  }
}

const formatDate = (value) => {
  if (!value) return null;
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

const detectLanguage = (message) => {
  const hasTelugu = /[\u0C00-\u0C7F]/.test(message);
  const hasLatin = /[A-Za-z]/.test(message);
  if (hasTelugu && hasLatin) return "te-en";
  if (hasTelugu) return "te";
  return "en";
};

const hasAny = (text, patterns) => {
  return patterns.some((pattern) => {
    if (pattern instanceof RegExp) {
      return pattern.test(text);
    }
    return text.includes(pattern);
  });
};

const detectIntent = (message) => {
  const text = message
    .toLowerCase()
    .trim()
    .replace(/[.,?!;:()"'']/g, "")
    .replace(/\s+/g, " ");

  // 1. Loan Balance / Remaining (check specific 'left/remaining/balance' first)
  if (hasAny(text, [
    /loan (left|remaining|balance)/,
    /how much.*loan.*(left|remaining|balance|pay)/,
    /how much.*pay/,
    /remaining loan/,
    /balance entha/,
    /inka entha loan/,
    /రుణం.*మిగిలి/
  ])) return "loan_balance";

  // 2. Loan Total
  if (hasAny(text, [
    /\btotal loan\b/,
    /\bloan amount\b/,
    /how much.*loan/,
    /my loan amount/,
    /మొత్తం రుణం/,
    /loan entha/,
    /naa total loan/,
    /naa loan entha/,
    /naaku entha loan/
  ])) return "loan_total";

  // 3. Active Loans
  if (hasAny(text, [
    /active loan/,
    /my loans/,
    /show.*loans/,
    /ప్రస్తుత రుణాలు/
  ])) return "active_loans";

  // 4. Next EMI / EMI Due Date
  if (hasAny(text, [
    /next emi/,
    /emi (due|date|when)/,
    /when is my emi/,
    /when is emi due/,
    /తదుపరి ఈఎంఐ/,
    /గడువు తేదీ/,
    /emi eppudu/,
    /next installment/
  ])) return "next_emi";

  // 5. EMI Amount
  if (hasAny(text, [
    /how much.*emi/,
    /emi amount/,
    /ఈఎంఐ మొత్తం/,
    /emi entha/,
    /my emi amount/
  ])) return "emi_amount";

  // 6. EMI Details
  if (hasAny(text, [
    /emi detail/,
    /show emi/
  ])) return "emi_details";

  // 7. Transactions / Payment History
  if (hasAny(text, [
    /transaction/,
    /payment history/,
    /show.*transaction/,
    /show.*payment/,
    /recent payment/,
    /లావాదేవీలు/,
    /naa transactions/
  ])) return "transactions";

  // 8. Subsidies
  if (hasAny(text, [
    /subsid(y|ies)/,
    /సబ్సిడీ/,
    /show.*subsid/
  ])) return "subsidies";

  // 9. Notifications
  if (hasAny(text, [
    /notification/,
    /alert/,
    /reminder/,
    /నోటిఫికేషన్లు/,
    /show.*notification/
  ])) return "notifications";

  // 10. Profile
  if (hasAny(text, [
    /profile/,
    /my detail/,
    /naa profile/,
    /naa detail/,
    /ప్రొఫైల్/
  ])) return "profile";

  // 11. Group ID
  if (hasAny(text, [
    /group id/,
    /group number/,
    /గ్రూప్ ఐడి/
  ])) return "group_id";

  // 12. Greetings
  if (hasAny(text, [
    /\bhi\b/,
    /\bhello\b/,
    /\bhey\b/,
    /నమస్తే/
  ])) return "greeting";

  return "unknown";
};

const getAuthenticatedUser = async (authenticatedUser) => {
  const user = await User.findById(authenticatedUser.id)
    .select("userId groupId name role position isActive village aadhaar phoneNumber")
    .lean();

  if (!user || !user.isActive) {
    throw new ChatServiceError(401, "Unauthorized access.");
  }
  return user;
};

// Data retrieval functions
const fetchDataForIntent = async (intent, user) => {
  switch (intent) {
    case "loan_total":
    case "loan_balance":
    case "active_loans": {
      const loans = await Loan.find({ memberId: user.userId, status: { $in: ACTIVE_LOAN_STATUSES } }).lean();
      const txs = await Transaction.find({ memberId: user.userId, type: "loan_payment", status: "completed" }).lean();
      const paidEmis = await Emi.find({ memberId: user.userId, status: "paid" }).lean();

      const totalTxPaid = txs.reduce((sum, t) => sum + (t.amount || 0), 0);
      const totalEmiPaid = paidEmis.reduce((sum, e) => sum + (e.amount || 0), 0);
      const totalPaid = Math.max(totalTxPaid, totalEmiPaid);

      return { loans, totalPaid };
    }

    case "next_emi":
    case "emi_amount":
    case "emi_due_date":
    case "emi_details": {
      return await Emi.findOne({ memberId: user.userId, status: { $in: ["pending", "overdue"] } }).sort({ dueDate: 1 }).lean();
    }

    case "transactions": {
      return await Transaction.find({ memberId: user.userId }).sort({ paymentDate: -1 }).limit(5).lean();
    }

    case "subsidies": {
      return await Subsidy.find({ memberId: user.userId }).sort({ createdAt: -1 }).limit(5).lean();
    }

    case "notifications": {
      return await Notification.find({ memberId: user.userId }).sort({ createdAt: -1 }).limit(5).lean();
    }

    case "profile":
    case "group_id":
      return user;

    default:
      return null;
  }
};

const constructResponse = (intent, data, language, user) => {
  const isTelugu = language === "te" || language === "te-en";

  if (intent === "greeting") {
    return isTelugu
      ? "నమస్తే! నేను మీకు మీ రుణం, ఈఎంఐ, లావాదేవీలు మరియు ప్రొఫైల్ వివరాల గురించి సహాయం చేయగలను."
      : "Hello! I am your DWCRA assistant. I can help you with questions about your loans, EMIs, transactions, subsidies, notifications, and profile.";
  }

  if (["next_emi", "emi_amount", "emi_due_date", "emi_details"].includes(intent)) {
    if (!data) {
      return isTelugu ? "మీకు ప్రస్తుతం పెండింగ్ ఈఎంఐలు లేవు." : "You don't have any pending EMIs at the moment.";
    }
  }

  if (["loan_total", "loan_balance", "active_loans"].includes(intent)) {
    if (!data || !data.loans || data.loans.length === 0) {
      return isTelugu ? "మీకు ఎటువంటి క్రియాశీల రుణాలు లేవు." : "You don't have any active loans.";
    }
  }

  switch (intent) {
    case "loan_total": {
      const total = data.loans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
      return isTelugu
        ? `మీ మొత్తం రుణ మొత్తం ₹${total.toLocaleString('en-IN')}.`
        : `Your total loan amount is ₹${total.toLocaleString('en-IN')}.`;
    }

    case "loan_balance": {
      const principal = data.loans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
      const balance = Math.max(0, principal - data.totalPaid);
      return isTelugu
        ? `మీ మిగిలిన రుణ బకాయి ₹${balance.toLocaleString('en-IN')}.`
        : `Your remaining loan balance is ₹${balance.toLocaleString('en-IN')}.`;
    }

    case "active_loans": {
      const loanCount = data.loans.length;
      const loanDetails = data.loans
        .map(l => `${l.loanType || 'Loan'}: ₹${(l.principalAmount || 0).toLocaleString('en-IN')} (${l.status})`)
        .join("\n");
      return (isTelugu ? `మీకు ${loanCount} క్రియాశీల రుణాలు ఉన్నాయి:\n` : `You have ${loanCount} active loan(s):\n`) + loanDetails;
    }

    case "next_emi":
    case "emi_due_date":
    case "emi_details": {
      const amount = data.amount || 0;
      const due = formatDate(data.dueDate);
      return isTelugu
        ? `మీ తదుపరి ఈఎంఐ ₹${amount.toLocaleString('en-IN')}, గడువు తేదీ ${due}.`
        : `Your next EMI is ₹${amount.toLocaleString('en-IN')}, due on ${due}.`;
    }

    case "emi_amount": {
      const amount = data.amount || 0;
      return isTelugu
        ? `మీ ఈఎంఐ మొత్తం ₹${amount.toLocaleString('en-IN')}.`
        : `Your EMI amount is ₹${amount.toLocaleString('en-IN')}.`;
    }

    case "transactions": {
      if (!data || data.length === 0) {
        return isTelugu ? "ఇటీవలి లావాదేవీలు ఏవీ లేవు." : "No recent transactions found.";
      }
      const txList = data
        .map(t => `${formatDate(t.paymentDate || t.createdAt)}: ₹${t.amount} (${t.type || 'payment'})`)
        .join("\n");
      return (isTelugu ? "ఇటీవలి లావాదేవీలు:\n" : "Recent transactions:\n") + txList;
    }

    case "subsidies": {
      if (!data || data.length === 0) {
        return isTelugu ? "సబ్సిడీలు ఏవీ లేవు." : "No subsidies found.";
      }
      const subList = data
        .map(s => `${s.schemeName || 'Subsidy'}: ₹${s.amount} (${s.status})`)
        .join("\n");
      return (isTelugu ? "మీ సబ్సిడీ వివరాలు:\n" : "Your subsidy details:\n") + subList;
    }

    case "notifications": {
      if (!data || data.length === 0) {
        return isTelugu ? "నోటిఫికేషన్లు ఏవీ లేవు." : "No notifications found.";
      }
      const notifList = data.map(n => `- ${n.title}`).join("\n");
      return (isTelugu ? "ఇటీవలి నోటిఫికేషన్లు:\n" : "Recent notifications:\n") + notifList;
    }

    case "profile": {
      return isTelugu
        ? `పేరు: ${data.name}\nID: ${data.userId}\nగ్రూప్: ${data.groupId}`
        : `Name: ${data.name}\nID: ${data.userId}\nGroup: ${data.groupId}`;
    }

    case "group_id": {
      return isTelugu
        ? `మీ గ్రూప్ ఐడి ${data.groupId}.`
        : `Your Group ID is ${data.groupId}.`;
    }

    default:
      return isTelugu
        ? "నేను మీకు మీ రుణం, ఈఎంఐ, లావాదేవీలు, సబ్సిడీలు, నోటిఫికేషన్లు మరియు ప్రొఫైల్ వివరాల గురించి సహాయం చేయగలను."
        : "I can help you with your loan, EMI, transactions, subsidies, notifications and profile.";
  }
};

const createAiReply = async (message, userContext) => {
  if (!process.env.OPENAI_API_KEY) return null;
  try {
    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are the DWCRA Connect AI Assistant. Help users with general DWCRA questions. Do not invent financial data. Context: " + JSON.stringify(userContext) },
        { role: "user", content: message }
      ],
      max_tokens: 300,
    });
    return response.choices[0].message.content.trim();
  } catch (error) {
    if (process.env.NODE_ENV !== "production") {
      console.error("[Chat] Optional AI service provider error:", error.message);
    }
    return null;
  }
};

const processChatMessage = async ({ authenticatedUser, message }) => {
  try {
    const user = await getAuthenticatedUser(authenticatedUser);
    const language = detectLanguage(message);
    const intent = detectIntent(message);

    if (intent !== "unknown") {
      const data = await fetchDataForIntent(intent, user);
      return {
        reply: constructResponse(intent, data, language, user),
        language,
        intent,
        dataSource: "database"
      };
    }

    // Optional AI fallback for non-account general questions
    const aiReply = await createAiReply(message, { name: user.name, role: user.role });
    if (aiReply) {
      return { reply: aiReply, language, intent: "ai_fallback", dataSource: "ai" };
    }

    // Standard friendly fallback response when query is unrecognized and no AI key configured
    return {
      reply: constructResponse("unknown", null, language, user),
      language,
      intent: "unknown",
      dataSource: "none"
    };
  } catch (error) {
    if (error instanceof ChatServiceError) throw error;
    throw new ChatServiceError(500, "Unable to process your request right now.");
  }
};

module.exports = { processChatMessage, ChatServiceError };
