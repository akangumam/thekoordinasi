const http = require('http');
const app = require('./app');
const { Server } = require('socket.io');
const setupTrackingSocket = require('./sockets/tracking.socket');
require('dotenv').config();

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Di prod sebaiknya dibatasi ke domain aplikasi
    methods: ["GET", "POST"]
  }
});

// Jalankan logika WebSocket
setupTrackingSocket(io);

const PORT = process.env.PORT || 3000;

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server Koordinasi jalan di port ${PORT}`);
  console.log(`📡 WebSocket juga aktif di port yang sama`);
});
