import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/state/app_state.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/ride/create_ride_screen.dart';
import 'features/ride/join_ride_screen.dart';
import 'features/ride/ride_room_screen.dart';

// ──────────────────────────────────────────────────────
// Route Paths
// ──────────────────────────────────────────────────────
class RoutePaths {
  RoutePaths._();
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const createRide = '/create-ride';
  static const joinRide = '/join-ride';
  static const rideRoom = '/ride-room';
}

// ──────────────────────────────────────────────────────
// Router Provider
// ──────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final appState = ref.watch(appStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,

    // GoRouter akan re-evaluate redirect setiap kali
    // appState.notifyListeners() dipanggil
    refreshListenable: appState,

    // ════════════════════════════════════════════════
    // REDIRECT LOGIC — INI JANTUNG ROUTING APP
    // ════════════════════════════════════════════════
    redirect: (context, state) {
      final initialized = appState.initialized;
      final isLoggedIn = appState.isLoggedIn;
      final isInRide = appState.isInRide;
      final currentPath = state.matchedLocation;

      // ── 1. Belum initialized → tetap di splash ──
      if (!initialized) {
        if (currentPath == RoutePaths.splash) return null;
        return RoutePaths.splash;
      }

      // ── 2. Belum login → paksa ke login ──
      if (!isLoggedIn) {
        if (currentPath == RoutePaths.login) return null;
        return RoutePaths.login;
      }

      // ── 3. Sedang ride → PAKSA ke ride room ──
      // Ini memastikan:
      // - App restart saat ride → langsung ke ride room
      // - User coba navigate ke mana pun → tetap di ride room
      // - Back button → tetap di ride room
      if (isInRide) {
        if (currentPath == RoutePaths.rideRoom) return null;
        return RoutePaths.rideRoom;
      }

      // ── 4. Sudah login, tidak ride ──
      // Redirect dari splash/login ke home
      if (currentPath == RoutePaths.splash || currentPath == RoutePaths.login) {
        return RoutePaths.home;
      }

      // Block akses ride room jika tidak sedang ride
      if (currentPath == RoutePaths.rideRoom) {
        return RoutePaths.home;
      }

      // Izinkan navigasi normal (home, create, join)
      return null;
    },

    // ════════════════════════════════════════════════
    // ROUTES
    // ════════════════════════════════════════════════
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.createRide,
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: RoutePaths.joinRide,
        builder: (context, state) => const JoinRideScreen(),
      ),
      GoRoute(
        path: RoutePaths.rideRoom,
        builder: (context, state) => const RideRoomScreen(),
      ),
    ],
  );
});
