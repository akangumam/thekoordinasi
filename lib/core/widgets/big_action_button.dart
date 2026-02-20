import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tombol besar untuk aksi utama saat riding
/// Minimum height 64dp — mudah ditekan bahkan dengan gloves
class BigActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final bool isLoading;

  const BigActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.height = 64,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = textColor ?? AppColors.textOnPrimary;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(fgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: AppTypography.buttonLarge.copyWith(color: fgColor),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Tombol Emergency — lebih besar, warna merah, full prominence
class EmergencyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isActive;

  const EmergencyButton({super.key, this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isActive ? Icons.warning_rounded : Icons.sos_rounded,
          size: 28,
          color: AppColors.textOnPrimary,
        ),
        label: Text(
          isActive ? 'EMERGENCY AKTIF' : '🚨 EMERGENCY',
          style: AppTypography.buttonLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? AppColors.emergencyDark
              : AppColors.emergency,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
