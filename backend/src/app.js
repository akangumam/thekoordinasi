const express = require('express');
const cors = require('cors');
const authRoutes = require('./modules/auth/auth.routes');
const rideRoutes = require('./modules/ride/ride.routes');

const app = express();

app.use(cors());
app.use(express.json());

// Request logger sederhana
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Basic health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Backend The Koordinasi is running' });
});

// Routes placeholders
app.use('/api/auth', authRoutes);
app.use('/api/rides', rideRoutes);

module.exports = app;
