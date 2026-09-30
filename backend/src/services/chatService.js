const OpenAI = require("openai");
const User = require("../models/User");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");
const { getLoanSummary, getEmiSummary } = require("./financialService");

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

  // 1. Paid Amount
  if (hasAny(text, [
    /how much.*paid/,
    /total paid/,
    /nenu entha pay/,
    /paid amount/,
    /payment completed/
  ])) return "paid_amount";

  // 2. Loan Balance / Remaining (highest priority for balance/remaining/left/inka entha queries)
  if (hasAny(text, [
    /loan (left|remaining|balance)/,
    /how much.*loan.*(left|remaining|balance|pay)/,
    /how much.*(left|remaining|balance|pay)/,
    /remaining loan/,
    /balance entha/,
    /inka entha loan/,
    /loan inka entha/,
    /naa loan entha undi/,
    /naa loan inka entha undi/,
    /naaku entha loan undi/,
    /రుణం.*మిగిలి/
  ])) return "loan_balance";

  // 3. Loan Total (strict total loan queries)
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

  // 4. Active Loans
  if (hasAny(text, [
    /active loan/,
    /my active loans/,
    /show.*active loans/,
    /which.*loans.*active/,
    /list.*active loans/,
    /ప్రస్తుత రుణాలు/
  ]) && !text.includes("total") && !text.includes("balance") && !text.includes("remaining")) return "active_loans";

  // 5. Next EMI / EMI Due Date
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

  // 6. EMI Amount
  if (hasAny(text, [
    /how much.*emi/,
    /emi amount/,
    /ఈఎంఐ మొత్తం/,
    /emi entha/,
    /my emi amount/
  ])) return "emi_amount";

  // 7. EMI Details
  if (hasAny(text, [
    /emi detail/,
    /show emi/
  ])) return "emi_details";

  // 8. Transactions / Payment History
  if (hasAny(text, [
    /transaction/,
    /payment history/,
    /show.*transaction/,
    /show.*payment/,
    /recent payment/,
    /లావాదేవీలు/,
    /naa transactions/
  ])) return "transactions";

  // 9. Subsidies
  if (hasAny(text, [
    /subsid(y|ies)/,
    /సబ్సిడీ/,
    /show.*subsid/
  ])) return "subsidies";

  // 10. Notifications
  if (hasAny(text, [
    /notification/,
    /alert/,
    /reminder/,
    /నోటిఫికేషన్లు/,
    /show.*notification/
  ])) return "notifications";

  // 11. Profile
  if (hasAny(text, [
    /profile/,
    /my detail/,
    /naa profile/,
    /naa detail/,
    /ప్రొఫైల్/
  ])) return "profile";

  // 12. Group ID
  if (hasAny(text, [
    /group id/,
    /group number/,
    /గ్రూప్ ఐడి/
  ])) return "group_id";

  // 13. Greetings
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
    case "paid_amount":
    case "loan_balance":
    case "active_loans": {
      return await getLoanSummary(user.userId);
    }

    case "next_emi":
    case "emi_amount":
    case "emi_due_date":
    case "emi_details": {
      return await getEmiSummary(user.userId);
    }

    case "transactions": {
      return await Transaction.find({ memberId: user.userId }).sort({ paymentDate: -1 }).limit(10).lean();
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

  // EMI Intents
  if (["next_emi", "emi_amount", "emi_due_date", "emi_details"].includes(intent)) {
    const emiSummary = data || {};
    if (!emiSummary.hasEmis || emiSummary.unpaidEmisCount === 0) {
      return isTelugu ? "మీకు ప్రస్తుతం పెండింగ్ ఈఎంఐలు లేవు." : "You don't have any pending EMIs at the moment.";
    }

    const nextUpcoming = emiSummary.nextUpcomingEmi;
    const primaryOverdue = emiSummary.primaryOverdueEmi;

    if (intent === "emi_amount") {
      const primary = nextUpcoming || primaryOverdue;
      const amt = primary.amount || 0;
      return isTelugu
        ? `మీ ఈఎంఐ మొత్తం ₹${amt.toLocaleString('en-IN')}.`
        : `Your EMI amount is ₹${amt.toLocaleString('en-IN')}.`;
    }

    if (nextUpcoming) {
      const amt = nextUpcoming.amount || 0;
      const due = formatDate(nextUpcoming.dueDate);
      let reply = isTelugu
        ? `మీ తదుపరి ఈఎంఐ ₹${amt.toLocaleString('en-IN')}, గడువు తేదీ ${due}.`
        : `Your next EMI is ₹${amt.toLocaleString('en-IN')}, due on ${due}.`;

      if (emiSummary.overdueEmisCount > 0 && primaryOverdue) {
        reply += isTelugu
          ? ` (గమనిక: మీకు ${formatDate(primaryOverdue.dueDate)}న బకాయి ఉన్న ₹${primaryOverdue.amount.toLocaleString('en-IN')} ఈఎంఐ కూడా ఉంది).`
          : ` (Note: You also have an overdue EMI of ₹${primaryOverdue.amount.toLocaleString('en-IN')} due on ${formatDate(primaryOverdue.dueDate)}).`;
      }
      return reply;
    } else if (primaryOverdue) {
      const amt = primaryOverdue.amount || 0;
      const due = formatDate(primaryOverdue.dueDate);
      return isTelugu
        ? `మీకు ₹${amt.toLocaleString('en-IN')} బకాయి (ఓవర్‌డ్యూ) ఈఎంఐ ఉంది, గడువు తేదీ ${due}.`
        : `You have an overdue EMI of ₹${amt.toLocaleString('en-IN')}, which was due on ${due}.`;
    }
  }

  // Loan Intents
  if (intent === "loan_total") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans) {
      return isTelugu
        ? "మీ ఖాతా కోసం ఎటువంటి రుణ రికార్డులు కనుగొనబడలేదు."
        : "I couldn't find any loan records for your account.";
    }
    return isTelugu
      ? `మీ మొత్తం రుణ మొత్తం ₹${loanSummary.totalPrincipal.toLocaleString('en-IN')}.`
      : `Your total loan amount is ₹${loanSummary.totalPrincipal.toLocaleString('en-IN')}.`;
  }

  if (intent === "paid_amount") {
    const loanSummary = data || {};
    return isTelugu
      ? `మీరు మీ రుణ చెల్లింపుల కోసం మొత్తం ₹${loanSummary.totalPaid.toLocaleString('en-IN')} చెల్లించారు.`
      : `You have paid a total of ₹${loanSummary.totalPaid.toLocaleString('en-IN')} towards your loan payments.`;
  }

  if (intent === "loan_balance") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans || loanSummary.activeLoanCount === 0) {
      return isTelugu
        ? "మీకు ఎటువంటి మిగిలిన రుణ బకాయి లేదు."
        : "You do not have any remaining loan balance.";
    }
    return isTelugu
      ? `మీ మిగిలిన రుణ బకాయి ₹${loanSummary.remainingBalance.toLocaleString('en-IN')}.`
      : `Your remaining loan balance is ₹${loanSummary.remainingBalance.toLocaleString('en-IN')}.`;
  }

  if (intent === "active_loans") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans || loanSummary.activeLoanCount === 0) {
      return isTelugu ? "మీకు ఎటువంటి క్రియాశీల రుణాలు లేవు." : "You don't have any active loans.";
    }
    const loanCount = loanSummary.activeLoanCount;
    const loanDetails = loanSummary.activeLoans
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
