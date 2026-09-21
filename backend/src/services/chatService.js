const OpenAI = require("openai");
const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");

const ACTIVE_LOAN_STATUSES = ["pending", "active", "overdue"];
const GROUP_LEADER_POSITIONS = new Set(["president", "secretary"]);

class ChatServiceError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.name = "ChatServiceError";
    this.statusCode = statusCode;
  }
}

const formatDate = (value) => (value ? new Date(value).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : null);
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

  // 1. Loan Intents
  if (hasAny(text, [/\btotal loan\b/, /మొత్తం రుణం/, /total loan/])) return "loan_total";
  if (hasAny(text, [/\b(loan (left|remaining|balance))\b/, /\b(how much.*pay)\b/, /రుణం.*మిగిలి/, /loan entha/])) return "loan_balance";
  if (hasAny(text, [/\bactive loans\b/, /ప్రస్తుత రుణాలు/, /active loans/])) return "active_loans";

  // 2. EMI Intents
  if (hasAny(text, [/\bnext emi\b/, /తదుపరి ఈఎంఐ/, /next emi/])) return "next_emi";
  if (hasAny(text, [/\bemi amount\b/, /ఈఎంఐ మొత్తం/, /emi entha/])) return "emi_amount";
  if (hasAny(text, [/\bemi (due|date)\b/, /గడువు తేదీ/, /emi eppudu/])) return "emi_due_date";

  // 3. Financial Logs
  if (hasAny(text, [/\b(transactions?|payments?)\b/, /లావాదేవీలు/, /payment history/])) return "transactions";
  if (hasAny(text, [/\bsubsid(y|ies)\b/, /సబ్సిడీ/, /subsidies/])) return "subsidies";
  if (hasAny(text, [/\bnotifications\b/, /నోటిఫికేషన్లు/, /alerts/])) return "notifications";

  // 4. Account
  if (hasAny(text, [/\bprofile\b/, /ప్రొఫైల్/, /my details/])) return "profile";
  if (hasAny(text, [/\bgroup id\b/, /గ్రూప్ ఐడి/, /group id/])) return "group_id";

  return "unknown";
};

const getAuthenticatedUser = async (authenticatedUser) => {
  const user = await User.findById(authenticatedUser.id).select("userId groupId name role position isActive").lean();
  if (!user || !user.isActive) throw new ChatServiceError(401, "Unauthorized access.");
  return user;
};

// Data retrieval functions
const fetchDataForIntent = async (intent, user) => {
  switch (intent) {
    case "loan_total":
    case "loan_balance":
    case "active_loans":
      const loans = await Loan.find({ memberId: user.userId, status: { $in: ACTIVE_LOAN_STATUSES } }).lean();
      const txs = await Transaction.find({ memberId: user.userId, type: "loan_payment", status: "completed" }).lean();
      const totalPaid = txs.reduce((sum, t) => sum + t.amount, 0);
      return { loans, totalPaid };

    case "next_emi":
    case "emi_amount":
    case "emi_due_date":
      return await Emi.findOne({ memberId: user.userId, status: { $in: ["pending", "overdue"] } }).sort({ dueDate: 1 }).lean();

    case "transactions":
      return await Transaction.find({ memberId: user.userId }).sort({ paymentDate: -1 }).limit(5).lean();

    case "subsidies":
      return await Subsidy.find({ memberId: user.userId }).sort({ createdAt: -1 }).limit(5).lean();

    case "notifications":
      return await Notification.find({ memberId: user.userId }).sort({ createdAt: -1 }).limit(5).lean();

    case "profile":
    case "group_id":
      return user;

    default:
      return null;
  }
};

const constructResponse = (intent, data, language) => {
  const isTelugu = language === "te" || language === "te-en";

  if (!data && ["next_emi", "emi_amount", "emi_due_date"].includes(intent)) {
    return isTelugu ? "మీకు ప్రస్తుతం పెండింగ్ ఈఎంఐలు లేవు." : "You don't have any pending EMIs at the moment.";
  }

  switch (intent) {
    case "loan_total":
      const total = data.loans.reduce((sum, l) => sum + l.principalAmount, 0);
      return isTelugu ? `మీ మొత్తం రుణ మొత్తం ₹${total.toLocaleString('en-IN')}.` : `Your total loan amount is ₹${total.toLocaleString('en-IN')}.`;

    case "loan_balance":
      const principal = data.loans.reduce((sum, l) => sum + l.principalAmount, 0);
      const balance = principal - data.totalPaid;
      return isTelugu ? `మీ మిగిలిన రుణ బకాయి ₹${balance.toLocaleString('en-IN')}.` : `Your remaining loan balance is ₹${balance.toLocaleString('en-IN')}.`;

    case "next_emi":
      return isTelugu ? `మీ తదుపరి ఈఎంఐ ₹${data.amount.toLocaleString('en-IN')}, గడువు తేదీ ${formatDate(data.dueDate)}.` : `Your next EMI is ₹${data.amount.toLocaleString('en-IN')}, due on ${formatDate(data.dueDate)}.`;

    case "transactions":
      if (data.length === 0) return isTelugu ? "లావాదేవీలు ఏవీ లేవు." : "No recent transactions found.";
      const txList = data.map(t => `${formatDate(t.paymentDate)}: ₹${t.amount} (${t.type})`).join("\n");
      return (isTelugu ? "ఇటీవలి లావాదేవీలు:\n" : "Recent transactions:\n") + txList;

    case "profile":
      return isTelugu ? `పేరు: ${data.name}\nID: ${data.userId}\nగ్రూప్: ${data.groupId}` : `Name: ${data.name}\nID: ${data.userId}\nGroup: ${data.groupId}`;

    case "group_id":
      return isTelugu ? `మీ గ్రూప్ ఐడి ${data.groupId}.` : `Your Group ID is ${data.groupId}.`;

    default:
      return isTelugu ? "క్షమించండి, నేను సహాయం చేయగలను: రుణం, ఈఎంఐ, లావాదేవీలు మరియు ప్రొఫైల్ గురించి అడగండి." : "I can help you with questions about your loan, EMI, transactions, and profile. Please try asking about one of these.";
  }
};

const createAiReply = async (message, userContext) => {
  if (!process.env.OPENAI_API_KEY) {
    return null; // Fallback to local unknown message
  }
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  try {
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
    console.error("AI provider failure:", error.message);
    return null;
  }
};

const processChatMessage = async ({ authenticatedUser, message }) => {
  const user = await getAuthenticatedUser(authenticatedUser);
  const language = detectLanguage(message);
  const intent = detectIntent(message);

  if (intent !== "unknown") {
    const data = await fetchDataForIntent(intent, user);
    return {
      reply: constructResponse(intent, data, language),
      language,
      intent,
      dataSource: "database"
    };
  }

  // Fallback to AI if configured
  const aiReply = await createAiReply(message, { name: user.name, role: user.role });
  if (aiReply) {
    return { reply: aiReply, language, intent: "ai_fallback", dataSource: "ai" };
  }

  // Final fallback
  return {
    reply: constructResponse("unknown", null, language),
    language,
    intent: "unknown",
    dataSource: "none"
  };
};

module.exports = { processChatMessage, ChatServiceError };
