// ==== lib\screens\about_screen.dart ====

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../generated/build_info.dart'; // Import der BuildInfo

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24.0,
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Über die App'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: _packageInfo == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle(context, 'Über die App'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('App-Version'),
                        subtitle: Text(
                          '${_packageInfo!.version}+${_packageInfo!.buildNumber}',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.build_circle_outlined),
                        title: const Text('Build-Zeitpunkt'),
                        subtitle: const Text(BuildInfo.buildTimestamp),
                      ),
                    ],
                  ),
                ),
                // Hier könnten weitere Sektionen oder Informationen folgen
              ],
            ),
    );
  }
}
