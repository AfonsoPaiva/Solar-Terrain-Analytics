import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AreaDrawingWidget extends StatefulWidget {
  final MapController mapController;
  final Function(List<LatLng>) onAreaCompleted;
  final VoidCallback? onCancel;

  const AreaDrawingWidget({
    super.key,
    required this.mapController,
    required this.onAreaCompleted,
    this.onCancel,
  });

  @override
  State<AreaDrawingWidget> createState() => _AreaDrawingWidgetState();
}

class _AreaDrawingWidgetState extends State<AreaDrawingWidget> {
  final List<LatLng> _polygonPoints = [];
  bool _isDrawing = false;

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _polygonPoints.clear();
    });
  }

  void _addPoint(LatLng point) {
    if (_isDrawing) {
      setState(() {
        _polygonPoints.add(point);
      });
    }
  }

  void _completeArea() {
    if (_polygonPoints.length >= 3) {
      widget.onAreaCompleted(_polygonPoints);
      setState(() {
        _isDrawing = false;
        _polygonPoints.clear();
      });
    }
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawing = false;
      _polygonPoints.clear();
    });
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drawing controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (!_isDrawing) ...[
                ElevatedButton.icon(
                  onPressed: _startDrawing,
                  icon: const Icon(Icons.draw),
                  label: const Text('Draw Area'),
                ),
              ] else ...[
                Text(
                  '${_polygonPoints.length} points selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _cancelDrawing,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _polygonPoints.length >= 3 ? _completeArea : null,
                  child: const Text('Complete'),
                ),
              ],
            ],
          ),
        ),
        // Instructions
        if (_isDrawing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap on the map to add points. You need at least 3 points to create an area.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Map overlay for drawing
        Expanded(
          child: GestureDetector(
            onTapUp: (details) {
              // Tap handling left to parent via map onTap; this gesture layer is a placeholder.
            },
            child: Container(),
          ),
        ),
      ],
    );
  }

  List<LatLng> get currentPolygon => List.from(_polygonPoints);
  bool get isDrawing => _isDrawing;

  void addPointFromMap(LatLng point) {
    _addPoint(point);
  }
}
