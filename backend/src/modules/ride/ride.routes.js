const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const db = require('../../config/database');

// Create Ride: Simpan ke DB & Jadikan Leader sebagai peserta pertama
router.post('/', authMiddleware, async (req, res) => {
  const { title } = req.body;
  const code = Math.random().toString(36).substring(2, 8).toUpperCase();
  
  try {
    console.log(`Menyimpan ride baru: ${title} oleh user ${req.user.id}`);
    const [ride] = await db('rides').insert({
      title: title || 'Trip Tanpa Judul',
      code: code,
      leader_id: req.user.id,
      status: 'active'
    }).returning('*');

    // Masukkan leader ke daftar peserta
    await db('ride_participants').insert({
      ride_id: ride.id,
      user_id: req.user.id
    });

    res.json({
      success: true,
      ride: {
        id: ride.id,
        title: ride.title,
        code: ride.code
      }
    });
  } catch (error) {
    console.error('Create Ride Error:', error);
    res.status(500).json({ success: false, message: 'Gagal membuat ride' });
  }
});

// Join Ride: Cari kode di DB & Tambahkan peserta
router.post('/join', authMiddleware, async (req, res) => {
  const { code } = req.body;

  try {
    // 1. Cari ride yang aktif dengan kode tersebut
    const ride = await db('rides')
      .where({ code: code.toUpperCase(), status: 'active' })
      .first();

    if (!ride) {
      return res.status(404).json({ success: false, message: 'Kode ride tidak ditemukan atau sudah berakhir' });
    }

    // 2. Tambahkan ke participants (jika belum ada)
    const existing = await db('ride_participants')
      .where({ ride_id: ride.id, user_id: req.user.id })
      .first();

    if (!existing) {
      await db('ride_participants').insert({
        ride_id: ride.id,
        user_id: req.user.id
      });
    }

    res.json({
      success: true,
      ride: {
        id: ride.id,
        title: ride.title,
        code: ride.code
      }
    });
  } catch (error) {
    console.error('Join Ride Error:', error);
    res.status(500).json({ success: false, message: 'Gagal bergabung ke ride' });
  }
});

module.exports = router;
