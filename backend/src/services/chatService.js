const OpenAI = require("openai");
const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");

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

  // 1. Loan Balance / Remaining (highest priority for balance/remaining/left queries)
  if (hasAny(text, [
    /loan (left|remaining|balance)/,
    /how much.*loan.*(left|remaining|balance|pay)/,
    /how much.*(left|remaining|balance|pay)/,
    /remaining loan/,
    /balance entha/,
    /inka entha loan/,
    /naa loan entha undi/,
    /naaku entha loan undi/,
    /రుణం.*మిగిలి/
  ])) return "loan_balance";

  // 2. Loan Total (strict total loan queries)
  if (hasAny(text, [
    /\btotal loan\b/,
    /\bloan amount\b/,
    /what is my total loan/,
    /how much loan do i have/,
    /my total loan/,
    /my loan amount/,
    /మొత్తం రుణం/,
    /naa total loan/
  ])) return "loan_total";

  // 3. Active Loans
  if (hasAny(text, [
    /active loan/,
    /my active loans/,
    /show.*active loans/,
    /which.*loans.*active/,
    /list.*active loans/,
    /ప్రస్తుత రుణాలు/
  ]) && !text.includes("total") && !text.includes("balance") && !text.includes("remaining")) return "active_loans";

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
    case "loan_total": {
      const loans = await Loan.find({ memberId: user.userId, status: { $ne: "cancelled" } }).lean();
      return { loans };
    }

    case "loan_balance": {
      const loans = await Loan.find({ memberId: user.userId, status: { $in: ["active", "pending", "overdue"] } }).lean();
      const txs = await Transaction.find({ memberId: user.userId, type: "loan_payment", status: "completed" }).lean();
      const paidEmis = await Emi.find({ memberId: user.userId, status: "paid" }).lean();

      const totalTxPaid = txs.reduce((sum, t) => sum + (t.amount || 0), 0);
      const totalEmiPaid = paidEmis.reduce((sum, e) => sum + (e.amount || 0), 0);
      const totalPaid = Math.max(totalTxPaid, totalEmiPaid);

      return { loans, totalPaid };
    }

    case "active_loans": {
      const loans = await Loan.find({ memberId: user.userId, status: { $in: ["active", "pending", "overdue"] } }).lean();
      return { loans };
    }

    case "next_emi":
    case "emi_amount":
    case "emi_due_date":
    case "emi_details": {
      const emis = await Emi.find({ memberId: user.userId, status: { $in: ["pending", "overdue"] } }).sort({ dueDate: 1 }).lean();
      return { emis };
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
    const emis = data ? data.emis || [] : [];
    if (emis.length === 0) {
      return isTelugu ? "మీకు ప్రస్తుతం పెండింగ్ ఈఎంఐలు లేవు." : "You don't have any pending EMIs at the moment.";
    }

    const now = new Date();
    const overdueEmis = emis.filter(e => new Date(e.dueDate) < now);
    const upcomingEmis = emis.filter(e => new Date(e.dueDate) >= now);

    const primaryEmi = upcomingEmis.length > 0 ? upcomingEmis[0] : overdueEmis[0];
    const isPrimaryOverdue = upcomingEmis.length === 0 && overdueEmis.length > 0;

    const amount = primaryEmi.amount || 0;
    const due = formatDate(primaryEmi.dueDate);

    if (intent === "emi_amount") {
      return isTelugu
        ? `మీ ఈఎంఐ మొత్తం ₹${amount.toLocaleString('en-IN')}.`
        : `Your EMI amount is ₹${amount.toLocaleString('en-IN')}.`;
    }

    if (isPrimaryOverdue) {
      return isTelugu
        ? `మీకు ₹${amount.toLocaleString('en-IN')} బకాయి (ఓవర్‌డ్యూ) ఈఎంఐ ఉంది, గడువు తేదీ ${due}.`
        : `You have an overdue EMI of ₹${amount.toLocaleString('en-IN')}, which was due on ${due}.`;
    } else {
      let reply = isTelugu
        ? `మీ తదుపరి ఈఎంఐ ₹${amount.toLocaleString('en-IN')}, గడువు తేదీ ${due}.`
        : `Your next EMI is ₹${amount.toLocaleString('en-IN')}, due on ${due}.`;

      if (overdueEmis.length > 0) {
        const overdueTotal = overdueEmis.reduce((s, e) => s + (e.amount || 0), 0);
        reply += isTelugu
          ? ` (గమనిక: మీకు ₹${overdueTotal.toLocaleString('en-IN')} ఓవర్‌డ్యూ ఈఎంఐ బకాయి ఉంది.)`
          : ` (Note: You also have an overdue EMI balance of ₹${overdueTotal.toLocaleString('en-IN')}).`;
      }
      return reply;
    }
  }

  if (intent === "loan_total") {
    const loans = data ? data.loans || [] : [];
    if (loans.length === 0) {
      return isTelugu ? "మీకు ఎటువంటి రుణ రికార్డులు లేవు." : "You do not have any loan records.";
    }
    const total = loans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
    return isTelugu
      ? `మీ మొత్తం రుణ మొత్తం ₹${total.toLocaleString('en-IN')}.`
      : `Your total loan amount is ₹${total.toLocaleString('en-IN')}.`;
  }

  if (intent === "loan_balance") {
    const loans = data ? data.loans || [] : [];
    if (loans.length === 0) {
      return isTelugu ? "మీకు ఎటువంటి మిగిలిన రుణ బకాయి లేదు." : "You do not have any remaining loan balance.";
    }
    const principal = loans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
    const balance = Math.max(0, principal - (data.totalPaid || 0));
    return isTelugu
      ? `మీ మిగిలిన రుణ బకాయి ₹${balance.toLocaleString('en-IN')}.`
      : `Your remaining loan balance is ₹${balance.toLocaleString('en-IN')}.`;
  }

  if (intent === "active_loans") {
    const loans = data ? data.loans || [] : [];
    if (loans.length === 0) {
      return isTelugu ? "మీకు ఎటువంటి క్రియాశీల రుణాలు లేవు." : "You don't have any active loans.";
    }
    const loanCount = loans.length;
    const loanDetails = loans
      .map(l => `${l.loanType || 'Loan'}: ₹${(l.principalAmount || 0).toLocaleString('en-IN')} (${l.status})`)
      .join("\n");
    return (isTelugu ? `మీకు ${loanCount} క్రియాశీల రుణాలు ఉన్నాయి:\n` : `You have ${loanCount} active loan(s):\n`) + loanDetails;
  }

  switch (intent) {
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
  const startTime = Date.now();
  try {
    const user = await getAuthenticatedUser(authenticatedUser);
    const language = detectLanguage(message);
    const intent = detectIntent(message);

    if (intent !== "unknown") {
      const dbStart = Date.now();
      const data = await fetchDataForIntent(intent, user);
      const dbQueryMs = Date.now() - dbStart;

      let recordCount = 0;
      if (data) {
        if (Array.isArray(data)) recordCount = data.length;
        else if (data.loans && Array.isArray(data.loans)) recordCount = data.loans.length;
        else if (data.emis && Array.isArray(data.emis)) recordCount = data.emis.length;
        else if (typeof data === "object") recordCount = 1;
      }

      const reply = constructResponse(intent, data, language, user);
      const totalMs = Date.now() - startTime;

      if (process.env.NODE_ENV !== "production") {
        console.log(`[Chat] Query : "${message}"`);
        console.log(`[Chat] userId: ${user.userId} (${user.name})`);
        console.log(`[Chat] intent: ${intent}`);
        console.log(`[Chat] records: ${recordCount}`);
        console.log(`[Chat] queryMs: ${dbQueryMs} ms | totalMs: ${totalMs} ms`);
      }

      return {
        reply,
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
