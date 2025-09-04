// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // Für LatLng-Objekte
import 'package:flutter_map/flutter_map.dart'; // Für OpenStreetMap-Anzeige und Marker

import '../services/nextbike_api_service.dart'; // Unser API-Service
import '../models/bike_location.dart'; // Unser Datenmodell für BikeLocation

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _bikeIdController = TextEditingController();
  final MapController _mapController =
      MapController(); // Controller für die FlutterMap

  String _currentSearchBikeId =
      ''; // Die ID, die aktuell gesucht oder gefunden wurde
  bool _isLoading = false; // Zeigt an, ob Daten geladen werden
  String? _errorMessage; // Speichert Fehlermeldungen für die Anzeige

  // Speichert alle von der API geladenen Fahrradstandorte
  // Schlüssel: Fahrrad-ID (String), Wert: BikeLocation-Objekt
  Map<String, BikeLocation> _allBikeLocations = {};

  // Speichert den Standort des aktuell gefundenen Fahrrads
  BikeLocation? _foundBikeLocation;

  // Liste der Marker, die auf der Karte angezeigt werden sollen
  List<Marker> _markers = [];

  // Standard-Mittelpunkt und Zoomlevel für die Karte (z.B. Köln-Zentrum)
  static const LatLng _initialMapCenter = LatLng(50.9381, 6.95778);
  static const double _initialMapZoom = 12.0;

  @override
  void initState() {
    super.initState();
    // Beim Start der App alle Fahrradstandorte von der API laden
    _loadAllBikeLocations();
  }

  @override
  void dispose() {
    // Controller freigeben, um Speicherlecks zu vermeiden
    _bikeIdController.dispose();
    super.dispose();
  }

  /// Lädt alle Fahrradstandorte von der Next-Bike API.
  /// Setzt Ladezustände und behandelt Fehler.
  Future<void> _loadAllBikeLocations() async {
    setState(() {
      _isLoading = true; // Ladezustand aktivieren
      _errorMessage = null; // Vorherige Fehlermeldungen zurücksetzen
    });
    try {
      final service = NextbikeApiService();
      _allBikeLocations = await service.fetchBikeLocations();
      print('Alle Standorte geladen: ${_allBikeLocations.length} Fahrräder');
      // Nach erfolgreichem Laden, falls noch kein Fahrrad gesucht wurde,
      // bleibt die Karte auf dem initialen Mittelpunkt.
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Fehlermeldung speichern
        print('Fehler beim Laden der Standorte: $_errorMessage');
      });
    } finally {
      setState(() {
        _isLoading = false; // Ladezustand deaktivieren
      });
    }
  }

  /// Sucht nach einer Fahrrad-ID und aktualisiert die Karte und den UI-Status.
  void _searchBike() {
    final searchId = _bikeIdController.text.trim(); // Eingegebene ID bereinigen
    setState(() {
      _currentSearchBikeId = searchId;
      _foundBikeLocation = null; // Vorheriges Ergebnis löschen
      _markers = []; // Vorherige Marker von der Karte entfernen
      _errorMessage = null; // Vorherige Fehlermeldung löschen

      if (searchId.isEmpty) {
        _errorMessage = 'Bitte geben Sie eine Fahrrad-ID ein.';
        return;
      }

      // Prüfen, ob die eingegebene ID in unseren geladenen Daten vorhanden ist
      if (_allBikeLocations.containsKey(searchId)) {
        _foundBikeLocation =
            _allBikeLocations[searchId]; // Gefundenen Standort speichern

        // Marker für das gefundene Fahrrad erstellen
        _markers = [
          Marker(
            point: _foundBikeLocation!.position, // Position des Fahrrads
            width: 80.0,
            height: 80.0,
            child: const Icon(
              // Visuelle Darstellung des Markers (roter Push-Pin)
              Icons.location_on,
              color: Colors.red,
              size: 40.0,
            ),
          ),
        ];

        // Karte auf den gefundenen Punkt zentrieren und Zoom anpassen
        _mapController.move(
          _foundBikeLocation!.position,
          16.0,
        ); // Zoomstufe 16 für gute Detailansicht

        print(
          'Fahrrad $searchId gefunden: Lat ${_foundBikeLocation!.position.latitude}, Lng ${_foundBikeLocation!.position.longitude}',
        );
      } else {
        // Fahrrad-ID nicht gefunden
        _errorMessage = 'Fahrrad-ID "$searchId" nicht gefunden.';
        print('Fahrrad-ID "$searchId" nicht gefunden.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('uNextBike'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white, // Textfarbe der AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Eingabefeld für die Fahrrad-ID
            TextField(
              controller: _bikeIdController,
              decoration: const InputDecoration(
                labelText: 'Fahrrad-ID eingeben',
                hintText: 'z.B. 221785',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bike),
              ),
              keyboardType:
                  TextInputType.number, // Nur numerische Eingabe erlauben
              onSubmitted: (_) =>
                  _searchBike(), // Suche auch bei Drücken der Enter-Taste auslösen
            ),
            const SizedBox(height: 16.0),
            // Suchbutton
            ElevatedButton.icon(
              // Button ist deaktiviert, solange Daten geladen werden
              onPressed: _isLoading && _allBikeLocations.isEmpty
                  ? null
                  : _searchBike,
              icon: _isLoading && _allBikeLocations.isEmpty
                  ? const SizedBox(
                      // Kleiner Ladeindikator im Button
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search), // Such-Icon
              label: Text(
                _isLoading && _allBikeLocations.isEmpty
                    ? 'Lade Daten...'
                    : 'Fahrrad suchen',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                backgroundColor:
                    Colors.blueAccent, // Hintergrundfarbe des Buttons
                foregroundColor: Colors.white, // Textfarbe des Buttons
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24.0),

            // Bereich für Lade-, Fehler- und Ergebnis-Anzeige
            if (_isLoading && _allBikeLocations.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              ) // Initialer Ladeindikator
            else if (_errorMessage != null &&
                !_isLoading) // Fehlermeldung anzeigen, wenn ein Fehler auftrat und nicht mehr geladen wird
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              )
            else if (_foundBikeLocation !=
                null) // Details des gefundenen Fahrrads anzeigen
              Column(
                children: [
                  const Text(
                    'Fahrrad gefunden!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ID: ${_foundBikeLocation!.bikeNumber}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Position: Lat ${_foundBikeLocation!.position.latitude}, Lng ${_foundBikeLocation!.position.longitude}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
            else if (_allBikeLocations.isNotEmpty &&
                _currentSearchBikeId.isEmpty)
              // Aufforderung zur Eingabe, wenn Daten geladen sind und noch nicht gesucht wurde
              const Text(
                'Geben Sie eine Fahrrad-ID ein, um den Standort auf der Karte zu finden.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 24.0),

            // OpenStreetMap Integration
            Expanded(
              child: Card(
                elevation: 4,
                clipBehavior: Clip
                    .antiAlias, // Sorgt für abgerundete Ecken der Karte passend zur Card
                child: _isLoading && _allBikeLocations.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      ) // Ladeindikator für die Karte, falls Daten noch nicht da sind
                    : _errorMessage != null && !_isLoading
                    ? Center(
                        // Fehleranzeige, falls Karten- oder API-Laden fehlschlägt
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Konnte Karte nicht laden aufgrund eines Fehlers: $_errorMessage',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : FlutterMap(
                        // Das eigentliche Karten-Widget
                        mapController:
                            _mapController, // Zuweisung des Controllers zur Steuerung
                        options: MapOptions(
                          initialCenter:
                              _initialMapCenter, // Startmittelpunkt der Karte
                          initialZoom: _initialMapZoom, // Startzoomstufe
                          interactionOptions: const InteractionOptions(
                            // Deaktiviert die Rotation, erlaubt alle anderen Interaktionen
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          // TileLayer für die OpenStreetMap-Kacheln
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            // WICHTIG: Ersetzen Sie 'de.yourcompany.unextbike' durch einen eindeutigen Paketnamen Ihrer App!
                            userAgentPackageName: 'de.yourcompany.unextbike',
                          ),
                          // MarkerLayer zur Anzeige der Push-Pins
                          MarkerLayer(
                            markers:
                                _markers, // Die Liste der anzuzeigenden Marker
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
