import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/big_action_button.dart';
import '../../app_router.dart';

/// Home Screen (Not In Ride)
/// - Sapaan user
/// - 2 tombol besar: BUAT RIDE + GABUNG RIDE
/// - Tidak ada tab bar, tidak ada profile menu
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(appStateProvider).logout(),
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textTertiary,
            ),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Header: Greeting ──
              Text(
                '$greeting,',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appState.userName ?? 'Rider',
                style: AppTypography.displayMedium,
              ),

              const SizedBox(height: 12),

              // ── Subtitle ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Siap touring',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Illustration area ──
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    size: 80,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),

              const Spacer(),

              // ── Button: BUAT RIDE ──
              BigActionButton(
                label: 'BUAT RIDE',
                icon: Icons.add_road_rounded,
                onPressed: () => context.push(RoutePaths.createRide),
                backgroundColor: AppColors.primary,
              ),
              const SizedBox(height: 16),

              // ── Button: GABUNG RIDE ──
              BigActionButton(
                label: 'GABUNG RIDE',
                icon: Icons.group_add_rounded,
                onPressed: () => context.push(RoutePaths.joinRide),
                backgroundColor: AppColors.surfaceLight,
                textColor: AppColors.textPrimary,
              ),

              const SizedBox(height: 40),

              // ── Riwayat Ride (placeholder) ──
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to ride history
                  },
                  child: Text(
                    'Riwayat Ride',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}
