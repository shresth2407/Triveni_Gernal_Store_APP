import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_state.dart';
import '../services/location_service.dart';

const _kLocationKey = 'saved_delivery_address';

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeoLocationService();
});

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const LocationState()) {
    _loadCached();
  }

  /// Restore cached address from shared_preferences on startup.
  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocationKey);
    if (saved != null && saved.isNotEmpty) {
      state = LocationState(address: saved);
    }
  }

  Future<void> _saveToCache(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocationKey, address);
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocationKey);
  }

  /// Requests GPS permission and resolves the current address.
  Future<void> detectGps() async {
    state = const LocationState(isLoading: true);
    try {
      final granted = await _locationService.requestPermission();
      if (!granted) {
        state = const LocationState(
          error: 'Location permission denied. Please enter your address manually.',
        );
        return;
      }
      final address = await _locationService.getCurrentAddress();
      await _saveToCache(address);
      state = LocationState(address: address);
    } catch (e) {
      state = LocationState(error: e.toString());
    }
  }

  /// Stores a manually entered address.
  Future<void> setManual(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      state = const LocationState();
      return;
    }
    await _saveToCache(trimmed);
    state = LocationState(address: trimmed);
  }

  /// Clears the saved location (e.g. on logout).
  Future<void> clear() async {
    await _clearCache();
    state = const LocationState();
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});
