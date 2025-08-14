import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../services/api_service.dart';
import '../../models/solar_area.dart';
import '../../widgets/solar_analysis_panel.dart';

class FallbackDashboard extends StatefulWidget {
  const FallbackDashboard({super.key});
  @override
  State<FallbackDashboard> createState() => _FallbackDashboardState();
}

class _FallbackDashboardState extends State<FallbackDashboard> {
  // Area drawing
  final List<ll.LatLng> _drawingPoints = [];
  List<ll.LatLng>? _selectedArea;
  
  // Analysis
  Map<String, dynamic>? _analysisData;
  bool _isAnalyzing = false;
  bool _isDrawingMode = false;
  
  // Saved areas
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
        title: const Text('Solar Terrain Analytics - Development Mode'),
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
                                  ? 'Click "Add Point" to add coordinates manually. Minimum 3 points then press Complete.'
                                  : 'Press "Draw Area" then add coordinates manually to outline your terrain.',
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
                // Saved areas list
                SizedBox(
                  height: 240,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text('Saved Areas', style: Theme.of(context).textTheme.titleMedium),
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
          // Map placeholder panel
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  // Map placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Map View - Development Mode',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configure Google Maps API key to enable interactive map',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isDrawingMode)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text('Manual Coordinate Entry', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _addTestPoint,
                                    icon: const Icon(Icons.add_location),
                                    label: const Text('Add Test Point'),
                                  ),
                                  if (_drawingPoints.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text('Points: ${_drawingPoints.length}'),
                                    for (int i = 0; i < _drawingPoints.length; i++)
                                      Text(
                                        '${i + 1}: ${_drawingPoints[i].latitude.toStringAsFixed(4)}, ${_drawingPoints[i].longitude.toStringAsFixed(4)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Selected area visualization
                  if (_selectedArea != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Area Selected',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedArea!.length} points',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
      });
      _analyzeArea(_selectedArea!);
    }
  }

  void _addTestPoint() {
    // Add some test points around Portugal
    final testPoints = [
      ll.LatLng(39.7555, -8.1439), // Leiria
      ll.LatLng(39.7556, -8.1340), // Leiria area
      ll.LatLng(39.7456, -8.1340), // Leiria area
      ll.LatLng(39.7456, -8.1439), // Leiria area
    ];
    
    if (_drawingPoints.length < testPoints.length) {
      setState(() {
        _drawingPoints.add(testPoints[_drawingPoints.length]);
      });
    }
  }

  Future<void> _analyzeArea(List<ll.LatLng> polygon) async {
    setState(() => _isAnalyzing = true);

    try {
      final result = await ApiService.analyzeArea(polygon);
      setState(() {
        _analysisData = result;
        _isAnalyzing = false;
      });
      print('Analysis result: $result');
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    }
  }

  Future<void> _saveAreaWithName() async {
    if (_selectedArea == null || _analysisData == null) return;

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
        final success = await ApiService.saveSitePolygon(result.trim(), _selectedArea!);
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
      setState(() => _savedAreas = []);
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
                  tooltip: 'View area',
                  onPressed: () => _viewArea(area),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: () => _deleteArea(area),
                ),
              ],
            ),
            onTap: () => _viewArea(area),
          ),
        );
      },
    );
  }

  void _viewArea(SolarArea area) {
    setState(() {
      _selectedArea = area.polygon;
      _analysisData = area.detailedAnalysis;
      _isDrawingMode = false;
      _drawingPoints.clear();
    });
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
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}
