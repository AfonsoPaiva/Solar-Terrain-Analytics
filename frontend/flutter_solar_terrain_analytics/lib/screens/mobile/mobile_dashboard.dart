import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../services/api_service.dart';
import '../../models/saved_site.dart';
import '../../widgets/solar_analysis_panel.dart';

class MobileDashboard extends StatefulWidget {
  const MobileDashboard({super.key});
  @override
  State<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<MobileDashboard> {
  GoogleMapController? _mapController;

  // EXACTLY THE SAME variables as web
  final List<LatLng> _drawingPoints = [];
  List<LatLng>? _selectedArea;
  final Set<Polygon> _polygons = {};
  final Set<Circle> _heatmapCircles = {};

  List<ll.LatLng>? _selectedAreaLatLong;
  Map<String, dynamic>? _analysisData;
  bool _isAnalyzing = false;
  bool _isDrawingMode = false;
  bool _showHeatmap = true;

  List<SavedSite> _savedSites = [];

  @override
  void initState() {
    super.initState();
    _loadSavedSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Terrain Analytics - Mobile'),
        actions: [
          IconButton(
            tooltip: 'Reload saved',
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedSites,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Left panel content adapted for mobile - EXACTLY like web but vertical
          Container(
            height: 350,
            color: Colors.grey[50],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drawing controls - EXACTLY like web
                  Row(
                    children: [
                      if (!_isDrawingMode) ...[
                        ElevatedButton.icon(
                          onPressed: _startDrawing,
                          icon: const Icon(Icons.draw),
                          label: const Text('Draw Area'),
                        ),
                      ] else ...[
                        Text('${_drawingPoints.length} pts'),
                        const Spacer(),
                        TextButton(onPressed: _cancelDrawing, child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _drawingPoints.length >= 3 ? _completeDrawing : null,
                          child: const Text('Complete'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Instruction - EXACTLY like web
                  Material(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isDrawingMode
                                  ? 'Click map to add vertices. Minimum 3 points then press Complete.'
                                  : 'Press "Draw Area" then click the map to outline your terrain.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Analysis panel - EXACTLY like web
                  SolarAnalysisPanel(
                    analysisData: _analysisData,
                    selectedLocation: null,
                    selectedArea: _selectedAreaLatLong,
                    isLoading: _isAnalyzing,
                  ),
                  
                  // Save button - EXACTLY like web
                  if (_analysisData != null && _selectedArea != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          onPressed: _saveAreaWithName,
                          label: const Text('Save Area'),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Saved terrains list - Compact for mobile
                  Text('Saved Terrains', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _buildSavedSitesList(),
                  ),
                ],
              ),
            ),
          ),
          
          // Map panel - EXACTLY like web
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(39.3999, -8.2245), // Portugal center
                zoom: 7.0,
              ),
              onTap: _onMapTap,
              polygons: _polygons,
              circles: _showHeatmap ? _heatmapCircles : {},
              // Same settings as web
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              mapType: MapType.terrain,
            ),
          ),
        ],
      ),
    );
  }

  // EXACTLY THE SAME methods as web
  void _startDrawing() {
    setState(() {
      _isDrawingMode = true;
      _drawingPoints.clear();
      _selectedArea = null;
      _selectedAreaLatLong = null;
      _analysisData = null;
      _updatePolygons();
    });
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawingMode = false;
      _drawingPoints.clear();
      _updatePolygons();
    });
  }

  // EXACTLY like web - auto-analyze after complete
  void _completeDrawing() {
    if (_drawingPoints.length >= 3) {
      setState(() {
        _selectedArea = List.from(_drawingPoints);
        // Convert Google Maps LatLng to latlong2 LatLng for API calls
        _selectedAreaLatLong = _drawingPoints.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
        _isDrawingMode = false;
        _updatePolygons();
      });
      _analyzeArea(_selectedAreaLatLong!);
    }
  }

  // EXACTLY like web
  void _updatePolygons() {
    _polygons.clear();
    
    // Drawing polygon (red)
    if (_drawingPoints.isNotEmpty) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('drawing'),
          points: _drawingPoints,
          fillColor: Colors.red.withValues(alpha: 0.3),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );
    }
    
    // Selected area polygon (green)
    if (_selectedArea != null) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('selected'),
          points: _selectedArea!,
          fillColor: Colors.green.withValues(alpha: 0.25),
          strokeColor: Colors.green,
          strokeWidth: 3,
        ),
      );
    }
  }

  // EXACTLY like web
  void _updateHeatmapCircles(List<dynamic> heatmapData) {
    _heatmapCircles.clear();
    
    for (int i = 0; i < heatmapData.length; i++) {
      final point = heatmapData[i];
      final intensity = point['intensity']?.toDouble() ?? 0.0;
      final shadowFactor = point['shadowFactor']?.toDouble() ?? 1.0;
      final colorHex = point['color'] as String? ?? '#FFFF00';
      
      // Convert hex color to Color
      final color = _hexToColor(colorHex);
      final alpha = (1.0 - shadowFactor).clamp(0.3, 0.8);
      
      _heatmapCircles.add(
        Circle(
          circleId: CircleId('heatmap_$i'),
          center: LatLng(
            point['lat']?.toDouble() ?? 0.0,
            point['lng']?.toDouble() ?? 0.0,
          ),
          radius: _getRadiusForIntensity(intensity),
          fillColor: color.withValues(alpha: alpha),
          strokeColor: color.withValues(alpha: alpha + 0.2),
          strokeWidth: 1,
        ),
      );
    }
  }

  // EXACTLY like web
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha if not present
    }
    return Color(int.parse(hex, radix: 16));
  }

  // EXACTLY like web
  double _getRadiusForIntensity(double intensity) {
    // Scale radius based on intensity (100-300 meters)
    return ((intensity / 2000.0) * 200 + 100).clamp(100.0, 300.0);
  }

  // EXACTLY like web
  Future<void> _onMapTap(LatLng point) async {
    if (!_isDrawingMode) return;

    // Check if point is within Portugal bounds
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
      _drawingPoints.add(point);
      _updatePolygons();
    });
  }

  // EXACTLY like web
  Future<void> _analyzeArea(List<ll.LatLng> polygon) async {
    setState(() => _isAnalyzing = true);

    try {
      // Convert latlong2 LatLng to Google Maps LatLng for API call
      final googleMapsPolygon = polygon.map((p) => LatLng(p.latitude, p.longitude)).toList();
      final result = await ApiService.analyzeArea(googleMapsPolygon);

      setState(() {
        _analysisData = result;
        _isAnalyzing = false;
      });

      // Update heatmap if data available
      if (result != null && result['heatmapData'] != null) {
        _updateHeatmapCircles(result['heatmapData']);
        setState(() {});
      }

      print('Analysis result: $result');
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  // EXACTLY like web
  Future<void> _saveAreaWithName() async {
    if (_selectedAreaLatLong == null || _analysisData == null) return;

    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Area'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Area Name',
            hintText: 'Enter a name for this area',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        // Convert latlong2 LatLng to Google Maps LatLng for API call
        final googleMapsPolygon = _selectedAreaLatLong!.map((p) => LatLng(p.latitude, p.longitude)).toList();
        final success = await ApiService.saveSitePolygon(result.trim(), googleMapsPolygon);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Area saved successfully')),
            );
          }
          _loadSavedSites();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save area')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
    }
  }

  // EXACTLY like web
  Future<void> _loadSavedSites() async {
    try {
      final sites = await ApiService.getSavedSites();
      setState(() => _savedSites = sites);
    } catch (e) {
      print('Error loading saved sites: $e');
      setState(() => _savedSites = []);
    }
  }

  // Adapted for mobile but same logic as web
  Widget _buildSavedSitesList() {
    if (_savedSites.isEmpty) {
      return const Center(
        child: Text('No saved sites yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _savedSites.length,
      itemBuilder: (context, index) {
        final site = _savedSites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.green),
            title: Text('Site ${site.id ?? 'Unknown'}'),
            subtitle: Text('Solar: ${site.solarPotential.toStringAsFixed(1)} kWh/m²'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View on map',
                  onPressed: () => _viewSiteOnMap(site),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: () => _deleteSite(site),
                ),
              ],
            ),
            onTap: () => _viewSiteOnMap(site),
          ),
        );
      },
    );
  }

  // EXACTLY like web
  void _viewSiteOnMap(SavedSite site) {
    final location = LatLng(site.latitude, site.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15.0),
      ),
    );
  }

  // EXACTLY like web
  Future<void> _deleteSite(SavedSite site) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete Site ${site.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && site.id != null) {
      try {
        final success = await ApiService.deleteSite(site.id!);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Site deleted successfully')),
            );
          }
          _loadSavedSites();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete site')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}
