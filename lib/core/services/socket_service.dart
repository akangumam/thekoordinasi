import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:latlong2/latlong.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  // Stream for other riders' movements
  final _riderMovedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get riderMovedStream =>
      _riderMovedController.stream;

  // Stream for emergency alerts
  final _emergencyController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get emergencyStream =>
      _emergencyController.stream;

  // Stream for regroup alerts
  final _regroupController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get regroupStream => _regroupController.stream;

  // Stream for ride ended
  final _rideEndedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get rideEndedStream =>
      _rideEndedController.stream;

  void connect(String serverUrl, String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Terhubung ke Server WebSocket');
    });

    _socket!.onDisconnect((_) => print('❌ Terputus dari WebSocket'));

    // Listen for events
    _socket!.on('rider_moved', (data) {
      _riderMovedController.add(data);
    });

    _socket!.on('emergency_alert', (data) {
      _emergencyController.add(data);
    });

    _socket!.on('regroup_alert', (data) {
      _regroupController.add(data);
    });

    _socket!.on('ride_ended', (data) {
      _rideEndedController.add(data);
    });
  }

  void joinRide(String rideId) {
    _socket?.emit('join_ride', rideId);
  }

  void sendLocation(
    String rideId,
    LatLng position,
    double speed,
    double heading,
  ) {
    _socket?.emit('send_location', {
      'rideId': rideId,
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': speed,
      'heading': heading,
    });
  }

  void sendEmergency(String rideId, LatLng position, String message) {
    _socket?.emit('send_emergency', {
      'rideId': rideId,
      'lat': position.latitude,
      'lng': position.longitude,
      'message': message,
    });
  }

  void sendRegroupAlert(String rideId) {
    _socket?.emit('send_regroup', {'rideId': rideId});
  }

  void sendEndRide(String rideId) {
    _socket?.emit('send_end_ride', {'rideId': rideId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
