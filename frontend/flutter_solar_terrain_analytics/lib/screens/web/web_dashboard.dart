import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../models/saved_site.dart';

class WebDashboard extends StatefulWidget {
  const WebDashboard({super.key});

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  Map<String, dynamic>? _solarData;
  List<SavedSite> _savedSites = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Terrain Analytics - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedSites,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Controls and info
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click on the map to analyze solar potential at any location in Portugal.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedLocation != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Location',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}'),
                          Text('Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_solarData != null) ...[
                            _buildSolarInfo(),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saveSite,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Site'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Sites',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _savedSites.isEmpty
                                ? const Center(child: Text('No saved sites yet'))
                                : ListView.builder(
                                    itemCount: _savedSites.length,
                                    itemBuilder: (context, index) {
                                      final site = _savedSites[index];
                                      return ListTile(
                                        title: Text('Site ${index + 1}'),
                                        subtitle: Text(
                                          'Lat: ${site.latitude.toStringAsFixed(4)}, '
                                          'Lng: ${site.longitude.toStringAsFixed(4)}\n'
                                          'Solar: ${site.solarPotential.toStringAsFixed(1)} kWh/kWp/year',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.location_on),
                                              onPressed: () => _goToSite(site),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => _deleteSite(site.id!),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right panel - Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(39.3999, -8.2245), // Portugal center
                initialZoom: 7.0,
                minZoom: 6.0,
                maxZoom: 18.0,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    const LatLng(36.838, -9.526), // Southwest Portugal
                    const LatLng(42.280, -6.189), // Northeast Portugal
                  ),
                ),
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_solar_terrain_analytics',
                ),
                MarkerLayer(
                  markers: [
                    if (_selectedLocation != null)
                      Marker(
                        point: _selectedLocation!,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ..._savedSites.map((site) => Marker(
                      point: LatLng(site.latitude, site.longitude),
                      child: const Icon(
                        Icons.solar_power,
                        color: Colors.orange,
                        size: 30,
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solar Analysis',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('Annual Potential: ${_solarData!['annualPotential']?.toStringAsFixed(1) ?? 'N/A'} kWh/kWp'),
        Text('Optimal Tilt: ${_solarData!['optimalTilt']?.toStringAsFixed(1) ?? 'N/A'}°'),
        Text('Optimal Azimuth: ${_solarData!['optimalAzimuth']?.toStringAsFixed(1) ?? 'N/A'}°'),
        Text('Location: ${_solarData!['location'] ?? 'N/A'}'),
      ],
    );
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    // Check if the point is within Portugal bounds
    if (point.latitude < 36.838 || point.latitude > 42.280 || 
        point.longitude < -9.526 || point.longitude > -6.189) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location within Portugal')),
        );
      }
      return;
    }

    setState(() {
      _selectedLocation = point;
      _isLoading = true;
      _solarData = null;
    });

    try {
      final data = await ApiService.getSolarEstimatePolygon([
        LatLng(point.latitude + 0.0005, point.longitude - 0.0005),
        LatLng(point.latitude + 0.0005, point.longitude + 0.0005),
        LatLng(point.latitude - 0.0005, point.longitude + 0.0005),
        LatLng(point.latitude - 0.0005, point.longitude - 0.0005),
      ]);
      if (mounted) {
        setState(() {
          _solarData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting solar data: $e')),
        );
      }
    }
  }

  Future<void> _loadSavedSites() async {
    try {
      final sites = await ApiService.getSavedSites();
      if (mounted) {
        setState(() => _savedSites = sites);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved sites: $e')),
        );
      }
    }
  }

  Future<void> _saveSite() async {
    if (_selectedLocation == null || _solarData == null) return;

    try {
      await ApiService.saveSitePolygon('Terreno', [
        LatLng(_selectedLocation!.latitude + 0.0005, _selectedLocation!.longitude - 0.0005),
        LatLng(_selectedLocation!.latitude + 0.0005, _selectedLocation!.longitude + 0.0005),
        LatLng(_selectedLocation!.latitude - 0.0005, _selectedLocation!.longitude + 0.0005),
        LatLng(_selectedLocation!.latitude - 0.0005, _selectedLocation!.longitude - 0.0005),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site saved successfully!')),
        );
        _loadSavedSites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving site: $e')),
        );
      }
    }
  }

  Future<void> _deleteSite(int siteId) async {
    try {
      await ApiService.deleteSite(siteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site deleted successfully!')),
        );
        _loadSavedSites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting site: $e')),
        );
      }
    }
  }

  void _goToSite(SavedSite site) {
    _mapController.move(LatLng(site.latitude, site.longitude), 12.0);
  }
}
