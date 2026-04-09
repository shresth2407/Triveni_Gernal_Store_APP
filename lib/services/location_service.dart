import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

abstract class LocationService {
  Future<bool> requestPermission();
  Future<String> getCurrentAddress();
}

class GeoLocationService implements LocationService {
  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<String> getCurrentAddress() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    final LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission denied. Please grant location access to use GPS detection.',
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw Exception('Unable to resolve address from current location.');
    }

    final Placemark place = placemarks.first;
    final parts = [
      place.street,
      place.locality,
      place.country,
    ].where((p) => p != null && p.isNotEmpty).toList();

    if (parts.isEmpty) {
      throw Exception('Could not determine a readable address for your location.');
    }

    return parts.join(', ');
  }
}
