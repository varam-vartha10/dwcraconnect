const dns = require("node:dns");

console.log("Node DNS servers:");
console.log(dns.getServers());

dns.promises.resolveSrv("_mongodb._tcp.dwcra-connect.iiriqek.mongodb.net")
  .then((records) => {
    console.log("SRV lookup succeeded:");
    console.log(records);
  })
  .catch((error) => {
    console.error("SRV lookup failed:");
    console.error(error);
  });