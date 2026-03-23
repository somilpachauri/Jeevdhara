// lib/core/utils/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String street;
  final String city;
  final String state;

 LocationResult(this.latitude, this.longitude, this.street, this.city, this.state);
}
class LocationService {
  Future<LocationResult> getCurrentLocationDetails() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied");
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

   String street = "Unknown Area";
    String city = "Unknown City";
    String state = "Unknown State";

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      
      // Safely handle nulls from Flutter Web
      String streetName = place.street ?? '';
      String subLocality = place.subLocality ?? '';
      
      street = "$streetName, $subLocality".trim();
      if (street == ",") street = "Unknown Area"; // Fallback if both are empty
      
      city = place.locality ?? place.subAdministrativeArea ?? "Unknown City";
      state = place.administrativeArea ?? "Unknown State";
    }

    return LocationResult(position.latitude, position.longitude, street, city, state);
  }

  Future<Position?> getCoordinatesFromAddress(String fullAddress) async {
    try {
      List<Location> locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        return Position(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}