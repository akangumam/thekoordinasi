import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Model untuk menyimpan data rider lain
class RiderState {
  final String userId;
  final String fullName;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final String? motorcycle;
  final DateTime lastUpdate;

  RiderState({
    required this.userId,
    required this.fullName,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    this.motorcycle,
    required this.lastUpdate,
  });

  LatLng get position => LatLng(lat, lng);
}

/// Provider untuk mengelola daftar rider lain secara real-time
final ridersProvider =
    StateNotifierProvider<RidersNotifier, Map<String, RiderState>>((ref) {
      return RidersNotifier();
    });

class RidersNotifier extends StateNotifier<Map<String, RiderState>> {
  RidersNotifier() : super({});

  void updateRider(Map<String, dynamic> data) {
    final userId = data['userId'];
    state = {
      ...state,
      userId: RiderState(
        userId: userId,
        fullName: data['fullName'],
        lat: data['lat'],
        lng: data['lng'],
        speed: (data['speed'] ?? 0).toDouble(),
        heading: (data['heading'] ?? 0).toDouble(),
        motorcycle: data['motorcycle'],
        lastUpdate: DateTime.now(),
      ),
    };
  }

  void removeRider(String userId) {
    final newState = Map<String, RiderState>.from(state);
    newState.remove(userId);
    state = newState;
  }

  void clear() {
    state = {};
  }
}
