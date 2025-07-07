import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<String?> getReadableLocation(String? location) async {
    if (location == null) return null;

    // If it's already an address (not coordinates), return as-is
    if (!_isCoordinateString(location)) return location;

    try {
      final parts = location.split(',');
      if (parts.length != 2) return location;

      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat == null || lng == null) return location;

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return location;

      final place = placemarks.first;
      return [
        if (place.street != null) place.street,
        if (place.locality != null) place.locality,
        if (place.administrativeArea != null) place.administrativeArea,
        if (place.country != null) place.country,
      ].where((part) => part != null && part.isNotEmpty).join(', ');
    } catch (e) {
      print('Geocoding error: $e');
      return location; // Return original if conversion fails
    }
  }

  static bool _isCoordinateString(String input) {
    final parts = input.split(',');
    if (parts.length != 2) return false;
    return double.tryParse(parts[0].trim()) != null &&
        double.tryParse(parts[1].trim()) != null;
  }
}