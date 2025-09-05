// lib/widgets/bike_map.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Ein Widget, das die OpenStreetMap mit Markern anzeigt.
/// Es kann auch Ladezustände oder Fehlermeldungen anzeigen.
class BikeMap extends StatelessWidget {
  final MapController mapController;
  final LatLng initialMapCenter;
  final double initialMapZoom;
  final List<Marker> markers;
  final bool
  isLoading; // Zeigt an, ob die initialen Daten für die Karte geladen werden
  final String?
  errorMessage; // Eine Fehlermeldung, die statt der Karte angezeigt werden soll

  const BikeMap({
    super.key,
    required this.mapController,
    required this.initialMapCenter,
    required this.initialMapZoom,
    required this.markers,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Zeigt einen Ladeindikator, wenn die Karte noch initial geladen wird.
      return const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      // Zeigt eine Fehlermeldung an, wenn ein Fehler beim Laden der Kartendaten auftrat.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Konnte Karte nicht laden aufgrund eines Fehlers: $errorMessage',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // Zeigt die FlutterMap an, wenn keine Fehler oder Ladezustände vorliegen.
      return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: initialMapCenter,
          initialZoom: initialMapZoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'de.yourcompany.unextbike',
          ),
          MarkerLayer(markers: markers),
        ],
      );
    }
  }
}
