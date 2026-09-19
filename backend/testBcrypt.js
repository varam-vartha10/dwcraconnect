const bcrypt = require("bcryptjs");

async function test() {
    const p = "123456";

    console.log("Testing bcrypt.genSalt(12)...");
    const salt = await bcrypt.genSalt(12);
    console.log("Salt result type:", typeof salt);
    console.log("Salt result value:", salt);

    console.log("\nTesting bcrypt.hash(p, 12)...");
    const hash = await bcrypt.hash(p, 12);
    console.log("Hash result type:", typeof hash);
    console.log("Hash result value:", hash);
}

test();
