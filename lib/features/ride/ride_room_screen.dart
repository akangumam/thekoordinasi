import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/big_action_button.dart';
import '../../core/utils/location_utils.dart';
import '../../core/services/socket_service.dart';
import 'providers/riders_provider.dart';
import 'widgets/leader_panel.dart';

class RideRoomScreen extends ConsumerStatefulWidget {
  const RideRoomScreen({super.key});

  @override
  ConsumerState<RideRoomScreen> createState() => _RideRoomScreenState();
}

class _RideRoomScreenState extends ConsumerState<RideRoomScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _socketRiderStream;
  StreamSubscription? _socketEmergencyStream;

  LatLng? _currentPoisition;
  bool _emergencyActive = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initLocationTracking();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    final socketService = SocketService();

    _socketRiderStream = socketService.riderMovedStream.listen((data) {
      ref.read(ridersProvider.notifier).updateRider(data);
    });

    _socketEmergencyStream = socketService.emergencyStream.listen((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ EMERGENCY: ${data['fullName']} membutuhkan bantuan!',
            ),
            backgroundColor: AppColors.emergency,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'LIHAT',
              textColor: Colors.white,
              onPressed: () {
                _mapController.move(LatLng(data['lat'], data['lng']), 17.0);
              },
            ),
          ),
        );
      }
    });

    socketService.regroupStream.listen((data) {
      if (mounted) {
        _showRegroupAlert();
      }
    });

    socketService.rideEndedStream.listen((data) {
      if (mounted) {
        ref.read(appStateProvider).endRide();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride telah diakhiri oleh Leader')),
        );
      }
    });
  }

  void _showRegroupAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: AppColors.accent),
            SizedBox(width: 10),
            Text('REGROUP!'),
          ],
        ),
        content: const Text(
          'Road Captain meminta semua anggota untuk berkumpul kembali / berhenti sejenak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SIAP!'),
          ),
        ],
      ),
    );
  }

  Future<void> _initLocationTracking() async {
    final hasPermission = await LocationUtils.handleLocationPermission(context);
    if (!hasPermission) return;

    final appState = ref.read(appStateProvider);

    // Ambil lokasi awal
    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPoisition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPoisition!, 15.0);
    }

    // Listen ke perubahan lokasi
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            final newPos = LatLng(position.latitude, position.longitude);
            setState(() {
              _currentPoisition = newPos;
            });

            // Kirim ke server
            if (appState.currentRideId != null) {
              SocketService().sendLocation(
                appState.currentRideId!,
                newPos,
                position.speed,
                position.heading,
              );
            }
          }
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _socketRiderStream?.cancel();
    _socketEmergencyStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _handleEmergency() {
    setState(() => _emergencyActive = !_emergencyActive);
    if (_emergencyActive && _currentPoisition != null) {
      final appState = ref.read(appStateProvider);
      SocketService().sendEmergency(
        appState.currentRideId!,
        _currentPoisition!,
        'MOGOK / BUTUH BANTUAN',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🚨 Emergency dikirim ke semua anggota!'),
          backgroundColor: AppColors.emergency,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showLeaderPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LeaderPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final riders = ref.watch(ridersProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tidak bisa keluar saat ride aktif'),
              backgroundColor: AppColors.surfaceLight,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.two_wheeler_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appState.currentRideTitle ?? 'Ride Aktif',
                          style: AppTypography.headingSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Leader: ${appState.isLeader ? "Anda" : "—"}',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: appState.isLeader
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appState.isLeader ? 'LEADER' : 'MEMBER',
                          style: AppTypography.caption.copyWith(
                            color: appState.isLeader
                                ? AppColors.accent
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // MAP AREA
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.card,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _currentPoisition ??
                            const LatLng(-6.2000, 106.8166),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.thekoordinasi.app',
                        ),
                        MarkerLayer(
                          markers: [
                            // Marker User Sendiri (Leader/Anda)
                            if (_currentPoisition != null)
                              Marker(
                                point: _currentPoisition!,
                                width: 100,
                                height: 100,
                                child: GestureDetector(
                                  onTap: () => _showRiderInfo(
                                    appState.userName ?? 'Anda',
                                    appState.motorcycle ?? 'Motor',
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.background
                                              .withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.accent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          appState.userName ?? 'Anda',
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.navigation_rounded,
                                        size: 36,
                                        color: AppColors.accent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Marker Peserta Lain
                            ...riders.entries.map((entry) {
                              final rider = entry.value;
                              return Marker(
                                point: rider.position,
                                width: 100,
                                height: 100,
                                child: GestureDetector(
                                  onTap: () => _showRiderInfo(
                                    rider.fullName,
                                    rider.motorcycle ?? 'Motor',
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.background
                                              .withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          rider.fullName,
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.navigation_rounded,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                    // Floating Buttons
                    if (appState.isLeader)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'leader_panel',
                          backgroundColor: AppColors.accent,
                          onPressed: _showLeaderPanel,
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: AppColors.background,
                          ),
                        ),
                      ),

                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'recenter',
                        backgroundColor: AppColors.surface,
                        onPressed: () {
                          if (_currentPoisition != null) {
                            _mapController.move(_currentPoisition!, 15.0);
                          }
                        },
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM BAR
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Panel Anggota
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.group_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${riders.length + 1} Anggota',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Panel Kode Gabung
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (appState.currentRideCode != null) {
                              Clipboard.setData(
                                ClipboardData(text: appState.currentRideCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kode berhasil disalin!'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  size: 16,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    appState.currentRideCode ?? "......",
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    if (appState.currentRideCode != null) {
                                      Share.share(
                                        'Ayo gabung touring "${appState.currentRideTitle}" di aplikasi TheKoordinasi!\n\nKode Gabung: ${appState.currentRideCode}',
                                      );
                                    }
                                  },
                                  child: const Icon(
                                    Icons.share_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  EmergencyButton(
                    onPressed: _handleEmergency,
                    isActive: _emergencyActive,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRiderInfo(String name, String motorcycle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.headingMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.two_wheeler_rounded,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            motorcycle,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BigActionButton(
              label: 'Hubungi (Coming Soon)',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
