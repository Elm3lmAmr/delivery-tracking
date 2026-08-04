import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../features/delivery/domain/repositories/delivery_repository.dart';

// Pings the driver's location to the backend every N seconds during an active delivery.
class LocationService {
  final DeliveryRepository repository;
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;

  LocationService(this.repository);

  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      return false;
    }
    return await Geolocator.isLocationServiceEnabled();
  }

  Position? _lastPos;

  void startTracking(int deliveryId, {Duration interval = const Duration(seconds: 30)}) {
    stopTracking();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      _lastPos = pos;
      _sendPing(deliveryId, pos);
    });

    // Fallback timer: guarantees a ping every interval even if completely stationary
    _timer = Timer.periodic(interval, (_) {
      if (_lastPos != null) {
        _sendPing(deliveryId, _lastPos!);
      }
    });
  }

  void _sendPing(int deliveryId, Position pos) {
    // Best-effort ping. Errors are swallowed to keep the stream alive.
    repository.postPing(
      deliveryId, pos.latitude, pos.longitude,
      accuracy: pos.accuracy, speed: pos.speed * 3.6,
    ).catchError((_) {});
  }

  void stopTracking() {
    _timer?.cancel();
    _positionSub?.cancel();
    _timer = null;
    _positionSub = null;
  }
}
