import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../services/api_service.dart';
import '../../models/solar_area.dart';
import '../../widgets/solar_analysis_panel.dart';

class GoogleMapsDashboard extends StatefulWidget {
  const GoogleMapsDashboard({super.key});
  @override
  State<GoogleMapsDashboard> createState() => _GoogleMapsDashboardState();
}

class _GoogleMapsDashboardState extends State<GoogleMapsDashboard> {
  GoogleMapController? _mapController;

  // Area drawing (using Google Maps LatLng)
  final List<LatLng> _drawingPoints = [];
  List<LatLng>? _selectedArea;
  final Set<Polygon> _polygons = {};
  final Set<Circle> _heatmapCircles = {};

  // Analysis (using latlong2 LatLng for compatibility)
  List<ll.LatLng>? _selectedAreaLatLong;
  Map<String, dynamic>? _analysisData;
  bool _isAnalyzing = false;
  bool _isDrawingMode = false;
  bool _showHeatmap = true;

  // Saved terrains (using SolarArea instead of SavedSite)
  List<SolarArea> _savedAreas = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAreas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Terrain Analytics - Areas'),
        actions: [
          IconButton(
            tooltip: 'Reload saved',
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedAreas,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel
          SizedBox(
            width: 430,
            child: Column(
              children: [
                // Drawing controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
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
                ),
                const SizedBox(height: 12),
                // Instruction
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
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
                ),
                const SizedBox(height: 12),
                // Analysis panel
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SolarAnalysisPanel(
                      analysisData: _analysisData,
                      selectedLocation: null,
                      selectedArea: _selectedAreaLatLong,
                      isLoading: _isAnalyzing,
                    ),
                  ),
                ),
                if (_analysisData != null && _selectedArea != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        onPressed: _saveAreaWithName,
                        label: const Text('Save Area'),
                      ),
                    ),
                  ),
                // Saved terrains list
                SizedBox(
                  height: 240,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text('Saved Terrains', style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Reload',
                              onPressed: _loadSavedAreas,
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildSavedAreasList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Map panel
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
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
                  // Enable all interactions for web
                  zoomControlsEnabled: false, // We'll use custom controls
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  mapType: MapType.terrain,
                ),
                // Map controls
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _MapBtn(
                        icon: Icons.add,
                        onTap: () => _mapController?.animateCamera(
                          CameraUpdate.zoomIn(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MapBtn(
                        icon: Icons.remove,
                        onTap: () => _mapController?.animateCamera(
                          CameraUpdate.zoomOut(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MapBtn(
                        icon: Icons.my_location,
                        onTap: _resetView,
                      ),
                      if (_analysisData != null && _analysisData!['heatmapData'] != null) ...[
                        const SizedBox(height: 8),
                        _MapBtn(
                          icon: _showHeatmap ? Icons.visibility : Icons.visibility_off,
                          onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                        ),
                      ],
                    ],
                  ),
                ),
                // Heatmap Legend
                if (_analysisData != null && _analysisData!['heatmapData'] != null && _showHeatmap)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Light Intensity',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildLegendItem('High Light', const Color(0xFF00FF00)),
                          _buildLegendItem('Good Light', const Color(0xFF80FF00)),
                          _buildLegendItem('Medium Light', const Color(0xFFFFFF00)),
                          _buildLegendItem('Low Light', const Color(0xFFFF8000)),
                          _buildLegendItem('Poor Light', const Color(0xFFFF0000)),
                          const SizedBox(height: 8),
                          Text(
                            'Transparency = Shadow Amount',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
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

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha if not present
    }
    return Color(int.parse(hex, radix: 16));
  }

  double _getRadiusForIntensity(double intensity) {
    // Scale radius based on intensity (100-300 meters)
    return ((intensity / 2000.0) * 200 + 100).clamp(100.0, 300.0);
  }

  void _resetView() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(39.3999, -8.2245),
          zoom: 7.0,
        ),
      ),
    );
  }

  Future<void> _onMapTap(LatLng point) async {
    if (!_isDrawingMode) return;

    // Check if point is within Portugal bounds
    if (point.latitude < 36.838 || point.latitude > 42.280 ||
        point.longitude < -9.526 || point.longitude > -6.189) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location within Portugal')),
      );
      return;
    }

    setState(() {
      _drawingPoints.add(point);
      _updatePolygons();
    });
  }

  Future<void> _analyzeArea(List<ll.LatLng> polygon) async {
    setState(() => _isAnalyzing = true);

    try {
      final result = await ApiService.analyzeArea(polygon);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    }
  }

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
        final success = await ApiService.saveSitePolygon(result.trim(), _selectedAreaLatLong!);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Area saved successfully')),
          );
          _loadSavedAreas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save area')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _loadSavedAreas() async {
    try {
      final areas = await ApiService.getSavedAreas();
      setState(() => _savedAreas = areas);
    } catch (e) {
      print('Error loading saved areas: $e');
      // Fallback to saved sites if areas not available
      try {
        await ApiService.getSavedSites();
        // Convert sites to a simple display format if needed
        setState(() {
          _savedAreas = []; // Will be handled in the UI
        });
      } catch (e2) {
        print('Error loading saved sites: $e2');
      }
    }
  }

  Widget _buildSavedAreasList() {
    if (_savedAreas.isEmpty) {
      return const Center(
        child: Text('No saved areas yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _savedAreas.length,
      itemBuilder: (context, index) {
        final area = _savedAreas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(area.name),
            subtitle: Text('${area.polygon.length} points'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View on map',
                  onPressed: () => _viewAreaOnMap(area),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: () => _deleteArea(area),
                ),
              ],
            ),
            onTap: () => _viewAreaOnMap(area),
          ),
        );
      },
    );
  }

  void _viewAreaOnMap(SolarArea area) {
    // Convert latlong2 LatLng to Google Maps LatLng
    final points = area.polygon.map((p) => LatLng(p.latitude, p.longitude)).toList();
    setState(() {
      _selectedArea = points;
      _selectedAreaLatLong = area.polygon;
      _analysisData = area.detailedAnalysis;
      _isDrawingMode = false;
      _drawingPoints.clear();
      _updatePolygons();
    });

    // Update heatmap if available
    if (area.detailedAnalysis['heatmapData'] != null) {
      _updateHeatmapCircles(area.detailedAnalysis['heatmapData']);
    }

    // Center map on the area
    if (points.isNotEmpty) {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        minLat = minLat < point.latitude ? minLat : point.latitude;
        maxLat = maxLat > point.latitude ? maxLat : point.latitude;
        minLng = minLng < point.longitude ? minLng : point.longitude;
        maxLng = maxLng > point.longitude ? maxLng : point.longitude;
      }

      final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 10.0),
        ),
      );
    }
  }

  Future<void> _deleteArea(SolarArea area) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Area'),
        content: Text('Are you sure you want to delete "${area.name}"?'),
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

    if (confirm == true && area.id != null) {
      try {
        final success = await ApiService.deleteSite(area.id!);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Area deleted successfully')),
          );
          _loadSavedAreas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete area')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
