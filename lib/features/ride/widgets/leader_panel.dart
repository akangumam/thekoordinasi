import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/big_action_button.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/socket_service.dart';
import '../providers/riders_provider.dart';
import 'end_ride_dialog.dart';

/// Leader Panel (Bottom Sheet)
/// Hanya muncul jika user adalah leader
///
/// Menampilkan:
/// - Info anggota paling belakang (terjauh)
/// - Tombol kirim alert regroup
/// - Tombol akhiri ride
class LeaderPanel extends ConsumerWidget {
  const LeaderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final riders = ref.watch(ridersProvider);

    // Cari rider terjauh (logic sederhana: hitung jarak dari leader/user sendiri)
    // Di prod, idealnya leader punya koordinat dan kita hitung jarak geodesik.
    // Untuk sekarang kita ambil rider pertama dari list (Placeholder logic for real data)
    final furthestRider = riders.values.isNotEmpty ? riders.values.first : null;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // ── Handle bar ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Leader Dashboard', style: AppTypography.headingSmall),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Info: Anggota paling belakang ──
          if (furthestRider != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anggota Terjauh',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            furthestRider.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              furthestRider.fullName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Update Baru saja',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      // Distance (Placeholder numeric)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Aktif',
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                          Text('di peta', style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Belum ada anggota bergabung',
                  style: AppTypography.caption,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // ── Stats row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.group_rounded,
                  label: 'Online',
                  value: '${riders.length + 1}',
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _StatStatCard(
                  icon: Icons.speed_rounded,
                  label: 'Status',
                  value: 'Touring',
                  color: AppColors.info,
                ),
                const SizedBox(width: 12),
                _StatStatCard(
                  icon: Icons.link_rounded,
                  label: 'KODE',
                  value: appState.currentRideCode ?? '---',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Button: Kirim Alert Regroup ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BigActionButton(
              label: 'KIRIM ALERT REGROUP',
              icon: Icons.campaign_rounded,
              onPressed: () {
                if (appState.currentRideId != null) {
                  SocketService().sendRegroupAlert(appState.currentRideId!);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '📢 Alert regroup dikirim ke semua anggota!',
                      ),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              backgroundColor: AppColors.accent,
              textColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 12),

          // ── Button: Akhiri Ride ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BigActionButton(
              label: 'AKHIRI RIDE',
              icon: Icons.stop_circle_rounded,
              onPressed: () {
                Navigator.of(context).pop(); // close bottom sheet
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const EndRideDialog(),
                );
              },
              backgroundColor: AppColors.surfaceLight,
              textColor: AppColors.emergency,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

// Rename stat card for internal use if needed or just use the existing one
class _StatStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// Stat card kecil untuk leader dashboard
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
