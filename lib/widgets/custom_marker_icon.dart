// lib/widgets/custom_marker_icon.dart

import 'package:flutter/material.dart';

/// Ein benutzerdefiniertes Widget, das als Marker-Icon auf der Karte dient.
class CustomMarkerIcon extends StatelessWidget {
  const CustomMarkerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    //return const Icon(Icons.location_on, color: Colors.red, size: 40.0);
    return const Icon(Icons.push_pin, color: Colors.red, size: 40.0);
  }
}
