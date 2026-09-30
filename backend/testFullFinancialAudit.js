const dns = require('node:dns');
dns.setServers(['8.8.8.8', '1.1.1.1']);
const mongoose = require('mongoose');
require('dotenv').config({ path: './.env' });
const { processChatMessage } = require('./src/services/chatService');
const User = require('./src/models/User');

async function runFullAudit() {
  await mongoose.connect(process.env.MONGO_URI, { dbName: 'dwcra_connect' });

  const testUserIds = ['SHG-001', 'SHG-003', 'SHG-004'];

  const testQuestions = [
    'What is my total loan?',
    'How much have I paid?',
    'How much loan do I have left?',
    'Show my active loans.',
    'What is my next EMI?',
    'When is my EMI due?',
    'How much is my EMI?',
    'Show my transactions.',
    'naa total loan entha?',
    'naa loan inka entha undi?',
    'nenu entha pay chesanu?',
    'next EMI eppudu?',
    'naa EMI entha?',
    'naa transactions chupinchu'
  ];

  for (const uid of testUserIds) {
    const user = await User.findOne({ userId: uid });
    console.log(`\n==================================================`);
    console.log(`TESTING USER: ${user.name} (${user.userId}) | Role: ${user.role}`);
    console.log(`==================================================`);

    for (let i = 0; i < testQuestions.length; i++) {
      const q = testQuestions[i];
      const res = await processChatMessage({
        authenticatedUser: { id: user._id.toString() },
        message: q
      });
      console.log(`\n[Q ${i+1}] "${q}"`);
      console.log(`  Intent: ${res.intent} | Source: ${res.dataSource}`);
      console.log(`  Reply :\n${res.reply.split('\n').map(l => '    ' + l).join('\n')}`);
    }
  }

  await mongoose.disconnect();
}

runFullAudit().catch(console.error);
