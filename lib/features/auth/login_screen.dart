import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/big_action_button.dart';

/// Login Screen
/// - Minimal: Nama Lengkap + Nomor HP
/// - Tanpa OTP, tanpa password (MVP internal)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _motorController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _motorController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // MVP: Login langsung simpan ke local state
    // Nanti akan diganti dengan API call ke backend
    await ref
        .read(appStateProvider)
        .login(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          motorcycle: _motorController.text.trim(),
        );

    // GoRouter redirect otomatis ke HomeScreen
    // Tidak perlu manual navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),

                // ── Logo Teks ──
                Image.asset(
                  'assets/logo_teks_thekoordinasi.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk mulai koordinasi touring',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // ── Input: Nama Lengkap ──
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Nama Lengkap',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan nama lengkap';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Input: Nomor HP ──
                TextFormField(
                  controller: _phoneController,
                  style: AppTypography.bodyLarge,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Nomor HP',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan nomor HP';
                    }
                    if (value.trim().length < 10) {
                      return 'Nomor HP minimal 10 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Input: Jenis Motor ──
                TextFormField(
                  controller: _motorController,
                  style: AppTypography.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Jenis Motor (Contoh: NMAX)',
                    prefixIcon: Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan jenis motor';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // ── Button: MASUK ──
                BigActionButton(
                  label: 'MASUK',
                  icon: Icons.login_rounded,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 60),

                // ── Footer ──
                Text(
                  'Aplikasi private komunitas',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
