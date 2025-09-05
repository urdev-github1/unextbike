// lib/services/nextbike_api_service.dart

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import '../models/bike_location.dart'; // Import des neuen Modells

/// Ein Service zum Abrufen und Parsen von Next-Bike-Daten.
class NextbikeApiService {
  final String _apiUrl =
      'https://api.nextbike.net/maps/nextbike-live.xml?city=14';

  /// Ruft die Next-Bike-Daten ab und gibt eine Map von Fahrrad-IDs zu BikeLocation-Objekten zurück.
  Future<Map<String, BikeLocation>> fetchBikeLocations() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        // Erfolgreiche Antwort, jetzt XML parsen
        return _parseXmlResponse(response.body);
      } else {
        // Fehler bei der API-Anfrage
        throw Exception(
          'Fehler beim Laden der Next-Bike Daten: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Allgemeine Netzwerk- oder andere Fehler abfangen
      throw Exception('Netzwerk- oder Parsing-Fehler: $e');
    }
  }

  /// Parst den XML-String und extrahiert die Fahrradstandorte.
  Map<String, BikeLocation> _parseXmlResponse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final Map<String, BikeLocation> bikeLocations = {};

    // Finden des 'city'-Elements
    final cityElement = document.findAllElements('city').firstOrNull;

    if (cityElement != null) {
      // Iterieren über alle 'place'-Elemente innerhalb des 'city'-Elements
      for (final placeElement in cityElement.findAllElements('place')) {
        final latString = placeElement.getAttribute('lat');
        final lngString = placeElement.getAttribute('lng');

        if (latString != null && lngString != null) {
          try {
            final lat = double.parse(latString);
            final lng = double.parse(lngString);
            final placeLatLng = LatLng(lat, lng);

            // Jetzt die 'bike'-Elemente innerhalb dieses 'place' finden
            for (final bikeElement in placeElement.findAllElements('bike')) {
              final bikeNumber = bikeElement.getAttribute('number');
              if (bikeNumber != null && bikeNumber.isNotEmpty) {
                bikeLocations[bikeNumber] = BikeLocation(
                  bikeNumber: bikeNumber,
                  position: placeLatLng,
                );
              }
            }
          } catch (e) {
            // print(
            //   'Fehler beim Parsen der Koordinaten oder Bike-ID für ein Place: $e',
            // );
          }
        }
      }
    }
    return bikeLocations;
  }
}
