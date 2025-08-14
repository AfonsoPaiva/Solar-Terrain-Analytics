import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../models/saved_site.dart';
import '../../widgets/solar_analysis_panel.dart';

class EnhancedWebDashboard extends StatefulWidget {
  const EnhancedWebDashboard({super.key});
  @override
  State<EnhancedWebDashboard> createState() => _EnhancedWebDashboardState();
}

class _EnhancedWebDashboardState extends State<EnhancedWebDashboard> {
  final MapController _mapController = MapController();

  // Area drawing
  final List<LatLng> _drawingPoints = [];
  List<LatLng>? _selectedArea;

  // Analysis
  Map<String, dynamic>? _analysisData;
  bool _isAnalyzing = false;
  bool _isDrawingMode = false;
  bool _showHeatmap = true;  // Toggle for heatmap visibility

  // Saved terrains (sites endpoint)
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
        title: const Text('Solar Terrain Analytics - Areas'),
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
                      selectedArea: _selectedArea,
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
                              onPressed: _loadSavedSites,
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildSavedSitesList()),
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
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(39.3999, -8.2245),
                    initialZoom: 7.0,
                    minZoom: 5.5,
                    maxZoom: 19.0,
                    cameraConstraint: CameraConstraint.contain(
                      bounds: LatLngBounds(
                        const LatLng(36.838, -9.526),
                        const LatLng(42.280, -6.189),
                      ),
                    ),
                    // Simple interaction options for web
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | 
                             InteractiveFlag.pinchZoom | 
                             InteractiveFlag.doubleTapZoom | 
                             InteractiveFlag.scrollWheelZoom,
                    ),
                    onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.flutter_solar_terrain_analytics',
                        ),
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
                        if (_selectedArea != null)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: _selectedArea!,
                                color: Colors.green.withValues(alpha: 0.25),
                                borderColor: Colors.green,
                                borderStrokeWidth: 3,
                              ),
                            ],
                          ),
                        // Heatmap layer for light intensity visualization
                        if (_analysisData != null && _analysisData!['heatmapData'] != null && _showHeatmap)
                          CircleLayer(
                            circles: _buildHeatmapCircles(_analysisData!['heatmapData']),
                          ),
                        MarkerLayer(
                          markers: [
                            ..._drawingPoints.map((p) => Marker(
                                  point: p,
                                  child: const Icon(Icons.circle, color: Colors.red, size: 10),
                                )),
                          ],
                        ),
                      ],
                    ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        _MapBtn(icon: Icons.add, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                        const SizedBox(height: 8),
                        _MapBtn(icon: Icons.remove, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                        const SizedBox(height: 8),
                        _MapBtn(icon: Icons.my_location, onTap: _resetView),
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
    if (_isDrawingMode) {
      setState(() => _drawingPoints.add(point));
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

  Future<void> _saveAreaWithName() async {
    if (_selectedArea == null) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Area'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Area Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, nameController.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final success = await ApiService.saveSitePolygon(name, _selectedArea!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Area saved' : 'Failed to save area')),
        );
        if (success) _loadSavedSites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving area: $e')),
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

  Widget _buildSavedSitesList() {
    if (_savedSites.isEmpty) {
      return const Center(child: Text('No saved areas yet'));
    }
    return ListView.builder(
      itemCount: _savedSites.length,
      itemBuilder: (context, index) {
        final site = _savedSites[index];
        return ListTile(
          leading: const Icon(Icons.area_chart),
          title: Text('Area ${index + 1}'),
          subtitle: Text('Lat: ${site.latitude.toStringAsFixed(4)}, Lng: ${site.longitude.toStringAsFixed(4)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in),
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

  void _goToLocation(LatLng location) => _mapController.move(location, 16.0);
  void _resetView() => _mapController.move(const LatLng(39.3999, -8.2245), 7.0);

  List<CircleMarker> _buildHeatmapCircles(List<dynamic> heatmapData) {
    List<CircleMarker> circles = [];
    
    for (var point in heatmapData) {
      if (point is Map<String, dynamic>) {
        double lat = point['lat']?.toDouble() ?? 0.0;
        double lng = point['lng']?.toDouble() ?? 0.0;
        double intensity = point['intensity']?.toDouble() ?? 0.0;
        double shadowFactor = point['shadowFactor']?.toDouble() ?? 1.0;
        String colorHex = point['color'] ?? '#00FF00';
        
        // Convert hex color to Flutter Color
        Color color = _hexToColor(colorHex);
        
        // Adjust opacity based on shadow factor (more shadow = more transparent)
        double opacity = 0.3 + (shadowFactor * 0.4); // 0.3 to 0.7 opacity range
        
        // Scale radius based on intensity (higher intensity = larger circle)
        double radius = 6.0 + (intensity / 2500 * 4.0); // 6-10 pixel radius range
        
        circles.add(
          CircleMarker(
            point: LatLng(lat, lng),
            radius: radius,
            color: color.withValues(alpha: opacity),
            borderColor: color.withValues(alpha: opacity + 0.2),
            borderStrokeWidth: 1.0,
          ),
        );
      }
    }
    
    return circles;
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black54, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSite(int siteId) async {
    try {
      final success = await ApiService.deleteSite(siteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Deleted' : 'Delete failed')),
        );
        if (success) _loadSavedSites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
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
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}
