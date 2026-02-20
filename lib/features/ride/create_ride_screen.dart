import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/big_action_button.dart';

/// Create Ride Screen
/// Leader mengisi: Judul ride, Start point, End point, Checkpoints (optional)
class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final List<TextEditingController> _checkpointControllers = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _startController.dispose();
    _endController.dispose();
    for (final c in _checkpointControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCheckpoint() {
    if (_checkpointControllers.length >= 5) return; // Max 5 checkpoints
    setState(() {
      _checkpointControllers.add(TextEditingController());
    });
  }

  void _removeCheckpoint(int index) {
    setState(() {
      _checkpointControllers[index].dispose();
      _checkpointControllers.removeAt(index);
    });
  }

  Future<void> _handleCreateRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rideTitle = _titleController.text.trim();

    try {
      // Panggil API untuk membuat ride
      await ref.read(appStateProvider).createRide(title: rideTitle);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat ride: $e')));
      }
    }

    // GoRouter redirect otomatis ke RideRoom
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Ride'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Judul Ride ──
                Text('Judul Ride', style: AppTypography.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: AppTypography.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Sunday Ride Dieng',
                    prefixIcon: Icon(
                      Icons.edit_road_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Masukkan judul ride'
                      : null,
                ),
                const SizedBox(height: 24),

                // ── Start Point ──
                Text('Titik Mulai', style: AppTypography.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _startController,
                  style: AppTypography.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: SPBU Cikini, Jakarta',
                    prefixIcon: Icon(
                      Icons.trip_origin_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Masukkan titik mulai'
                      : null,
                ),
                const SizedBox(height: 24),

                // ── End Point ──
                Text('Titik Tujuan', style: AppTypography.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _endController,
                  style: AppTypography.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Dieng Plateau, Wonosobo',
                    prefixIcon: Icon(
                      Icons.flag_rounded,
                      color: AppColors.emergency,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Masukkan titik tujuan'
                      : null,
                ),
                const SizedBox(height: 32),

                // ── Checkpoints (Optional) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Checkpoint (opsional)', style: AppTypography.label),
                    if (_checkpointControllers.length < 5)
                      TextButton.icon(
                        onPressed: _addCheckpoint,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_checkpointControllers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Belum ada checkpoint.\nTekan "Tambah" untuk menambahkan titik istirahat.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),

                ...List.generate(_checkpointControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _checkpointControllers[index],
                            style: AppTypography.bodyLarge,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Checkpoint ${index + 1}',
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeCheckpoint(index),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 40),

                // ── Button: BUAT & MULAI RIDE ──
                BigActionButton(
                  label: 'BUAT & MULAI RIDE',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _handleCreateRide,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // ── Info ──
                Center(
                  child: Text(
                    'Kode join akan dibuat otomatis.\nBagikan ke anggota untuk bergabung.',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
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
