// lib/models/bike_location.dart

import 'package:latlong2/latlong.dart';

/// Repräsentiert den Standort eines Fahrrads mit seiner ID, Breiten- und Längengrad.
class BikeLocation {
  final String bikeNumber;
  final LatLng position;

  BikeLocation({required this.bikeNumber, required this.position});

  @override
  String toString() {
    return 'BikeLocation(bikeNumber: $bikeNumber, position: ${position.latitude}, ${position.longitude})';
  }
}
