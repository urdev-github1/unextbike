// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../services/nextbike_api_service.dart';
import '../models/bike_location.dart';
import '../widgets/bike_map.dart'; // Import des neuen BikeMap-Widgets
import '../widgets/custom_marker_icon.dart'; // Import des neuen CustomMarkerIcon-Widgets

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _bikeIdController = TextEditingController();
  final MapController _mapController = MapController();

  String _currentSearchBikeId = '';
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, BikeLocation> _allBikeLocations = {};
  BikeLocation? _foundBikeLocation;
  List<Marker> _markers = [];

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

  Future<void> _loadAllBikeLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = NextbikeApiService();
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

  void _searchBike() {
    final searchId = _bikeIdController.text.trim();
    setState(() {
      _currentSearchBikeId = searchId;
      _foundBikeLocation = null;
      _markers = [];
      _errorMessage = null;

      if (searchId.isEmpty) {
        _errorMessage = 'Bitte geben Sie eine Fahrrad-ID ein.';
        return;
      }

      if (_allBikeLocations.containsKey(searchId)) {
        _foundBikeLocation = _allBikeLocations[searchId];

        _markers = [
          Marker(
            point: _foundBikeLocation!.position,
            width: 80.0,
            height: 80.0,
            child:
                const CustomMarkerIcon(), // Verwendung des ausgelagerten Widgets
          ),
        ];

        _mapController.move(_foundBikeLocation!.position, 16.0);
      } else {
        _errorMessage = 'Fahrrad-ID "$searchId" nicht gefunden.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('uNextBike'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _bikeIdController,
              decoration: const InputDecoration(
                labelText: 'Fahrrad-ID eingeben',
                hintText: 'z.B. 221785',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bike),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _searchBike(),
            ),
            const SizedBox(height: 16.0),
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

            // OpenStreetMap Integration mit dem neuen BikeMap-Widget
            Expanded(
              child: Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: BikeMap(
                  mapController: _mapController,
                  initialMapCenter: _initialMapCenter,
                  initialMapZoom: _initialMapZoom,
                  markers: _markers,
                  // Parameter für den Ladezustand und Fehlermeldungen werden an BikeMap übergeben
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
