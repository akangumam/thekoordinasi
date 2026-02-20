const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../../config/database');

// Login: Cek database, jika belum ada buat user baru (Upsert)
router.post('/login', async (req, res) => {
  const { name, phone, motorcycle } = req.body;
  
  try {
    // 1. Cari user berdasarkan nomor HP
    let user = await db('users').where({ phone }).first();
    
    // 2. Jika tidak ada, buat user baru
    if (!user) {
      const [newUser] = await db('users').insert({
        full_name: name,
        phone: phone,
        motorcycle: motorcycle || null
      }).returning('*');
      user = newUser;
    } else if (motorcycle) {
      // Update jenis motor jika user sudah ada tapi input motor baru
      await db('users').where({ id: user.id }).update({ motorcycle });
      user.motorcycle = motorcycle;
    }

    // 3. Generate Token (Sertakan jenis motor)
    const token = jwt.sign(
      { 
        id: user.id, 
        fullName: user.full_name, 
        phone: user.phone,
        motorcycle: user.motorcycle 
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      user: { 
        id: user.id, 
        fullName: user.full_name, 
        phone: user.phone,
        motorcycle: user.motorcycle
      },
      token
    });
  } catch (error) {
    console.error('Login Error:', error);
    res.status(500).json({ success: false, message: 'Server error saat login' });
  }
});

module.exports = router;
