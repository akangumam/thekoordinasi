import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/socket_service.dart';

// ──────────────────────────────────────────────
// SharedPreferences keys
// ──────────────────────────────────────────────
const _keyIsLoggedIn = 'isLoggedIn';
const _keyUserName = 'userName';
const _keyUserPhone = 'userPhone';
const _keyToken = 'userToken';
const _keyIsInRide = 'isInRide';
const _keyCurrentRideId = 'currentRideId';
const _keyIsLeader = 'isLeader';
const _keyCurrentRideTitle = 'currentRideTitle';
const _keyCurrentRideCode = 'currentRideCode';
const _keyMotorcycle = 'motorcycle';

// ──────────────────────────────────────────────
// Global Config (Gunakan localhost + adb reverse untuk HP fisik)
// ──────────────────────────────────────────────
// Alamat server (Ganti link https ini dengan URL dari localtunnel/ngrok Anda)
const baseUrl = 'https://ALAMAT-TUNNEL-ANDA.loca.lt';

// ──────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────
final appStateProvider = ChangeNotifierProvider<AppStateNotifier>((ref) {
  return AppStateNotifier();
});

// ──────────────────────────────────────────────
// AppStateNotifier
// ──────────────────────────────────────────────

class AppStateNotifier extends ChangeNotifier {
  final _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10), // Maksimal nunggu 10 detik
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  bool _initialized = false;
  bool _isLoggedIn = false;
  String? _userName;
  String? _userPhone;
  String? _token;
  bool _isInRide = false;
  String? _currentRideId;
  String? _currentRideTitle;
  String? _currentRideCode;
  String? _motorcycle;
  bool _isLeader = false;

  // ── Getters ──
  bool get initialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  String? get token => _token;
  bool get isInRide => _isInRide;
  String? get currentRideId => _currentRideId;
  String? get currentRideTitle => _currentRideTitle;
  String? get currentRideCode => _currentRideCode;
  String? get motorcycle => _motorcycle;
  bool get isLeader => _isLeader;

  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();

    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _userName = prefs.getString(_keyUserName);
    _userPhone = prefs.getString(_keyUserPhone);
    _token = prefs.getString(_keyToken);
    _isInRide = prefs.getBool(_keyIsInRide) ?? false;
    _currentRideId = prefs.getString(_keyCurrentRideId);
    _currentRideTitle = prefs.getString(_keyCurrentRideTitle);
    _currentRideCode = prefs.getString(_keyCurrentRideCode);
    _motorcycle = prefs.getString(_keyMotorcycle);
    _isLeader = prefs.getBool(_keyIsLeader) ?? false;

    if (_isLoggedIn && _token != null) {
      SocketService().connect(baseUrl, _token!);
    }

    // Kita tidak memanggil notifyListeners() di sini agar GoRouter
    // tidak langsung redirect sebelum splash selesai.
  }

  void completeInitialization() {
    _initialized = true;
    notifyListeners();
  }

  Future<void> login({
    required String name,
    required String phone,
    String? motorcycle,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'name': name, 'phone': phone, 'motorcycle': motorcycle},
      );

      if (response.data['success']) {
        final prefs = await SharedPreferences.getInstance();
        _token = response.data['token'];
        _userName = response.data['user']['fullName'];
        _userPhone = response.data['user']['phone'];
        _isLoggedIn = true;

        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserName, _userName!);
        await prefs.setString(_keyUserPhone, _userPhone!);
        await prefs.setString(_keyToken, _token!);

        // Simpan jenis motor jika ada dari server (opsional)
        if (response.data['user']['motorcycle'] != null) {
          _motorcycle = response.data['user']['motorcycle'];
          await prefs.setString(_keyMotorcycle, _motorcycle!);
        }

        SocketService().connect(baseUrl, _token!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_isInRide) return;
    final prefs = await SharedPreferences.getInstance();

    _isLoggedIn = false;
    _userName = null;
    _userPhone = null;
    _token = null;

    await prefs.clear();
    SocketService().disconnect();
    notifyListeners();
  }

  Future<void> createRide({required String title}) async {
    try {
      final response = await _dio.post(
        '/api/rides',
        data: {'title': title},
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );

      if (response.data['success']) {
        final ride = response.data['ride'];
        debugPrint('Ride created successfully: ${ride['id']}');
        await joinRide(
          rideId: ride['id'],
          rideTitle: ride['title'],
          rideCode: ride['code'],
          asLeader: true,
        );
      }
    } catch (e) {
      debugPrint('Create Ride Error: $e');
      rethrow;
    }
  }

  Future<void> joinRide({
    required String rideId,
    required String rideTitle,
    required String rideCode,
    required bool asLeader,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _isInRide = true;
    _currentRideId = rideId;
    _currentRideTitle = rideTitle;
    _currentRideCode = rideCode;
    _isLeader = asLeader;

    await prefs.setBool(_keyIsInRide, true);
    await prefs.setString(_keyCurrentRideId, rideId);
    await prefs.setString(_keyCurrentRideTitle, rideTitle);
    await prefs.setString(_keyCurrentRideCode, rideCode);
    await prefs.setBool(_keyIsLeader, asLeader);

    SocketService().joinRide(rideId);
    notifyListeners();
  }

  Future<void> joinRideWithCode({required String code}) async {
    try {
      final response = await _dio.post(
        '/api/rides/join',
        data: {'code': code},
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );

      if (response.data['success']) {
        final ride = response.data['ride'];
        await joinRide(
          rideId: ride['id'],
          rideTitle: ride['title'],
          rideCode: ride['code'],
          asLeader: false,
        );
      }
    } catch (e) {
      debugPrint('Join Ride Error: $e');
      rethrow;
    }
  }

  Future<void> endRide() async {
    final prefs = await SharedPreferences.getInstance();

    _isInRide = false;
    _currentRideId = null;
    _currentRideTitle = null;
    _isLeader = false;

    await prefs.setBool(_keyIsInRide, false);
    await prefs.remove(_keyCurrentRideId);
    await prefs.remove(_keyCurrentRideTitle);
    await prefs.remove(_keyCurrentRideCode);
    await prefs.setBool(_keyIsLeader, false);

    notifyListeners();
  }
}
