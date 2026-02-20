const jwt = require('jsonwebtoken');

const setupTrackingSocket = (io) => {
  io.use((socket, next) => {
    // Middleware untuk validasi JWT saat connect socket
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('Auth error'));
    
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`Rider connected: ${socket.user.fullName}`);

    // Join room berdasarkan rideId agar broadcast terisolasi per rombongan
    socket.on('join_ride', (rideId) => {
      socket.join(rideId);
      console.log(`User ${socket.user.fullName} joined ride: ${rideId}`);
    });

    // Menerima lokasi dari satu anggota
    socket.on('send_location', (data) => {
      // data: { rideId, lat, lng, speed, heading }
      const { rideId, lat, lng, speed, heading } = data;
      
      // Broadcast ke SEMUA anggota lain di rombongan tersebut
      socket.to(rideId).emit('rider_moved', {
        userId: socket.user.id,
        fullName: socket.user.fullName,
        lat,
        lng,
        speed,
        heading,
        timestamp: new Date()
      });

      // Opsional: Simpan ke database setiap N detik untuk history (Summary)
    });

    // Handle Emergency Alert
    socket.on('send_emergency', (data) => {
      const { rideId, lat, lng, message } = data;
      io.to(rideId).emit('emergency_alert', {
        userId: socket.user.id,
        fullName: socket.user.fullName,
        lat,
        lng,
        message: message || 'MEMBUTUHKAN BANTUAN!'
      });
    });

    // Handle Regroup Alert
    socket.on('send_regroup', (data) => {
      const { rideId } = data;
      // Beri tahu SEMUA di room (termasuk leader sebagai konfirmasi)
      io.to(rideId).emit('regroup_alert', {
        leaderName: socket.user.fullName,
        timestamp: new Date()
      });
    });

    // Handle End Ride
    socket.on('send_end_ride', (data) => {
      const { rideId } = data;
      // Beri tahu SEMUA anggota
      io.to(rideId).emit('ride_ended', {
        message: 'Ride telah diakhiri oleh Leader.'
      });
    });

    socket.on('disconnect', () => {
      console.log('Rider disconnected');
    });
  });
};

module.exports = setupTrackingSocket;
