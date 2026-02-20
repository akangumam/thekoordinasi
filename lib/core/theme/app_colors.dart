import 'package:flutter/material.dart';

/// Warna aplikasi TheKoordinasi
/// Dark theme optimized untuk outdoor riding visibility
class AppColors {
  AppColors._();

  // ── Background ──
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceLight = Color(0xFF242736);
  static const Color card = Color(0xFF1E2130);

  // ── Primary (Orange - Adventure/Motorcycle)  ──
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F5E);
  static const Color primaryDark = Color(0xFFE55A25);

  // ── Accent ──
  static const Color accent = Color(0xFFFFB800);

  // ── Status ──
  static const Color emergency = Color(0xFFFF2D55);
  static const Color emergencyDark = Color(0xFFCC1B3E);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFCC00);
  static const Color info = Color(0xFF5AC8FA);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Border & Divider ──
  static const Color border = Color(0xFF2C2E3A);
  static const Color divider = Color(0xFF2C2E3A);

  // ── Rider Status Colors ──
  static const Color riderOnline = Color(0xFF34C759);
  static const Color riderOffline = Color(0xFF636366);
  static const Color riderEmergency = Color(0xFFFF2D55);
}
