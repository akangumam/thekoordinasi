import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_state.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// End Ride Dialog
/// Hanya bisa dipanggil oleh Leader
/// Konfirmasi sebelum mengakhiri ride untuk semua anggota
class EndRideDialog extends ConsumerStatefulWidget {
  const EndRideDialog({super.key});

  @override
  ConsumerState<EndRideDialog> createState() => _EndRideDialogState();
}

class _EndRideDialogState extends ConsumerState<EndRideDialog> {
  bool _isEnding = false;

  Future<void> _handleEndRide() async {
    setState(() => _isEnding = true);

    final appState = ref.read(appStateProvider);
    if (appState.currentRideId != null) {
      // Broadcast via socket agar semua anggota keluar
      SocketService().sendEndRide(appState.currentRideId!);
    }

    // Tunggu sebentar untuk animasi/socket broadcast
    await Future.delayed(const Duration(milliseconds: 500));

    // Clear ride state local
    await ref.read(appStateProvider).endRide();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.emergency.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_circle_rounded,
                size: 40,
                color: AppColors.emergency,
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ──
            Text('Akhiri Ride?', style: AppTypography.headingMedium),
            const SizedBox(height: 12),

            // ── Description ──
            Text(
              'Ride akan berakhir untuk semua anggota.\nRingkasan ride akan dibuat otomatis.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ── Button: Ya, Akhiri ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isEnding ? null : _handleEndRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor: AppColors.emergency.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isEnding
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.textOnPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'YA, AKHIRI RIDE',
                        style: AppTypography.buttonMedium,
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Button: Batal ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: _isEnding ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'BATAL',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
