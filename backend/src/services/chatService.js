const OpenAI = require("openai");
const User = require("../models/User");
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

  // 1. Group Specific Queries
  if (hasAny(text, [
    /how many members.*group/,
    /members.*in.*group/,
    /group lo enni members/,
    /group members count/,
    /గ్రూప్‌లో ఎంతమంది సభ్యులు/
  ])) return "group_members_count";

  if (hasAny(text, [
    /group total loan/,
    /how much loan.*our group/,
    /group loan amount/,
    /group loan entha/
  ])) return "group_loan_total";

  if (hasAny(text, [
    /group overdue/,
    /which members.*overdue/,
    /members.*overdue/,
    /group lo overdue members/
  ])) return "group_overdue_members";

  if (hasAny(text, [
    /group summary/,
    /group details/,
    /tell me about my group/,
    /our group/
  ])) return "group_summary";

  // 2. General Questions & Capabilities
  if (hasAny(text, [
    /what can you (do|help)/,
    /help me with/,
    /explain.*emi/,
    /what is.*emi/,
    /explain.*subsidy/,
    /what is.*subsidy/
  ])) return "general_question";

  // 3. Paid Amount
  if (hasAny(text, [
    /how much.*paid/,
    /total paid/,
    /nenu entha pay/,
    /paid amount/,
    /payment completed/
  ])) return "paid_amount";

  // 4. Loan Balance / Remaining
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
  ])) return "loan_balance";

  // 5. Loan Total (strict total loan queries)
  if (hasAny(text, [
    /\btotal loan\b/,
    /\bloan amount\b/,
    /what is my total loan/,
    /how much loan do i have/,
    /my total loan/,
    /my loan amount/,
    /how much did i borrow/,
    /మొత్తం రుణం/,
    /naa total loan/
  ])) return "loan_total";

  // 6. Active Loans
  if (hasAny(text, [
    /active loan/,
    /my active loans/,
    /show.*active loans/,
    /which.*loans.*active/,
    /list.*active loans/,
    /ప్రస్తుత రుణాలు/
  ]) && !text.includes("total") && !text.includes("balance") && !text.includes("remaining")) return "active_loans";

  // 7. Overdue EMI
  if (hasAny(text, [
    /overdue/,
    /is my emi overdue/,
    /pending emi overdue/,
    /ఓవర్‌డ్యూ/
  ])) return "overdue_emi";

  // 8. Next EMI / EMI Due Date
  if (hasAny(text, [
    /next emi/,
    /when is the next one/,
    /emi (due|date|when)/,
    /when is my emi/,
    /when is emi due/,
    /తదుపరి ఈఎంఐ/,
    /గడువు తేదీ/,
    /emi eppudu/,
    /next installment/
  ])) return "next_emi";

  // 9. EMI Amount
  if (hasAny(text, [
    /how much.*emi/,
    /emi amount/,
    /ఈఎంఐ మొత్తం/,
    /emi entha/,
    /naa emi entha/
  ])) return "emi_amount";

  // 10. Account Overview
  if (hasAny(text, [
    /tell me about my account/,
    /account summary/,
    /account details/,
    /my account/
  ])) return "account_overview";

  // 11. Transactions / Payment History
  if (hasAny(text, [
    /transaction/,
    /payment history/,
    /show.*transaction/,
    /show.*payment/,
    /recent payment/,
    /last payment/,
    /లావాదేవీలు/,
    /naa transactions/
  ])) return "transactions";

  // 12. Subsidies
  if (hasAny(text, [
    /subsid(y|ies)/,
    /సబ్సిడీ/,
    /show.*subsid/,
    /naa subsidy/
  ])) return "subsidies";

  // 13. Notifications
  if (hasAny(text, [
    /notification/,
    /alert/,
    /reminder/,
    /నోటిఫికేషన్లు/,
    /show.*notification/
  ])) return "notifications";

  // 14. Profile
  if (hasAny(text, [
    /who am i/,
    /profile/,
    /my detail/,
    /naa profile/,
    /naa detail/,
    /ప్రొఫైల్/
  ])) return "profile";

  // 15. Group ID
  if (hasAny(text, [
    /group id/,
    /group number/,
    /గ్రూప్ ఐడి/
  ])) return "group_id";

  // 16. Greetings
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
    case "group_members_count":
    case "group_loan_total":
    case "group_overdue_members":
    case "group_summary": {
      if (user.role === "leader" || ["president", "secretary"].includes(user.position)) {
        return await getGroupSummary(user.groupId);
      }
      return { isMemberRestricted: true };
    }

    case "loan_total":
    case "paid_amount":
    case "loan_balance":
    case "active_loans": {
      return await getMyLoanSummary(user.userId, user.groupId, user.role);
    }

    case "next_emi":
    case "emi_amount":
    case "emi_due_date":
    case "emi_details":
    case "overdue_emi": {
      return await getMyEmiSummary(user.userId, user.groupId, user.role);
    }

    case "account_overview": {
      return await getMyAccountSummary(user.userId, user.groupId, user.role);
    }

    case "transactions": {
      return await getMyTransactionSummary(user.userId, user.groupId, user.role, 10);
    }

    case "subsidies": {
      return await getMySubsidySummary(user.userId, user.groupId, user.role);
    }

    case "notifications": {
      return await getMyNotificationSummary(user.userId, user.groupId, user.role, 10);
    }

    case "profile":
    case "group_id":
      return user;

    default:
      return null;
  }
};

const getFollowUpSuggestions = (intent, language) => {
  const isTelugu = language === "te" || language === "te-en";

  switch (intent) {
    case "group_summary":
    case "group_loan_total":
    case "group_members_count":
      return isTelugu
        ? ["గ్రూప్ లో ఎంతమంది సభ్యులు ఉన్నారు?", "గ్రూప్ లో ఓవర్‌డ్యూ ఉన్నవారెవరు?", "నా వ్యక్తిగత రుణ వివరాలు"]
        : ["How many members are in my group?", "Which members have overdue EMIs?", "Show my personal account summary"];

    case "loan_total":
    case "loan_balance":
    case "paid_amount":
      return isTelugu
        ? ["తదుపరి ఈఎంఐ ఎప్పుడు?", "నా చెల్లింపుల చరిత్ర చూపించు", "ఓవర్‌డ్యూ ఈఎంఐ ఏమైనా ఉందా?"]
        : ["When is my next EMI?", "How much have I paid?", "Show my recent transactions"];

    case "next_emi":
    case "emi_amount":
    case "overdue_emi":
      return isTelugu
        ? ["నాకు ఇంకా ఎంత రుణం బకాయి ఉంది?", "నా చెల్లింపుల చరిత్ర చూపించు", "నా ప్రొఫైల్ వివరాలు"]
        : ["How much loan do I have left?", "Show my transactions", "Do I have any subsidies?"];

    default:
      return isTelugu
        ? ["మొత్తం రుణం ఎంత?", "తదుపరి ఈఎంఐ ఎప్పుడు?", "మిగిలిన రుణం ఎంత?"]
        : ["What is my total loan?", "When is my next EMI?", "How much loan do I have left?"];
  }
};

const constructResponse = (intent, data, language, user, rawMessage = "") => {
  const isTelugu = language === "te" || language === "te-en";

  if (intent === "greeting") {
    return {
      reply: isTelugu
        ? "నమస్తే! నేను మీ డిడబ్ల్యూసిఆర్‌ఎ సహాయకుడిని. మీ రుణం, ఈఎంఐ, చెల్లింపులు, సబ్సిడీలు మరియు ప్రొఫైల్ వివరాల గురించి సహాయం చేయగలను."
        : "Hello! I am your DWCRA Connect AI Assistant. I can help you with your loan, EMI, payments, subsidies, transactions, notifications, and profile.",
      suggestions: getFollowUpSuggestions("greeting", language)
    };
  }

  // Group Intents
  if (["group_members_count", "group_loan_total", "group_overdue_members", "group_summary"].includes(intent)) {
    if (data && data.isMemberRestricted) {
      return {
        reply: isTelugu
          ? `గ్రూప్ సభ్యురాలిగా, మీరు మీ వ్యక్తిగత ఖాతా వివరాలను వీక్షించవచ్చు. మీ గ్రూప్ (${user.groupId}) నందు 10 మంది క్రియాశీల సభ్యులు ఉన్నారు.`
          : `As a group member, you can view your personal account summary. Your group (${user.groupId}) has 10 active members. Group-wide financial summaries are available to group leaders (President/Secretary).`,
        suggestions: getFollowUpSuggestions("loan_total", language)
      };
    }

    const grp = data || {};
    if (intent === "group_members_count") {
      return {
        reply: isTelugu
          ? `మీ గ్రూప్ (${user.groupId}) నందు మొత్తం ${grp.totalMembers || 10} మంది క్రియాశీల సభ్యులు ఉన్నారు. (ప్రెసిడెంట్: ${grp.president ? grp.president.name : 'N/A'}, సెక్రటరీ: ${grp.secretary ? grp.secretary.name : 'N/A'}).`
          : `Your group (${user.groupId}) has ${grp.totalMembers || 10} active members. (President: ${grp.president ? grp.president.name : 'N/A'}, Secretary: ${grp.secretary ? grp.secretary.name : 'N/A'}).`,
        suggestions: getFollowUpSuggestions("group_summary", language)
      };
    }

    if (intent === "group_loan_total") {
      return {
        reply: isTelugu
          ? `మీ గ్రూప్ (${user.groupId}) మొత్తం రుణ ప్రిన్సిపల్ ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}, చెల్లించినది ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}, మిగిలిన బకాయి ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}.`
          : `Your group (${user.groupId}) total loan principal is ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}. Total paid: ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}, Remaining balance: ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}.`,
        suggestions: getFollowUpSuggestions("group_summary", language)
      };
    }

    if (intent === "group_overdue_members") {
      const overdueMembers = (grp.memberSummaries || []).filter(m => m.hasOverdueEmi);
      if (overdueMembers.length === 0) {
        return {
          reply: isTelugu
            ? `మీ గ్రూప్‌లో ఎవరికీ ఓవర్‌డ్యూ ఈఎంఐ బకాయిలు లేవు.`
            : `None of the members in your group (${user.groupId}) have overdue EMIs.`,
          suggestions: getFollowUpSuggestions("group_summary", language)
        };
      }
      const names = overdueMembers.map(m => `${m.name} (${m.userId})`).join(", ");
      return {
        reply: isTelugu
          ? `మీ గ్రూప్‌లో క్రింది సభ్యులకు ఓవర్‌డ్యూ ఈఎంఐలు ఉన్నాయి: ${names}.`
          : `The following member(s) in your group (${user.groupId}) have overdue EMIs: ${names}.`,
        suggestions: getFollowUpSuggestions("group_summary", language)
      };
    }

    return {
      reply: isTelugu
        ? `గ్రూప్ వివరాలు (${user.groupId}):\n- మొత్తం సభ్యులు: ${grp.totalMembers || 10}\n- మొత్తం రుణం: ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}\n- చెల్లించినది: ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}\n- మిగిలిన బకాయి: ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}\n- ఓవర్‌డ్యూ ఈఎంఐలు: ${grp.overdueGroupEmisCount || 0}`
        : `Group Overview for ${user.groupId}:\n• Total Members: ${grp.totalMembers || 10}\n• Total Loan Principal: ₹${(grp.totalGroupPrincipal || 0).toLocaleString('en-IN')}\n• Total Paid: ₹${(grp.totalGroupPaid || 0).toLocaleString('en-IN')}\n• Remaining Balance: ₹${(grp.totalGroupRemaining || 0).toLocaleString('en-IN')}\n• Overdue EMIs: ${grp.overdueGroupEmisCount || 0}`,
      suggestions: getFollowUpSuggestions("group_summary", language)
    };
  }

  if (intent === "general_question") {
    const text = rawMessage.toLowerCase();
    if (text.includes("emi")) {
      return {
        reply: isTelugu
          ? "ఈఎంఐ (EMI - Equated Monthly Installment) అనేది ప్రతి నెలా మీరు చెల్లించాల్సిన స్థిరమైన వాయిదా మొత్తం."
          : "An EMI (Equated Monthly Installment) is a fixed payment amount made by a borrower to a lender at a specified date each calendar month.",
        suggestions: getFollowUpSuggestions("next_emi", language)
      };
    }
    if (text.includes("subsidy")) {
      return {
        reply: isTelugu
          ? "సబ్సిడీ అనేది ప్రభుత్వం అందించే ఆర్థిక సహాయం లేదా గ్రాంట్."
          : "A subsidy is financial assistance or grant provided by the government to support SHG members.",
        suggestions: getFollowUpSuggestions("subsidies", language)
      };
    }
    return {
      reply: isTelugu
        ? "నేను మీ రుణం, ఈఎంఐ, సబ్సిడీ మరియు ఖాతా వివరాల గురించి సహాయం చేయగలను."
        : "I can help you with questions about your loans, EMIs, subsidies, transactions, and account summary.",
      suggestions: getFollowUpSuggestions("general", language)
    };
  }

  // Account Overview
  if (intent === "account_overview") {
    const acc = data || {};
    const loanSum = acc.loanSummary || {};
    return {
      reply: isTelugu
        ? `ఖాతా సారాంశం (${user.name}):\n- మొత్తం రుణం: ₹${(loanSum.totalPrincipal || 0).toLocaleString('en-IN')}\n- చెల్లించినది: ₹${(loanSum.totalPaid || 0).toLocaleString('en-IN')}\n- మిగిలిన బకాయి: ₹${(loanSum.remainingBalance || 0).toLocaleString('en-IN')}`
        : `Account Summary for ${user.name} (${user.userId}):\n• Total Loan: ₹${(loanSum.totalPrincipal || 0).toLocaleString('en-IN')}\n• Total Paid: ₹${(loanSum.totalPaid || 0).toLocaleString('en-IN')}\n• Remaining Balance: ₹${(loanSum.remainingBalance || 0).toLocaleString('en-IN')}\n• Active Loans: ${loanSum.activeLoanCount || 0}`,
      suggestions: getFollowUpSuggestions("loan_balance", language)
    };
  }

  // EMI Intents
  if (["next_emi", "emi_amount", "emi_due_date", "emi_details", "overdue_emi"].includes(intent)) {
    const emiSummary = data || {};
    if (!emiSummary.hasEmis || emiSummary.unpaidEmisCount === 0) {
      return {
        reply: isTelugu ? "మీకు లేదా మీ గ్రూప్ కి ప్రస్తుతం పెండింగ్ ఈఎంఐలు లేవు." : "You don't have any pending EMIs at the moment.",
        suggestions: getFollowUpSuggestions("next_emi", language)
      };
    }

    const nextUpcoming = emiSummary.nextUpcomingEmi;
    const primaryOverdue = emiSummary.primaryOverdueEmi;

    if (intent === "overdue_emi") {
      if (emiSummary.overdueEmisCount > 0 && primaryOverdue) {
        return {
          reply: isTelugu
            ? `అవును, మీకు ₹${primaryOverdue.amount.toLocaleString('en-IN')} ఓవర్‌డ్యూ ఈఎంఐ బకాయి ఉంది, గడువు తేదీ ${formatDate(primaryOverdue.dueDate)}.`
            : `Yes, you have an overdue EMI of ₹${primaryOverdue.amount.toLocaleString('en-IN')}, which was due on ${formatDate(primaryOverdue.dueDate)}.`,
          suggestions: getFollowUpSuggestions("next_emi", language)
        };
      } else {
        return {
          reply: isTelugu
            ? "మీకు ఎటువంటి ఓవర్‌డ్యూ ఈఎంఐ బకాయిలు లేవు."
            : "No, you do not have any overdue EMIs at the moment.",
          suggestions: getFollowUpSuggestions("next_emi", language)
        };
      }
    }

    if (intent === "emi_amount") {
      const primary = nextUpcoming || primaryOverdue;
      const amt = primary ? primary.amount : 0;
      return {
        reply: isTelugu
          ? `మీ ఈఎంఐ మొత్తం ₹${amt.toLocaleString('en-IN')}.`
          : `Your EMI amount is ₹${amt.toLocaleString('en-IN')}.`,
        suggestions: getFollowUpSuggestions("next_emi", language)
      };
    }

    if (nextUpcoming) {
      const amt = nextUpcoming.amount || 0;
      const due = formatDate(nextUpcoming.dueDate);
      const prefix = emiSummary.isGroupSummary
        ? (isTelugu ? `మీ గ్రూప్ (${user.groupId}) తదుపరి ఈఎంఐ` : `Your group (${user.groupId}) next EMI is`)
        : (isTelugu ? "మీ తదుపరి ఈఎంఐ" : "Your next EMI is");

      let reply = `${prefix} ₹${amt.toLocaleString('en-IN')}, due on ${due}.`;

      if (emiSummary.overdueEmisCount > 0 && primaryOverdue) {
        reply += isTelugu
          ? ` (గమనిక: మీకు ${formatDate(primaryOverdue.dueDate)}న బకాయి ఉన్న ₹${primaryOverdue.amount.toLocaleString('en-IN')} ఈఎంఐ కూడా ఉంది).`
          : ` (Note: You also have an overdue EMI of ₹${primaryOverdue.amount.toLocaleString('en-IN')} due on ${formatDate(primaryOverdue.dueDate)}).`;
      }
      return {
        reply,
        suggestions: getFollowUpSuggestions("next_emi", language)
      };
    } else if (primaryOverdue) {
      const amt = primaryOverdue.amount || 0;
      const due = formatDate(primaryOverdue.dueDate);
      return {
        reply: isTelugu
          ? `మీకు ₹${amt.toLocaleString('en-IN')} బకాయి (ఓవర్‌డ్యూ) ఈఎంఐ ఉంది, గడువు తేదీ ${due}.`
          : `You have an overdue EMI of ₹${amt.toLocaleString('en-IN')}, which was due on ${due}.`,
        suggestions: getFollowUpSuggestions("next_emi", language)
      };
    }
  }

  // Loan Intents
  if (intent === "loan_total") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans) {
      return {
        reply: isTelugu
          ? "మీ ఖాతా లేదా మీ గ్రూప్ కోసం ఎటువంటి రుణ రికార్డులు కనుగొనబడలేదు."
          : "I couldn't find any loan records for your account or group.",
        suggestions: getFollowUpSuggestions("loan_total", language)
      };
    }

    const prefix = loanSummary.isGroupSummary
      ? (isTelugu ? `మీ గ్రూప్ (${user.groupId}) మొత్తం రుణ మొత్తం` : `Your group (${user.groupId}) total loan amount is`)
      : (isTelugu ? "మీ మొత్తం రుణ మొత్తం" : "Your total loan amount is");

    return {
      reply: `${prefix} ₹${loanSummary.totalPrincipal.toLocaleString('en-IN')}.`,
      suggestions: getFollowUpSuggestions("loan_total", language)
    };
  }

  if (intent === "paid_amount") {
    const loanSummary = data || {};
    const prefix = loanSummary.isGroupSummary
      ? (isTelugu ? `మీ గ్రూప్ (${user.groupId}) చెల్లించిన మొత్తం` : `Your group (${user.groupId}) has paid a total of`)
      : (isTelugu ? "మీరు చెల్లించిన మొత్తం" : "You have paid a total of");

    return {
      reply: `${prefix} ₹${loanSummary.totalPaid.toLocaleString('en-IN')} towards loan payments.`,
      suggestions: getFollowUpSuggestions("paid_amount", language)
    };
  }

  if (intent === "loan_balance") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans || loanSummary.activeLoanCount === 0) {
      return {
        reply: isTelugu
          ? "మీకు లేదా మీ గ్రూప్ కి ఎటువంటి మిగిలిన రుణ బకాయి లేదు."
          : "You do not have any remaining loan balance.",
        suggestions: getFollowUpSuggestions("loan_balance", language)
      };
    }

    const prefix = loanSummary.isGroupSummary
      ? (isTelugu ? `మీ గ్రూప్ (${user.groupId}) మిగిలిన రుణ బకాయి` : `Your group (${user.groupId}) remaining loan balance is`)
      : (isTelugu ? "మీ మిగిలిన రుణ బకాయి" : "Your remaining loan balance is");

    const original = loanSummary.isGroupSummary ? loanSummary.totalPrincipal : loanSummary.activePrincipal;
    const explanation = isTelugu
      ? ` (మొత్తం ప్రిన్సిపల్: ₹${original.toLocaleString('en-IN')}, చెల్లించినది: ₹${loanSummary.totalPaid.toLocaleString('en-IN')}).`
      : ` (Original Loan: ₹${original.toLocaleString('en-IN')}, Total Paid: ₹${loanSummary.totalPaid.toLocaleString('en-IN')}).`;

    return {
      reply: `${prefix} ₹${loanSummary.remainingBalance.toLocaleString('en-IN')}.${explanation}`,
      suggestions: getFollowUpSuggestions("loan_balance", language)
    };
  }

  if (intent === "active_loans") {
    const loanSummary = data || {};
    if (!loanSummary.hasLoans || loanSummary.activeLoanCount === 0) {
      return {
        reply: isTelugu ? "మీకు ఎటువంటి క్రియాశీల రుణాలు లేవు." : "You don't have any active loans.",
        suggestions: getFollowUpSuggestions("active_loans", language)
      };
    }
    const loanCount = loanSummary.activeLoanCount;
    const loanDetails = loanSummary.activeLoans
      .map(l => `${l.loanType || 'Loan'} (${l.memberId}): ₹${(l.principalAmount || 0).toLocaleString('en-IN')} [${l.status}]`)
      .join("\n");

    const header = loanSummary.isGroupSummary
      ? (isTelugu ? `మీ గ్రూప్ (${user.groupId}) నందు ${loanCount} క్రియాశీల రుణాలు ఉన్నాయి:\n` : `Your group (${user.groupId}) has ${loanCount} active loan(s):\n`)
      : (isTelugu ? `మీకు ${loanCount} క్రియాశీల రుణాలు ఉన్నాయి:\n` : `You have ${loanCount} active loan(s):\n`);

    return {
      reply: header + loanDetails,
      suggestions: getFollowUpSuggestions("active_loans", language)
    };
  }

  // Transactions
  if (intent === "transactions") {
    const txSummary = data || {};
    if (!txSummary.hasTransactions) {
      return {
        reply: isTelugu ? "ఇటీవలి లావాదేవీలు ఏవీ లేవు." : "No recent transactions found.",
        suggestions: getFollowUpSuggestions("transactions", language)
      };
    }
    const txList = txSummary.transactions
      .map(t => `${formatDate(t.paymentDate || t.createdAt)}: ₹${t.amount} (${t.type || 'payment'})`)
      .join("\n");
    return {
      reply: (isTelugu ? "ఇటీవలి లావాదేవీలు:\n" : "Recent transactions:\n") + txList,
      suggestions: getFollowUpSuggestions("transactions", language)
    };
  }

  // Subsidies
  if (intent === "subsidies") {
    const subSummary = data || {};
    if (!subSummary.hasSubsidies) {
      return {
        reply: isTelugu
          ? "మీ ఖాతా లేదా మీ గ్రూప్ కోసం ఎటువంటి సబ్సిడీ రికార్డులు కనుగొనబడలేదు."
          : "I couldn't find any subsidy records for your account or group.",
        suggestions: getFollowUpSuggestions("subsidies", language)
      };
    }
    const subList = subSummary.subsidies
      .map(s => `${s.schemeName || 'Subsidy'} (${s.memberId}): ₹${s.amount} [${s.status}]`)
      .join("\n");
    return {
      reply: (isTelugu ? "సబ్సిడీ వివరాలు:\n" : "Subsidy details:\n") + subList,
      suggestions: getFollowUpSuggestions("subsidies", language)
    };
  }

  // Notifications
  if (intent === "notifications") {
    const notifSummary = data || {};
    if (!notifSummary.hasNotifications) {
      return {
        reply: isTelugu ? "నోటిఫికేషన్లు ఏవీ లేవు." : "No notifications found.",
        suggestions: getFollowUpSuggestions("general", language)
      };
    }
    const notifList = notifSummary.notifications.map(n => `- ${n.title}`).join("\n");
    return {
      reply: (isTelugu ? "ఇటీవలి నోటిఫికేషన్లు:\n" : "Recent notifications:\n") + notifList,
      suggestions: getFollowUpSuggestions("general", language)
    };
  }

  if (intent === "profile") {
    return {
      reply: isTelugu
        ? `పేరు: ${data.name}\nID: ${data.userId}\nగ్రూప్: ${data.groupId}`
        : `Name: ${data.name}\nID: ${data.userId}\nGroup: ${data.groupId}`,
      suggestions: getFollowUpSuggestions("general", language)
    };
  }

  if (intent === "group_id") {
    return {
      reply: isTelugu
        ? `మీ గ్రూప్ ఐడి ${data.groupId}.`
        : `Your Group ID is ${data.groupId}.`,
      suggestions: getFollowUpSuggestions("general", language)
    };
  }

  return {
    reply: isTelugu
      ? "నేను మీకు మీ రుణం, ఈఎంఐ, లావాదేవీలు, సబ్సిడీలు, నోటిఫికేషన్లు మరియు ప్రొఫైల్ వివరాల గురించి సహాయం చేయగలను."
      : "I can help you with your loan, EMI, transactions, subsidies, notifications and profile.",
    suggestions: getFollowUpSuggestions("general", language)
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
    const intent = detectIntent(message);

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
        suggestions: getFollowUpSuggestions("general", language),
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
