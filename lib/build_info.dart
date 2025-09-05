// lib/build_info.dart

import 'dart:io'; // Für Dateioperationen
import 'package:intl/intl.dart'; // Für die Datumsformatierung

void main() {
  final now = DateTime.now(); // Aktuelles Datum und Uhrzeit
  final formattedDate = DateFormat('dd.MM.yyyy / HH:mm:ss').format(now);

  // Inhalt der Dart-Datei mit dem Build-Timestamp
  final content =
      '''
// Diese Datei wird automatisch generiert. NICHT manuell bearbeiten.
class BuildInfo {
  static const String buildTimestamp = '$formattedDate';
}
''';

  // Pfad zur Zieldatei definieren
  final file = File('lib/generated/build_info.dart');

  // Sicherstellen, dass das Verzeichnis existiert
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }

  // Inhalt in die Zieldatei schreiben
  file.writeAsStringSync(content);
}
