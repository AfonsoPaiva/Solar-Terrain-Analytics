import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../models/saved_site.dart';

class MobileDashboard extends StatefulWidget {
  const MobileDashboard({super.key});

  @override
  State<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<MobileDashboard>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _tabController;
  
  LatLng? _selectedLocation;
  Map<String, dynamic>? _solarData;
  List<SavedSite> _savedSites = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Map'),
            Tab(icon: Icon(Icons.list), text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMapTab(),
          _buildSavedSitesTab(),
        ],
      ),
      floatingActionButton: _selectedLocation != null && _solarData != null
          ? FloatingActionButton.extended(
              onPressed: _saveSite,
              label: const Text('Save Site'),
              icon: const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildMapTab() {
    return Column(
      children: [
        // Instructions card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tap on the map to analyze solar potential at any location in Portugal',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        // Map
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
        // Solar data panel
        if (_selectedLocation != null) _buildSolarInfoPanel(),
      ],
    );
  }

  Widget _buildSolarInfoPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}'),
              Text('Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_solarData != null) ...[
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedSitesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Saved Sites',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSavedSites,
              ),
            ],
          ),
        ),
        Expanded(
          child: _savedSites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.solar_power_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No saved sites yet'),
                      Text('Use the map to analyze and save locations'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _savedSites.length,
                  itemBuilder: (context, index) {
                    final site = _savedSites[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.solar_power),
                        title: Text('Site ${index + 1}'),
                        subtitle: Text(
                          'Lat: ${site.latitude.toStringAsFixed(4)}, '
                          'Lng: ${site.longitude.toStringAsFixed(4)}\n'
                          'Solar: ${site.solarPotential.toStringAsFixed(1)} kWh/kWp/year',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: const Row(
                                children: [
                                  Icon(Icons.location_on),
                                  SizedBox(width: 8),
                                  Text('View on Map'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') {
                              _goToSite(site);
                            } else if (value == 'delete') {
                              _deleteSite(site.id!);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
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
    _tabController.animateTo(0); // Switch to map tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
