// 1. مراقب الانهيارات (هذا سيكشف سبب الخطأ في سجلات رندر)
process.on('uncaughtException', (err) => {
  console.error('CRITICAL ERROR:', err);
  process.exit(1);
});
process.on('unhandledRejection', (reason) => {
  console.error('UNHANDLED REJECTION:', reason);
});

// 2. خادم "البقاء على قيد الحياة" لرندر
const http = require('http');
const PORT = process.env.PORT || 3000;
http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end("Bot is Alive and Healthy!");
}).listen(PORT, () => {
  console.log(`Web server running on port ${PORT}`);
});

// 3. هنا ضع كود البوت الخاص بك (تأكد من وجوده هنا)
console.log("Bot process is starting...");
// example: const { Client } = require('discord.js'); ... إلخ
