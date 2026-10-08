const OpenAI = require("openai");
const User = require("../models/User");
const Subsidy = require("../models/Subsidy");
const {
  getMyLoanSummary,
  getMyEmiSummary,
  getMySubsidySummary,
  getMyTransactionSummary,
  getMyNotificationSummary,
  getMyAccountSummary,
} = require("./accountSummaryService");
const { getGroupSummary } = require("./groupSummaryService");

class ChatServiceError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.name = "ChatServiceError";
    this.statusCode = statusCode;
  }
}

// Short-term conversation context store (In-memory, session-scoped per user)
const conversationContextStore = new Map();

const getStoredContext = (userId) => {
  return conversationContextStore.get(userId) || null;
};

const updateStoredContext = (userId, intent, scope) => {
  conversationContextStore.set(userId, {
    lastIntent: intent,
    lastScope: scope,
    updatedAt: Date.now(),
  });
};

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

/**
 * Robust Intent Classification Layer
 */
const detectIntent = (message, previousContext = null) => {
  const text = message
    .toLowerCase()
    .trim()
    .replace(/[.,?!;:()"'']/g, "")
    .replace(/\s+/g, " ");

  // --- 1. MULTI-TURN CONTEXTUAL FOLLOW-UPS ---
  if (previousContext) {
    const lastIntent = previousContext.lastIntent;

    // Follow-up: "What about the overdue one?"
    if (hasAny(text, [/overdue/, /pending/]) && (lastIntent === "personal_next_emi" || lastIntent === "personal_emi_summary")) {
      return "personal_overdue_emi";
    }

    // Follow-up: "How much is left?" / "What is left?"
    if (hasAny(text, [/what is left/, /how much is left/, /left/, /remaining/, /balance/]) && (lastIntent === "personal_loan_total" || lastIntent === "personal_loan_paid")) {
      return "personal_loan_remaining";
    }

    // Follow-up: "How much is still pending?" (Group context)
    if (hasAny(text, [/pending/, /outstanding/, /remaining/]) && lastIntent === "group_loan_total") {
      return "group_outstanding_total";
    }

    // Follow-up: "How much did I pay?"
    if (hasAny(text, [/paid/, /pay/, /how much/]) && lastIntent === "personal_loan_total") {
      return "personal_loan_paid";
    }
  }

  // --- 2. GROUP INTENTS (Leader Authorized) ---

  // Group Subsidy Total (Fixed Bug)
  if (hasAny(text, [
    /group.*subsidy/,
    /our group.*subsidy/,
    /subsidy.*(group|our group)/,
    /how much subsidy.*(group|our group)/,
    /total subsidy.*(group|our group)/,
    /group subsidy entha/,
    /mana group.*subsidy/,
    /సబ్సిడీ.*గ్రూప్/
  ])) return "group_subsidy_total";

  // Group Subsidy Member Breakdown
  if (hasAny(text, [
    /who.*received.*subsidy/,
    /which members.*subsidy/,
    /members.*got.*subsidy/,
    /evariki subsidy vachindi/,
    /సబ్సిడీ పొందిన సభ్యులు/
  ])) return "group_subsidy_members";

  // Group Members Count
  if (hasAny(text, [
    /how many members.*group/,
    /members.*in.*group/,
    /group lo enni members/,
    /group members count/,
    /గ్రూప్‌లో ఎంతమంది సభ్యులు/
  ])) return "group_members_count";

  // Group Overdue Members
  if (hasAny(text, [
    /group overdue/,
    /which members.*overdue/,
    /members.*overdue/,
    /group lo overdue members/
  ])) return "group_overdue_members";

  // Group Loan Total
  if (hasAny(text, [
    /group total loan/,
    /how much loan.*our group/,
    /our group loan/,
    /mana group loan/,
    /group loan amount/,
    /group loan entha/
  ])) return "group_loan_total";

  // Group Loan Paid & Outstanding
  if (hasAny(text, [
    /group.*paid/,
    /how much.*group.*paid/,
    /group total paid/
  ])) return "group_paid_total";

  if (hasAny(text, [
    /group.*outstanding/,
    /group.*remaining/,
    /group.*balance/,
    /our.*outstanding/,
    /our.*remaining/,
    /our.*balance/
  ])) return "group_outstanding_total";

  // Group Summary
  if (hasAny(text, [
    /group summary/,
    /group details/,
    /tell me about my group/,
    /our group/
  ])) return "group_summary";

  // --- 3. PERSONAL INTENTS ---

  // Personal Paid Amount
  if (hasAny(text, [
    /how much.*paid/,
    /total paid/,
    /nenu entha pay/,
    /entha pay chesanu/,
    /paid amount/,
    /payment completed/
  ])) return "personal_loan_paid";

  // Personal Loan Balance / Remaining
  if (hasAny(text, [
    /loan (left|remaining|balance)/,
    /how much.*loan.*(left|remaining|balance|pay)/,
    /how much.*(left|remaining|balance|pay)/,
    /remaining loan/,
    /balance entha/,
    /inka entha loan/,
    /loan inka entha/,
    /naa loan entha und/,
    /naa loan inka entha und/,
    /naaku entha loan und/,
    /రుణం.*మిగిలి/
  ])) return "personal_loan_remaining";

  // Personal Loan Total
  if (hasAny(text, [
    /\btotal loan\b/,
    /\bloan amount\b/,
    /what is my loan/,
    /my loan/,
    /what is my total loan/,
    /how much loan do i have/,
    /my total loan/,
    /my loan amount/,
    /how much did i borrow/,
    /మొత్తం రుణం/,
    /naa total loan/,
    /naa loan/
  ])) return "personal_loan_total";

  // Personal Active Loans
  if (hasAny(text, [
    /active loan/,
    /my active loans/,
    /show.*active loans/,
    /which.*loans.*active/,
    /list.*active loans/,
    /ప్రస్తుత రుణాలు/
  ]) && !text.includes("total") && !text.includes("balance") && !text.includes("remaining")) return "personal_active_loans";

  // Personal Overdue EMI
  if (hasAny(text, [
    /overdue/,
    /is my emi overdue/,
    /pending emi overdue/,
    /tappu emi/,
    /naa emi overdue/,
    /ఓవర్‌డ్యూ/
  ])) return "personal_overdue_emi";

  // Personal Next EMI / Due Date
  if (hasAny(text, [
    /next emi/,
    /when is the next one/,
    /emi (due|date|when)/,
    /when is my emi/,
    /when is emi due/,
    /తదుపరి ఈఎంఐ/,
    /గడువు తేదీ/,
    /emi eppudu/,
    /naa emi eppudu/,
    /next installment/
  ])) return "personal_next_emi";

  // Personal EMI Amount
  if (hasAny(text, [
    /how much.*emi/,
    /emi amount/,
    /ఈఎంఐ మొత్తం/,
    /emi entha/,
    /naa emi entha/
  ])) return "personal_emi_amount";

  // Personal Account Overview
  if (hasAny(text, [
    /tell me about my account/,
    /account summary/,
    /account details/,
    /my account/
  ])) return "personal_account_summary";

  // Personal Transactions / Last Payment
  if (hasAny(text, [
    /last payment/,
    /what was my last payment/,
    /recent payment/,
    /did i make a payment/,
    /transaction/,
    /payment history/,
    /show.*transaction/,
    /show.*payment/,
    /లావాదేవీలు/,
    /naa transactions/,
    /naa last payment/
  ])) return "personal_transaction_history";

  // Personal Subsidies
  if (hasAny(text, [
    /subsid(y|ies)/,
    /సబ్సిడీ/,
    /show.*subsid/,
    /naa subsidy/,
    /subsidy vachinda/
  ])) return "personal_subsidy_total";

  // Personal Notifications
  if (hasAny(text, [
    /notification/,
    /alert/,
    /reminder/,
    /నోటిఫికేషన్లు/,
    /show.*notification/,
    /do i have any reminders/
  ])) return "personal_notifications";

  // Profile & Group ID
  if (hasAny(text, [/who am i/, /profile/, /my detail/, /naa profile/])) return "personal_profile";
  if (hasAny(text, [/group id/, /group number/, /గ్రూప్ ఐడి/])) return "personal_group_id";

  // Greetings & Non-Financial
  if (hasAny(text, [/\bhi\b/, /\bhello\b/, /\bhey\b/, /నమస్తే/])) return "greeting";
  if (hasAny(text, [/thanks/, /thank you/, /ధన్యవాదాలు/])) return "thanks";

  // General Educational Questions
  if (hasAny(text, [/what can you (do|help)/, /help me/, /explain.*emi/, /what is.*emi/, /explain.*subsidy/, /what is.*subsidy/])) return "general_financial_question";

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

/**
 * Data Retrieval Layer (Always Grounded in MongoDB Atlas)
 */
const fetchDataForIntent = async (intent, user) => {
  const isLeader = user.role === "leader" || ["president", "secretary"].includes(user.position);

  switch (intent) {
    // --- GROUP INTENTS ---
    case "group_subsidy_total":
    case "group_subsidy_members": {
      if (!isLeader) return { isMemberRestricted: true };
      const groupSubsidies = await Subsidy.find({ groupId: user.groupId }).sort({ createdAt: -1 }).lean();
      const totalAmount = groupSubsidies.reduce((sum, s) => sum + (s.amount || 0), 0);
      return {
        groupId: user.groupId,
        totalAmount,
        count: groupSubsidies.length,
        subsidies: groupSubsidies,
      };
    }

    case "group_members_count":
    case "group_loan_total":
    case "group_paid_total":
    case "group_outstanding_total":
    case "group_emi_summary":
    case "group_overdue_members":
    case "group_summary": {
      if (!isLeader) return { isMemberRestricted: true };
      return await getGroupSummary(user.groupId);
    }

    // --- PERSONAL INTENTS ---
    case "personal_loan_total":
    case "personal_loan_paid":
    case "personal_loan_remaining":
    case "personal_active_loans": {
      return await getMyLoanSummary(user.userId, user.groupId, user.role);
    }

    case "personal_next_emi":
    case "personal_emi_amount":
    case "personal_overdue_emi":
    case "personal_emi_summary": {
      return await getMyEmiSummary(user.userId, user.groupId, user.role);
    }

    case "personal_account_summary": {
      return await getMyAccountSummary(user.userId, user.groupId, user.role);
    }

    case "personal_transaction_history":
    case "personal_last_payment": {
      return await getMyTransactionSummary(user.userId, user.groupId, user.role, 10);
    }

    case "personal_subsidy_total":
    case "personal_subsidy_history": {
      return await getMySubsidySummary(user.userId, user.groupId, user.role);
    }

    case "personal_notifications": {
      return await getMyNotificationSummary(user.userId, user.groupId, user.role, 10);
    }

    case "personal_profile":
    case "personal_group_id":
      return user;

    default:
      return null;
  }
};

const getFollowUpSuggestions = (intent, language, isLeader = false) => {
  const isTelugu = language === "te" || language === "te-en";

  if (isLeader) {
    switch (intent) {
      case "group_subsidy_total":
      case "group_subsidy_members":
        return isTelugu
          ? ["ఎవరెవరికి సబ్సిడీ వచ్చింది?", "గ్రూప్ మొత్తం రుణం ఎంత?", "ఓవర్‌డ్యూ ఉన్న సభ్యులు ఎవరు?"]
          : ["Which members received subsidy?", "Group total loan", "Which members have overdue EMIs?"];

      case "group_summary":
      case "group_loan_total":
      case "group_members_count":
        return isTelugu
          ? ["గ్రూప్ సబ్సిడీ ఎంత?", "గ్రూప్ లో ఓవర్‌డ్యూ ఉన్నవారెవరు?", "నా వ్యక్తిగత వివరాలు"]
          : ["Group total subsidy", "Which members have overdue EMIs?", "Show my personal account summary"];

      default:
        return isTelugu
          ? ["గ్రూప్ మొత్తం రుణం ఎంత?", "గ్రూప్ సబ్సిడీ ఎంత?", "ఓవర్‌డ్యూ సభ్యులు ఎవరు?"]
          : ["Group total loan", "Group total subsidy", "Which members have overdue EMIs?"];
    }
  }

  switch (intent) {
    case "personal_loan_total":
    case "personal_loan_remaining":
    case "personal_loan_paid":
      return isTelugu
        ? ["తదుపరి ఈఎంఐ ఎప్పుడు?", "నా చెల్లింపుల చరిత్ర చూపించు", "ఓవర్‌డ్యూ ఈఎంఐ ఏమైనా ఉందా?"]
        : ["When is my next EMI?", "How much have I paid?", "Show my recent transactions"];

    case "personal_next_emi":
    case "personal_emi_amount":
    case "personal_overdue_emi":
      return isTelugu
        ? ["నాకు ఇంకా ఎంత రుణం బకాయి ఉంది?", "నా చెల్లింపుల చరిత్ర చూపించు", "నా సబ్సిడీ వివరాలు"]
        : ["How much loan do I have left?", "Show my transactions", "Do I have any subsidies?"];

    case "personal_subsidy_total":
      return isTelugu
        ? ["మొత్తం రుణం ఎంత?", "తదుపరి ఈఎంఐ ఎప్పుడు?", "నా లావాదేవీలు"]
        : ["What is my total loan?", "When is my next EMI?", "Show my recent transactions"];

    default:
      return isTelugu
        ? ["మొత్తం రుణం ఎంత?", "తదుపరి ఈఎంఐ ఎప్పుడు?", "మిగిలిన రుణం ఎంత?"]
        : ["What is my total loan?", "When is my next EMI?", "How much loan do I have left?"];
  }
};

/**
 * Natural Language Response Generator
 */
const constructResponse = (intent, data, language, user, rawMessage = "") => {
  const isTelugu = language === "te" || language === "te-en";
  const isLeader = user.role === "leader" || ["president", "secretary"].includes(user.position);

  if (intent === "greeting") {
    return {
      reply: isTelugu
        ? "నమస్తే! నేను మీ డిడబ్ల్యూసిఆర్‌ఎ సహాయకుడిని. మీ రుణం, ఈఎంఐ, చెల్లింపులు, సబ్సిడీలు మరియు నోటిఫికేషన్‌ల వివరాల గురించి సహాయం చేయగలను."
        : "Hello! I am your DWCRA Connect AI Assistant. I can help you with your loan, EMI, payments, subsidies, transactions, notifications, and profile.",
      suggestions: getFollowUpSuggestions("greeting", language, isLeader)
    };
  }

  if (intent === "thanks") {
    return {
      reply: isTelugu
        ? "మీకు సహాయపడినందుకు సంతోషం! ఇంకా ఏమైనా సందేహాలు ఉంటే అడగండి."
        : "You're welcome! Let me know if you need any other account details.",
      suggestions: getFollowUpSuggestions("general", language, isLeader)
    };
  }

  if (intent === "general_financial_question") {
    const text = rawMessage.toLowerCase();
    if (text.includes("emi")) {
      return {
        reply: isTelugu
          ? "ఈఎంఐ (EMI - Equated Monthly Installment) అనేది ప్రతి నెలా మీరు చెల్లించాల్సిన స్థిరమైన వాయిదా మొత్తం."
          : "An EMI (Equated Monthly Installment) is a fixed payment amount made by a borrower to a lender at a specified date each calendar month.",
        suggestions: getFollowUpSuggestions("personal_next_emi", language, isLeader)
      };
    }
    if (text.includes("subsidy")) {
      return {
        reply: isTelugu
          ? "సబ్సిడీ అనేది ప్రభుత్వం అందించే ఆర్థిక సహాయం లేదా గ్రాంట్."
          : "A subsidy is financial assistance or grant provided by the government to support SHG members.",
        suggestions: getFollowUpSuggestions("personal_subsidy_total", language, isLeader)
      };
    }
    return {
      reply: isTelugu
        ? "నేను మీ రుణం, ఈఎంఐ, సబ్సిడీ మరియు ఖాతా వివరాల గురించి సహాయం చేయగలను."
        : "I can help you with questions about your loans, EMIs, subsidies, transactions, and account summary.",
      suggestions: getFollowUpSuggestions("general", language, isLeader)
    };
  }

  // --- GROUP INTENTS ---
  if (intent.startsWith("group_")) {
    if (data && data.isMemberRestricted) {
      return {
        reply: isTelugu
          ? `గ్రూప్ సభ్యురాలిగా, మీరు మీ వ్యక్తిగత ఖాతా వివరాలను వీక్షించవచ్చు. మీ గ్రూప్ (${user.groupId}) నందు 10 మంది క్రియాశీల సభ్యులు ఉన్నారు. వివరమైన గ్రూప్ ఆర్థిక నివేదికలు ప్రెసిడెంట్ లేదా సెక్రటరీకి అందుబాటులో ఉంటాయి.`
          : `As a group member, you can view your personal account summary. Your group (${user.groupId}) has 10 active members. Group-wide financial summaries are available to group leaders (President/Secretary).`,
        suggestions: getFollowUpSuggestions("personal_loan_total", language, false)
      };
    }

    const grp = data || {};

    // Fixed Group Subsidy Total Intent
    if (intent === "group_subsidy_total") {
      const totalSub = grp.totalAmount || 0;
      const count = grp.count || 0;
      return {
        reply: isTelugu
          ? `మీ గ్రూప్ (${user.groupId}) ఇప్పటివరకు మొత్తం ₹${totalSub.toLocaleString('en-IN')} సబ్సిడీ పొందడమైనది (మొత్తం ${count} సబ్సిడీ గ్రాంట్‌లు).`
          : `Your group (${user.groupId}) has received a total subsidy of ₹${totalSub.toLocaleString('en-IN')} across ${count} member subsidy record(s).`,
        suggestions: getFollowUpSuggestions("group_subsidy_total", language, true)
      };
    }

    // Group Subsidy Member Breakdown
    if (intent === "group_subsidy_members") {
      const list = grp.subsidies || [];
      if (list.length === 0) {
        return {
          reply: isTelugu ? "మీ గ్రూప్‌లో ఎవరికీ సబ్సిడీ లభించలేదు." : "No member subsidy records found for your group.",
          suggestions: getFollowUpSuggestions("group_subsidy_total", language, true)
        };
      }
      const details = list.map(s => `${s.memberId}: ₹${(s.amount || 0).toLocaleString('en-IN')} (${s.schemeName || 'Subsidy'})`).join("\n");
      return {
        reply: (isTelugu ? `గ్రూప్ (${user.groupId}) సబ్సిడీ వివరాలు:\n` : `Member Subsidy Breakdown for group ${user.groupId}:\n`) + details,
        suggestions: getFollowUpSuggestions("group_subsidy_total", language, true)
      };
    }

    if (intent === "group_members_count") {
      return {
        reply: isTelugu
          ? `మీ గ్రూప్ (${user.groupId}) నందు మొత్తం ${grp.totalMembers || 10} మంది క్రియాశీల సభ్యులు ఉన్నారు. (ప్రెసిడెంట్: ${grp.president ? grp.president.name : 'N/A'}, సెక్రటరీ: ${grp.secretary ? grp.secretary.name : 'N/A'}).`
          : `Your group (${user.groupId}) has ${grp.totalMembers || 10} active members. (President: ${grp.president ? grp.president.name : 'N/A'}, Secretary: ${grp.secretary ? grp.secretary.name : 'N/A'}).`,
        suggestions: getFollowUpSuggestions("group_summary", language, true)
      };
    }

    if (intent === "group_loan_total") {
      return {
        reply: isTelugu
          ? `మీ గ్రూప్ (${user.groupId}) మొత్తం రుణ ప్రిన్సిపల్ ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}. చెల్లించినది ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}, మిగిలిన బకాయి ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}.`
          : `Your group (${user.groupId}) total loan principal is ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}. Total paid: ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}, Remaining balance: ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}.`,
        suggestions: getFollowUpSuggestions("group_summary", language, true)
      };
    }

    if (intent === "group_paid_total") {
      return {
        reply: isTelugu
          ? `మీ గ్రూప్ (${user.groupId}) చెల్లించిన మొత్తం రుణ చెల్లింపులు ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}.`
          : `Your group (${user.groupId}) has paid a total of ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')} towards loans.`,
        suggestions: getFollowUpSuggestions("group_summary", language, true)
      };
    }

    if (intent === "group_outstanding_total") {
      return {
        reply: isTelugu
          ? `మీ గ్రూప్ (${user.groupId}) మిగిలిన రుణ బకాయి ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}.`
          : `Your group (${user.groupId}) total outstanding loan balance is ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}.`,
        suggestions: getFollowUpSuggestions("group_summary", language, true)
      };
    }

    if (intent === "group_overdue_members") {
      const overdueMembers = (grp.memberSummaries || []).filter(m => m.hasOverdueEmi);
      if (overdueMembers.length === 0) {
        return {
          reply: isTelugu
            ? `మీ గ్రూప్‌లో ఎవరికీ ఓవర్‌డ్యూ ఈఎంఐ బకాయిలు లేవు.`
            : `None of the members in your group (${user.groupId}) have overdue EMIs.`,
          suggestions: getFollowUpSuggestions("group_summary", language, true)
        };
      }
      const names = overdueMembers.map(m => `${m.name} (${m.userId})`).join(", ");
      return {
        reply: isTelugu
          ? `మీ గ్రూప్‌లో క్రింది సభ్యులకు ఓవర్‌డ్యూ ఈఎంఐలు ఉన్నాయి: ${names}.`
          : `The following member(s) in your group (${user.groupId}) have overdue EMIs: ${names}.`,
        suggestions: getFollowUpSuggestions("group_summary", language, true)
      };
    }

    return {
      reply: isTelugu
        ? `గ్రూప్ నివేదిక (${user.groupId}):\n• మొత్తం సభ్యులు: ${grp.totalMembers || 10}\n• మొత్తం రుణం: ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}\n• చెల్లించినది: ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}\n• మిగిలిన బకాయి: ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}\n• ఓవర్‌డ్యూ ఈఎంఐలు: ${grp.overdueGroupEmisCount || 0}\n• మొత్తం సబ్సిడీ: ₹${(grp.totalGroupSubsidyAmount || 0).toLocaleString('en-IN')}`
        : `Group Summary for ${user.groupId}:\n• Total Members: ${grp.totalMembers || 10}\n• Total Loan Principal: ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}\n• Total Paid: ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}\n• Remaining Balance: ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}\n• Overdue EMIs: ${grp.overdueGroupEmisCount || 0}\n• Total Subsidy Received: ₹${(grp.totalGroupSubsidyAmount || 0).toLocaleString('en-IN')}`,
      suggestions: getFollowUpSuggestions("group_summary", language, true)
    };
  }

  // --- PERSONAL INTENTS ---

  if (intent === "personal_account_summary") {
    const acc = data || {};
    const loanSum = acc.loanSummary || {};
    return {
      reply: isTelugu
        ? `ఖాతా సారాంశం (${user.name}):\n• మొత్తం రుణం: ₹${(loanSum.totalPrincipal || 0).toLocaleString('en-IN')}\n• చెల్లించినది: ₹${(loanSum.totalPaid || 0).toLocaleString('en-IN')}\n• మిగిలిన బకాయి: ₹${(loanSum.remainingBalance || 0).toLocaleString('en-IN')}`
        : `Account Summary for ${user.name} (${user.userId}):\n• Total Loan Principal: ₹${(loanSum.totalPrincipal || 0).toLocaleString('en-IN')}\n• Total Paid: ₹${(loanSum.totalPaid || 0).toLocaleString('en-IN')}\n• Remaining Balance: ₹${(loanSum.remainingBalance || 0).toLocaleString('en-IN')}\n• Active Loans: ${loanSum.activeLoanCount || 0}`,
      suggestions: getFollowUpSuggestions("personal_loan_remaining", language, false)
    };
  }

  if (intent === "personal_loan_total") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans) {
      return {
        reply: isTelugu ? "మీ ఖాతా కోసం ఎటువంటి రుణ రికార్డులు కనుగొనబడలేదు." : "No loan records found for your account.",
        suggestions: getFollowUpSuggestions("personal_loan_total", language, false)
      };
    }
    return {
      reply: isTelugu
        ? `మీ మొత్తం రుణ ప్రిన్సిపల్ ₹${loanSummary.totalPrincipal.toLocaleString('en-IN')}.`
        : `Your total loan principal is ₹${loanSummary.totalPrincipal.toLocaleString('en-IN')}.`,
      suggestions: getFollowUpSuggestions("personal_loan_total", language, false)
    };
  }

  if (intent === "personal_loan_paid") {
    const loanSummary = data || {};
    return {
      reply: isTelugu
        ? `మీరు ఇప్పటివరకు చెల్లించిన మొత్తం రుణ చెల్లింపులు ₹${loanSummary.totalPaid.toLocaleString('en-IN')}.`
        : `You have paid a total of ₹${loanSummary.totalPaid.toLocaleString('en-IN')} towards your loan.`,
      suggestions: getFollowUpSuggestions("personal_loan_paid", language, false)
    };
  }

  if (intent === "personal_loan_remaining") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans || loanSummary.activeLoanCount === 0) {
      return {
        reply: isTelugu ? "మీకు ఎటువంటి మిగిలిన రుణ బకాయి లేదు." : "You do not have any remaining loan balance.",
        suggestions: getFollowUpSuggestions("personal_loan_remaining", language, false)
      };
    }
    const explanation = isTelugu
      ? ` (మొత్తం ప్రిన్సిపల్: ₹${loanSummary.totalPrincipal.toLocaleString('en-IN')}, చెల్లించినది: ₹${loanSummary.totalPaid.toLocaleString('en-IN')}).`
      : ` (Original Loan: ₹${loanSummary.totalPrincipal.toLocaleString('en-IN')}, Total Paid: ₹${loanSummary.totalPaid.toLocaleString('en-IN')}).`;

    return {
      reply: isTelugu
        ? `మీ మిగిలిన రుణ బకాయి ₹${loanSummary.remainingBalance.toLocaleString('en-IN')}.${explanation}`
        : `Your remaining loan balance is ₹${loanSummary.remainingBalance.toLocaleString('en-IN')}.${explanation}`,
      suggestions: getFollowUpSuggestions("personal_loan_remaining", language, false)
    };
  }

  if (intent === "personal_active_loans") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans || loanSummary.activeLoanCount === 0) {
      return {
        reply: isTelugu ? "మీకు ఎటువంటి క్రియాశీల రుణాలు లేవు." : "You don't have any active loans.",
        suggestions: getFollowUpSuggestions("personal_loan_total", language, false)
      };
    }
    const loanDetails = loanSummary.activeLoans
      .map(l => `${l.loanType || 'Loan'} (${l.loanId}): ₹${(l.principalAmount || 0).toLocaleString('en-IN')} [${l.status}]`)
      .join("\n");

    return {
      reply: (isTelugu ? `మీకు ${loanSummary.activeLoanCount} క్రియాశీల రుణాలు ఉన్నాయి:\n` : `You have ${loanSummary.activeLoanCount} active loan(s):\n`) + loanDetails,
      suggestions: getFollowUpSuggestions("personal_loan_total", language, false)
    };
  }

  // Personal EMI Intents
  if (["personal_next_emi", "personal_emi_amount", "personal_overdue_emi", "personal_emi_summary"].includes(intent)) {
    const emiSummary = data || {};
    if (!emiSummary.hasEmis || emiSummary.unpaidEmisCount === 0) {
      return {
        reply: isTelugu ? "మీకు ప్రస్తుతం పెండింగ్ ఈఎంఐలు లేవు." : "You don't have any pending EMIs at the moment.",
        suggestions: getFollowUpSuggestions("personal_next_emi", language, false)
      };
    }

    const nextUpcoming = emiSummary.nextUpcomingEmi;
    const primaryOverdue = emiSummary.primaryOverdueEmi;

    if (intent === "personal_overdue_emi") {
      if (emiSummary.overdueEmisCount > 0 && primaryOverdue) {
        return {
          reply: isTelugu
            ? `అవును, మీకు ₹${primaryOverdue.amount.toLocaleString('en-IN')} ఓవర్‌డ్యూ ఈఎంఐ బకాయి ఉంది, గడువు తేదీ ${formatDate(primaryOverdue.dueDate)}.`
            : `Yes, you have an overdue EMI of ₹${primaryOverdue.amount.toLocaleString('en-IN')}, which was due on ${formatDate(primaryOverdue.dueDate)}.`,
          suggestions: getFollowUpSuggestions("personal_next_emi", language, false)
        };
      } else {
        return {
          reply: isTelugu ? "మీకు ఎటువంటి ఓవర్‌డ్యూ ఈఎంఐ బకాయిలు లేవు." : "No, you do not have any overdue EMIs at the moment.",
          suggestions: getFollowUpSuggestions("personal_next_emi", language, false)
        };
      }
    }

    if (intent === "personal_emi_amount") {
      const primary = nextUpcoming || primaryOverdue;
      const amt = primary ? primary.amount : 0;
      return {
        reply: isTelugu ? `మీ ఈఎంఐ మొత్తం ₹${amt.toLocaleString('en-IN')}.` : `Your EMI installment amount is ₹${amt.toLocaleString('en-IN')}.`,
        suggestions: getFollowUpSuggestions("personal_next_emi", language, false)
      };
    }

    if (nextUpcoming) {
      const amt = nextUpcoming.amount || 0;
      const due = formatDate(nextUpcoming.dueDate);
      let reply = isTelugu ? `మీ తదుపరి ఈఎంఐ ₹${amt.toLocaleString('en-IN')}, గడువు తేదీ ${due}.` : `Your next EMI is ₹${amt.toLocaleString('en-IN')}, due on ${due}.`;

      if (emiSummary.overdueEmisCount > 0 && primaryOverdue) {
        reply += isTelugu
          ? ` (గమనిక: మీకు ${formatDate(primaryOverdue.dueDate)}న బకాయి ఉన్న ₹${primaryOverdue.amount.toLocaleString('en-IN')} ఈఎంఐ కూడా ఉంది).`
          : ` (Note: You also have an overdue EMI of ₹${primaryOverdue.amount.toLocaleString('en-IN')} due on ${formatDate(primaryOverdue.dueDate)}).`;
      }
      return { reply, suggestions: getFollowUpSuggestions("personal_next_emi", language, false) };
    } else if (primaryOverdue) {
      const amt = primaryOverdue.amount || 0;
      const due = formatDate(primaryOverdue.dueDate);
      return {
        reply: isTelugu
          ? `మీకు ₹${amt.toLocaleString('en-IN')} బకాయి (ఓవర్‌డ్యూ) ఈఎంఐ ఉంది, గడువు తేదీ ${due}.`
          : `You have an overdue EMI of ₹${amt.toLocaleString('en-IN')}, which was due on ${due}.`,
        suggestions: getFollowUpSuggestions("personal_next_emi", language, false)
      };
    }
  }

  // Personal Transactions
  if (intent === "personal_transaction_history" || intent === "personal_last_payment") {
    const txSummary = data || {};
    if (!txSummary.hasTransactions) {
      return {
        reply: isTelugu ? "ఇటీవలి చెల్లింపు లావాదేవీలు ఏవీ లేవు." : "No recent payment transactions found.",
        suggestions: getFollowUpSuggestions("personal_loan_paid", language, false)
      };
    }

    if (intent === "personal_last_payment" && txSummary.transactions.length > 0) {
      const lastTx = txSummary.transactions[0];
      return {
        reply: isTelugu
          ? `మీ చివరి చెల్లింపు ₹${lastTx.amount.toLocaleString('en-IN')} తేది ${formatDate(lastTx.paymentDate || lastTx.createdAt)}న విజయవంతంగా పూర్తయింది. (Transaction ID: ${lastTx.transactionId}).`
          : `Your last payment was ₹${lastTx.amount.toLocaleString('en-IN')} made on ${formatDate(lastTx.paymentDate || lastTx.createdAt)}. (Transaction ID: ${lastTx.transactionId}).`,
        suggestions: getFollowUpSuggestions("personal_loan_paid", language, false)
      };
    }

    const txList = txSummary.transactions
      .map(t => `${formatDate(t.paymentDate || t.createdAt)}: ₹${t.amount} (${t.notes || t.type}) [${t.transactionId}]`)
      .join("\n");

    return {
      reply: (isTelugu ? "ఇటీవలి చెల్లింపులు:\n" : "Recent payment history:\n") + txList,
      suggestions: getFollowUpSuggestions("personal_loan_paid", language, false)
    };
  }

  // Personal Subsidies
  if (intent === "personal_subsidy_total" || intent === "personal_subsidy_history") {
    const subSummary = data || {};
    if (!subSummary.hasSubsidies) {
      return {
        reply: isTelugu ? "మీ ఖాతా కోసం ఎటువంటి సబ్సిడీ రికార్డులు కనుగొనబడలేదు." : "No subsidy records found for your account.",
        suggestions: getFollowUpSuggestions("personal_subsidy_total", language, false)
      };
    }
    const subList = subSummary.subsidies
      .map(s => `• ${s.schemeName || 'Subsidy'}: ₹${s.amount.toLocaleString('en-IN')} [${s.status}]`)
      .join("\n");

    return {
      reply: (isTelugu ? `మొత్తం సబ్సిడీ: ₹${subSummary.totalAmount.toLocaleString('en-IN')}\nలభించిన సబ్సిడీలు:\n` : `Total Subsidy Received: ₹${subSummary.totalAmount.toLocaleString('en-IN')}\nSubsidy Records:\n`) + subList,
      suggestions: getFollowUpSuggestions("personal_subsidy_total", language, false)
    };
  }

  // Personal Notifications
  if (intent === "personal_notifications") {
    const notifSummary = data || {};
    if (!notifSummary.hasNotifications) {
      return {
        reply: isTelugu ? "నోటిఫికేషన్లు ఏవీ లేవు." : "No notifications found.",
        suggestions: getFollowUpSuggestions("general", language, isLeader)
      };
    }
    const notifList = notifSummary.notifications.map(n => `• ${n.title}: ${n.message}`).join("\n");
    return {
      reply: (isTelugu ? "ఇటీవలి నోటిఫికేషన్లు:\n" : "Recent notifications:\n") + notifList,
      suggestions: getFollowUpSuggestions("general", language, isLeader)
    };
  }

  if (intent === "personal_profile") {
    return {
      reply: isTelugu
        ? `పేరు: ${user.name}\nID: ${user.userId}\nగ్రూప్: ${user.groupId}\nరోల్: ${user.position}`
        : `Name: ${user.name}\nID: ${user.userId}\nGroup: ${user.groupId}\nPosition: ${user.position}`,
      suggestions: getFollowUpSuggestions("general", language, isLeader)
    };
  }

  if (intent === "personal_group_id") {
    return {
      reply: isTelugu ? `మీ గ్రూప్ ఐడి ${user.groupId}.` : `Your Group ID is ${user.groupId}.`,
      suggestions: getFollowUpSuggestions("general", language, isLeader)
    };
  }

  return {
    reply: isTelugu
      ? "నేను మీకు మీ రుణం, ఈఎంఐ, చెల్లింపులు, సబ్సిడీలు, నోటిఫికేషన్లు మరియు ప్రొఫైల్ వివరాల గురించి సహాయం చేయగలను."
      : "I can help you with your loan, EMI, payments, subsidies, transactions, notifications, and profile.",
    suggestions: getFollowUpSuggestions("general", language, isLeader)
  };
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

    // Retrieve previous conversation context for multi-turn support
    const prevContext = getStoredContext(user.userId);
    const intent = detectIntent(message, prevContext);

    if (intent !== "unknown") {
      const dbStart = Date.now();
      const data = await fetchDataForIntent(intent, user);
      const dbQueryMs = Date.now() - dbStart;

      let recordCount = 0;
      if (data) {
        if (data.loans && Array.isArray(data.loans)) recordCount = data.loans.length;
        else if (data.emis && Array.isArray(data.emis)) recordCount = data.emis.length;
        else if (data.subsidies && Array.isArray(data.subsidies)) recordCount = data.subsidies.length;
        else if (data.transactions && Array.isArray(data.transactions)) recordCount = data.transactions.length;
        else if (data.notifications && Array.isArray(data.notifications)) recordCount = data.notifications.length;
        else if (typeof data === "object") recordCount = 1;
      }

      const constructed = constructResponse(intent, data, language, user, message);
      const totalMs = Date.now() - startTime;

      // Update short-term conversation context for multi-turn follow-ups
      const scope = intent.startsWith("group_") ? "group" : "personal";
      updateStoredContext(user.userId, intent, scope);

      if (process.env.NODE_ENV !== "production") {
        console.log(`[CHAT DEBUG] message    : "${message}"`);
        console.log(`[CHAT DEBUG] userId     : ${user.userId}`);
        console.log(`[CHAT DEBUG] groupId    : ${user.groupId}`);
        console.log(`[CHAT DEBUG] role       : ${user.role}`);
        console.log(`[CHAT DEBUG] intent     : ${intent}`);
        console.log(`[CHAT DEBUG] recordCount: ${recordCount}`);
        console.log(`[CHAT DEBUG] queryMs    : ${dbQueryMs} ms | totalMs: ${totalMs} ms`);
      }

      return {
        reply: constructed.reply,
        suggestions: constructed.suggestions,
        language,
        intent,
        dataSource: "database"
      };
    }

    // Optional AI fallback for non-account general questions
    const aiReply = await createAiReply(message, { name: user.name, role: user.role });
    if (aiReply) {
      return {
        reply: aiReply,
        suggestions: getFollowUpSuggestions("general", language, user.role === "leader"),
        language,
        intent: "ai_fallback",
        dataSource: "ai"
      };
    }

    // Standard friendly fallback response when query is unrecognized and no AI key configured
    const constructed = constructResponse("unknown", null, language, user, message);
    return {
      reply: constructed.reply,
      suggestions: constructed.suggestions,
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
