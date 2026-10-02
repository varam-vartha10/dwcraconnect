const dns = require('node:dns');
dns.setServers(['8.8.8.8', '1.1.1.1']);
const mongoose = require('mongoose');
require('dotenv').config({ path: './.env' });
const { processChatMessage } = require('./src/services/chatService');
const { getMyAccountSummary } = require('./src/services/accountSummaryService');
const { getGroupSummary } = require('./src/services/groupSummaryService');
const User = require('./src/models/User');

async function runMultiUserAudit() {
  await mongoose.connect(process.env.MONGO_URI, { dbName: 'dwcra_connect' });

  const testUsers = ['SHG-001', 'SHG-003', 'SHG-004'];

  console.log('=== MULTI-MEMBER ACCOUNT ISOLATION AUDIT ===');
  for (const uid of testUsers) {
    const user = await User.findOne({ userId: uid });
    const acc = await getMyAccountSummary(user.userId, user.groupId, user.role);

    console.log(`\n--- Member ${user.userId} (${user.name}) | Role: ${user.role} ---`);
    console.log('  Loan Count      :', acc.loanSummary.loanCount);
    console.log('  Active Loans    :', acc.loanSummary.activeLoanCount);
    console.log('  Total Principal :', '₹' + acc.loanSummary.totalPrincipal);
    console.log('  Total Repaid    :', '₹' + acc.loanSummary.totalPaid);
    console.log('  Remaining Bal   :', '₹' + acc.loanSummary.remainingBalance);
    console.log('  EMIs Total      :', acc.emiSummary.totalEmisCount);
    console.log('  EMIs Paid       :', acc.emiSummary.paidEmisCount);
    console.log('  EMIs Overdue    :', acc.emiSummary.overdueEmisCount);
  }

  console.log('\n=== GROUP SUMMARY AUDIT FOR GRP001 ===');
  const grpSummary = await getGroupSummary('GRP001');
  console.log('Group ID             :', grpSummary.groupId);
  console.log('Total Group Members  :', grpSummary.totalMembers);
  console.log('Total Group Principal:', '₹' + grpSummary.totalGroupPrincipal);
  console.log('Total Group Repaid   :', '₹' + grpSummary.totalGroupPaid);
  console.log('Total Group Remaining:', '₹' + grpSummary.totalGroupRemaining);
  console.log('Member Breakdown     :');
  for (const m of grpSummary.memberSummaries) {
    console.log(`  - ${m.userId} (${m.name}): Loan ₹${m.totalPrincipal}, Paid ₹${m.totalPaid}, Bal ₹${m.remainingBalance}`);
  }

  console.log('\n=== CHATBOT NATURAL CONVERSATION AUDIT ===');
  const chatQuestions = [
    'What is my total loan?',
    'How much loan do I have left?',
    'How much have I paid?',
    'When is my next EMI?',
    'Is my EMI overdue?',
    'Show my transactions.',
    'Do I have any subsidy?',
    'What is my group ID?',
    'Tell me about my account.',
    'Explain EMI',
    'naa loan entha undhi?',
    'naa EMI eppudu?',
    'Hello'
  ];

  const testUser = await User.findOne({ userId: 'SHG-004' });
  for (let i = 0; i < chatQuestions.length; i++) {
    const q = chatQuestions[i];
    const res = await processChatMessage({
      authenticatedUser: { id: testUser._id.toString() },
      message: q
    });
    console.log(`\n[Q ${i+1}] "${q}"`);
    console.log(`  Intent: ${res.intent} | Source: ${res.dataSource}`);
    console.log(`  Reply : ${res.reply}`);
    console.log(`  Suggestions: ${JSON.stringify(res.suggestions)}`);
  }

  await mongoose.disconnect();
}

runMultiUserAudit().catch(console.error);
