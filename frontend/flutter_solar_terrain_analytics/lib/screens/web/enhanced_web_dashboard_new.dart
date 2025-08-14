import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../models/saved_site.dart';
import '../../models/solar_area.dart';
import '../../widgets/solar_analysis_panel.dart';

class EnhancedWebDashboard extends StatefulWidget {
  const EnhancedWebDashboard({super.key});

  @override
  State<EnhancedWebDashboard> createState() => _EnhancedWebDashboardState();
}

class _EnhancedWebDashboardState extends State<EnhancedWebDashboard> {
  final MapController _mapController = MapController();
  
  // Selection state
  LatLng? _selectedLocation;
  List<LatLng> _drawingPoints = [];
  List<LatLng>? _selectedArea;
  
  // Analysis state
  Map<String, dynamic>? _analysisData;
  bool _isAnalyzing = false;
  
  // Drawing state
  bool _isDrawingMode = false;
  
  // Data state
  List<SavedSite> _savedSites = [];
  List<SolarArea> _savedAreas = [];
  
  // UI state
  String _selectedTab = 'points'; // 'points' or 'areas'

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Terrain Analytics - Enhanced Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Controls and analysis
          Container(
            width: 450,
            child: Column(
              children: [
                // Mode selection tabs
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'points',
                              label: Text('Point Analysis'),
                              icon: Icon(Icons.location_on),
                            ),
                            ButtonSegment(
                              value: 'areas',
                              label: Text('Area Analysis'),
                              icon: Icon(Icons.area_chart),
                            ),
                          ],
                          selected: {_selectedTab},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _selectedTab = newSelection.first;
                              _isDrawingMode = false;
                              _drawingPoints.clear();
                              _selectedLocation = null;
                              _selectedArea = null;
                              _analysisData = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Drawing controls for area mode
                if (_selectedTab == 'areas') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (!_isDrawingMode) ...[
                          ElevatedButton.icon(
                            onPressed: _startDrawing,
                            icon: const Icon(Icons.draw),
                            label: const Text('Draw Area'),
                          ),
                        ] else ...[
                          Text('${_drawingPoints.length} points'),
                          const Spacer(),
                          TextButton(
                            onPressed: _cancelDrawing,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _drawingPoints.length >= 3 ? _completeDrawing : null,
                            child: const Text('Complete'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Instructions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTab == 'points'
                              ? 'Click on the map to analyze solar potential at specific locations'
                              : _isDrawingMode
                                  ? 'Click on the map to draw an area. Need at least 3 points.'
                                  : 'Use "Draw Area" to select and analyze custom areas',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Analysis panel
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SolarAnalysisPanel(
                      analysisData: _analysisData,
                      selectedLocation: _selectedLocation,
                      selectedArea: _selectedArea,
                      isLoading: _isAnalyzing,
                    ),
                  ),
                ),

                // Save button
                if (_analysisData != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _saveAnalysis,
                      icon: const Icon(Icons.save),
                      label: Text(_selectedTab == 'points' ? 'Save Site' : 'Save Area'),
                    ),
                  ),

                // Saved data tabs
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.location_on),
                            text: 'Sites (${_savedSites.length})',
                          ),
                          Tab(
                            icon: const Icon(Icons.area_chart),
                            text: 'Areas (${_savedAreas.length})',
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: TabBarView(
                          children: [
                            _buildSavedSitesList(),
                            _buildSavedAreasList(),
                          ],
                        ),
                      ),
                    ],
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
                initialCenter: const LatLng(39.3999, -8.2245),
                initialZoom: 7.0,
                minZoom: 6.0,
                maxZoom: 18.0,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    const LatLng(36.838, -9.526),
                    const LatLng(42.280, -6.189),
                  ),
                ),
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_solar_terrain_analytics',
                ),
                
                // Saved areas polygons
                PolygonLayer(
                  polygons: _savedAreas.map((area) => Polygon(
                    points: area.polygon,
                    color: Colors.blue.withValues(alpha: 0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  )).toList(),
                ),
                
                // Current drawing polygon
                if (_drawingPoints.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _drawingPoints,
                        color: Colors.red.withValues(alpha: 0.3),
                        borderColor: Colors.red,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                
                // Selected area polygon
                if (_selectedArea != null)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _selectedArea!,
                        color: Colors.green.withValues(alpha: 0.3),
                        borderColor: Colors.green,
                        borderStrokeWidth: 3,
                      ),
                    ],
                  ),
                
                // Markers
                MarkerLayer(
                  markers: [
                    // Selected location
                    if (_selectedLocation != null)
                      Marker(
                        point: _selectedLocation!,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    
                    // Drawing points
                    ..._drawingPoints.map((point) => Marker(
                      point: point,
                      child: const Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 12,
                      ),
                    )),
                    
                    // Saved sites
                    ..._savedSites.map((site) => Marker(
                      point: LatLng(site.latitude, site.longitude),
                      child: const Icon(
                        Icons.solar_power,
                        color: Colors.orange,
                        size: 30,
                      ),
                    )),
                    
                    // Saved areas centers
                    ..._savedAreas.map((area) => Marker(
                      point: area.center,
                      child: const Icon(
                        Icons.area_chart,
                        color: Colors.blue,
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

  void _startDrawing() {
    setState(() {
      _isDrawingMode = true;
      _drawingPoints.clear();
      _selectedArea = null;
      _analysisData = null;
    });
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawingMode = false;
      _drawingPoints.clear();
    });
  }

  void _completeDrawing() {
    if (_drawingPoints.length >= 3) {
      setState(() {
        _selectedArea = List.from(_drawingPoints);
        _isDrawingMode = false;
        _drawingPoints.clear();
      });
      _analyzeArea(_selectedArea!);
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    if (point.latitude < 36.838 || point.latitude > 42.280 || 
        point.longitude < -9.526 || point.longitude > -6.189) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location within Portugal')),
        );
      }
      return;
    }

    if (_selectedTab == 'areas' && _isDrawingMode) {
      setState(() {
        _drawingPoints.add(point);
      });
    } else if (_selectedTab == 'points') {
      setState(() {
        _selectedLocation = point;
        _selectedArea = null;
        _analysisData = null;
        _isAnalyzing = true;
      });
      await _analyzePoint(point);
    }
  }

  Future<void> _analyzePoint(LatLng point) async {
    try {
      // Use small square polygon around point for area-based estimate via POST
      const delta = 0.0005; // ~55m
      final polygon = [
        LatLng(point.latitude + delta, point.longitude - delta),
        LatLng(point.latitude + delta, point.longitude + delta),
        LatLng(point.latitude - delta, point.longitude + delta),
        LatLng(point.latitude - delta, point.longitude - delta),
      ];
      final data = await ApiService.getSolarEstimatePolygon(polygon);
      if (mounted) {
        setState(() {
          _analysisData = data;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing point: $e')),
        );
      }
    }
  }

  Future<void> _analyzeArea(List<LatLng> polygon) async {
    setState(() => _isAnalyzing = true);
    
    try {
      final data = await ApiService.analyzeArea(polygon);
      if (mounted) {
        setState(() {
          _analysisData = data;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing area: $e')),
        );
      }
    }
  }

  Future<void> _saveAnalysis() async {
    if (_selectedTab == 'points' && _selectedLocation != null && _analysisData != null) {
      await _saveSite();
    } else if (_selectedTab == 'areas' && _selectedArea != null && _analysisData != null) {
      await _saveAreaWithName();
    }
  }

  Future<void> _saveSite() async {
    if (_selectedLocation == null || _analysisData == null) return;

    try {
      final success = await ApiService.saveSitePolygon('Terreno', [
        LatLng(_selectedLocation!.latitude + 0.0005, _selectedLocation!.longitude - 0.0005),
        LatLng(_selectedLocation!.latitude + 0.0005, _selectedLocation!.longitude + 0.0005),
        LatLng(_selectedLocation!.latitude - 0.0005, _selectedLocation!.longitude + 0.0005),
        LatLng(_selectedLocation!.latitude - 0.0005, _selectedLocation!.longitude - 0.0005),
      ]);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Site saved successfully!')),
          );
          _loadSavedData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save site')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving site: $e')),
        );
      }
    }
  }

  Future<void> _saveAreaWithName() async {
    if (_selectedArea == null || _analysisData == null) return;

    final nameController = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Area'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Area Name',
              hintText: 'Enter a name for this area',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      try {
        final success = await ApiService.saveArea(name, _selectedArea!, _analysisData!);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Area saved successfully!')),
            );
            _loadSavedData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save area')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving area: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final sites = await ApiService.getSavedSites();
      final areas = await ApiService.getSavedAreas();
      
      if (mounted) {
        setState(() {
          _savedSites = sites;
          _savedAreas = areas;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved data: $e')),
        );
      }
    }
  }

  Widget _buildSavedSitesList() {
    if (_savedSites.isEmpty) {
      return const Center(child: Text('No saved sites yet'));
    }

    return ListView.builder(
      itemCount: _savedSites.length,
      itemBuilder: (context, index) {
        final site = _savedSites[index];
        return ListTile(
          leading: const Icon(Icons.solar_power),
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
                onPressed: () => _goToLocation(LatLng(site.latitude, site.longitude)),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteSite(site.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedAreasList() {
    if (_savedAreas.isEmpty) {
      return const Center(child: Text('No saved areas yet'));
    }

    return ListView.builder(
      itemCount: _savedAreas.length,
      itemBuilder: (context, index) {
        final area = _savedAreas[index];
        return ListTile(
          leading: const Icon(Icons.area_chart),
          title: Text(area.name),
          subtitle: Text(
            'Size: ${area.totalArea.toStringAsFixed(0)} m²\n'
            'Solar: ${area.averageSolarPotential.toStringAsFixed(1)} kWh/kWp/year',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () => _goToArea(area),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteArea(area.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToLocation(LatLng location) {
    _mapController.move(location, 15.0);
  }

  void _goToArea(SolarArea area) {
    _mapController.fitCamera(CameraFit.bounds(bounds: area.bounds, padding: const EdgeInsets.all(50)));
  }

  Future<void> _deleteSite(int siteId) async {
    try {
      final success = await ApiService.deleteSite(siteId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Site deleted successfully!')),
          );
          _loadSavedData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete site')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting site: $e')),
        );
      }
    }
  }

  Future<void> _deleteArea(int areaId) async {
    try {
      final success = await ApiService.deleteArea(areaId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Area deleted successfully!')),
          );
          _loadSavedData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete area')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting area: $e')),
        );
      }
    }
  }
}
