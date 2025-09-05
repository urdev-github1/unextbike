// ==== lib\screens\main_screen.dart ====

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../services/nextbike_api_service.dart';
import '../models/bike_location.dart';
import '../widgets/bike_map.dart';
import '../widgets/custom_marker_icon.dart';
import 'about_screen.dart'; // Import des neuen AboutScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _bikeIdController = TextEditingController();
  final MapController _mapController = MapController();

  // Speichert die aktuell gesuchte Fahrrad-ID.
  String _currentSearchBikeId = '';
  // Flag, das anzeigt, ob Daten geladen werden.
  bool _isLoading = false;
  // Speichert eine Fehlermeldung, falls ein Fehler auftritt.
  String? _errorMessage;

  // Eine Map, die alle geladenen Fahrradstandorte speichert, indiziert nach Fahrrad-ID.
  Map<String, BikeLocation> _allBikeLocations = {};
  // Speichert den gefundenen Fahrradstandort nach einer Suche.
  BikeLocation? _foundBikeLocation;
  // Eine Liste von Markierungen, die auf der Karte angezeigt werden sollen.
  List<Marker> _markers = [];

  // Anfangsposition und Zoomstufe der Karte (z.B. Köln).
  static const LatLng _initialMapCenter = LatLng(50.9381, 6.95778);
  static const double _initialMapZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadAllBikeLocations();
  }

  @override
  void dispose() {
    _bikeIdController.dispose();
    super.dispose();
  }

  /// Lädt alle Fahrradstandorte vom Nextbike API Service.
  Future<void> _loadAllBikeLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Initialisiert den Service und lädt die Daten.
      final service = NextbikeApiService();
      // Ruft die Fahrradstandorte ab und speichert sie.
      _allBikeLocations = await service.fetchBikeLocations();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Sucht nach dem Fahrrad mit der eingegebenen ID und aktualisiert die Karte.
  void _searchBike() {
    final searchId = _bikeIdController.text.trim();

    // Aktualisiert den Zustand der UI.
    setState(() {
      _currentSearchBikeId = searchId; // Speichert die gesuchte ID.
      _foundBikeLocation = null; // Setzt den gefundenen Standort zurück.
      _markers = []; // Leert die Marker-Liste.
      _errorMessage = null; // Setzt Fehlermeldungen zurück.

      // Überprüft, ob eine ID eingegeben wurde.
      if (searchId.isEmpty) {
        _errorMessage = 'Bitte geben Sie eine Fahrrad-ID ein.';
        return;
      }

      // Sucht in der geladenen Map nach der Fahrrad-ID.
      if (_allBikeLocations.containsKey(searchId)) {
        // Wenn gefunden, speichert den Standort und erstellt einen Marker.
        _foundBikeLocation = _allBikeLocations[searchId];

        // Erstellt einen Marker für die gefundene Position.
        _markers = [
          Marker(
            // Position des gefundenen Fahrrads.
            point: _foundBikeLocation!.position,
            width: 80.0,
            height: 80.0,
            // Verwendet ein benutzerdefiniertes Icon.
            child: const CustomMarkerIcon(),
          ),
        ];

        // Bewegt die Karte zur gefundenen Position und zoomt heran.
        _mapController.move(_foundBikeLocation!.position, 16.0);
      } else {
        _errorMessage = 'Fahrrad-ID "$searchId" nicht gefunden.';
      }
    });
  }

  /// Baut die Benutzeroberfläche des MainScreen auf.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('uNextBike'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          // Info-Button, der zum AboutScreen navigiert.
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            tooltip: 'Über die App',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Textfeld für die Eingabe der Fahrrad-ID.
            TextField(
              controller: _bikeIdController,
              decoration: const InputDecoration(
                labelText: 'Fahrrad-ID eingeben',
                hintText: 'z.B. 221785',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bike),
              ),
              keyboardType: TextInputType.number,
              // Ruft _searchBike auf, wenn Enter gedrückt wird.
              onSubmitted: (_) => _searchBike(),
            ),
            const SizedBox(height: 16.0),

            // Schaltfläche zum Suchen eines Fahrrads.
            ElevatedButton.icon(
              onPressed: _isLoading && _allBikeLocations.isEmpty
                  ? null
                  : _searchBike,
              icon: _isLoading && _allBikeLocations.isEmpty
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isLoading && _allBikeLocations.isEmpty
                    ? 'Lade Daten...'
                    : 'Fahrrad suchen',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24.0),

            // Anzeige von Ladeindikatoren, Fehlermeldungen oder Suchergebnissen.
            if (_isLoading && _allBikeLocations.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null && !_isLoading)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              )
            else if (_foundBikeLocation != null)
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
              const Text(
                'Geben Sie eine Fahrrad-ID ein, um den Standort auf der Karte zu finden.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24.0),

            // Erweiterter Bereich für die Karte.
            Expanded(
              child: Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: BikeMap(
                  mapController: _mapController,
                  initialMapCenter: _initialMapCenter,
                  initialMapZoom: _initialMapZoom,
                  markers: _markers,
                  isLoading: _isLoading && _allBikeLocations.isEmpty,
                  errorMessage: _errorMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
