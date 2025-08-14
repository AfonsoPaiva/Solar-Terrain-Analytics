import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class SolarAnalysisPanel extends StatelessWidget {
  final Map<String, dynamic>? analysisData;
  final LatLng? selectedLocation;
  final List<LatLng>? selectedArea;
  final bool isLoading;

  const SolarAnalysisPanel({
    super.key,
    this.analysisData,
    this.selectedLocation,
    this.selectedArea,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing solar potential...'),
            ],
          ),
        ),
      );
    }

    if (analysisData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Select a point or draw an area to analyze solar potential'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Solar Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Basic solar data
            Text(
              'Basic Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Area:', '${analysisData!['areaM2']?.toStringAsFixed(1) ?? 'N/A'} m²'),
            _buildInfoRow('Usable Area:', '${analysisData!['usableAreaM2']?.toStringAsFixed(1) ?? 'N/A'} m²'),
            _buildInfoRow('System Size:', '${analysisData!['assumedSystemKWp']?.toStringAsFixed(2) ?? 'N/A'} kWp'),
            _buildInfoRow('Annual Energy:', '${analysisData!['annualEnergyKWh']?.toStringAsFixed(0) ?? 'N/A'} kWh'),
            
            const SizedBox(height: 16),
            
            // Enhanced analysis data
            if (analysisData!['enhancedAnalysisData'] != null) ...[
              Text(
                'Enhanced Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildEnhancedAnalysis(analysisData!['enhancedAnalysisData']),
            ],
            
            const SizedBox(height: 16),
            
            // Weather data
            if (analysisData!['enhancedAnalysisData']?['monthlyWeatherData'] != null) ...[
              Text(
                'Weather Impact',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildWeatherInfo(analysisData!['enhancedAnalysisData']['monthlyWeatherData']),
            ],
            
            const SizedBox(height: 16),
            
            // Recommendations
            if (analysisData!['enhancedAnalysisData']?['recommendations'] != null) ...[
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildRecommendations(analysisData!['enhancedAnalysisData']['recommendations']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildSeasonalChart(Map<String, dynamic> seasonalData) {
    final seasons = ['Spring', 'Summer', 'Autumn', 'Winter'];
    final values = [
      seasonalData['spring']?.toDouble() ?? 0.0,
      seasonalData['summer']?.toDouble() ?? 0.0,
      seasonalData['autumn']?.toDouble() ?? 0.0,
      seasonalData['winter']?.toDouble() ?? 0.0,
    ];

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: List.generate(seasons.length, (index) {
        final percentage = maxValue > 0 ? values[index] / maxValue : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(seasons[index]),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                ),
              ),
              const SizedBox(width: 8),
              Text('${values[index].toStringAsFixed(0)} kWh'),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShadowInfo(Map<String, dynamic> shadowData) {
    return Column(
      children: [
        _buildInfoRow(
          'Shadow Coverage',
          '${((shadowData['averageShading'] ?? 0.0) * 100).toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Peak Shadow Hours',
          'N/A',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Shadow Impact',
          '${((shadowData['averageShading'] ?? 0.0) * 100).toStringAsFixed(1)}% reduction',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Morning Shading',
          '${((shadowData['morningShading'] ?? 0.0) * 100).toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Evening Shading',
          '${((shadowData['eveningShading'] ?? 0.0) * 100).toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Noon Shading',
          '${((shadowData['noonShading'] ?? 0.0) * 100).toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Winter Shading',
          '${((shadowData['winterShading'] ?? 0.0) * 100).toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Summer Shading',
          '${((shadowData['summerShading'] ?? 0.0) * 100).toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildLightProductionChart(Map<String, dynamic> lightData) {
    final hours = lightData['hourlyProduction'] as List? ?? [];
    
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (hour) {
          final production = hour < hours.length ? 
              (hours[hour] as num?)?.toDouble() ?? 0.0 : 0.0;
          final maxProduction = hours.isNotEmpty ? 
              hours.map((e) => (e as num).toDouble()).reduce((a, b) => a > b ? a : b) : 1.0;
          final height = maxProduction > 0 ? (production / maxProduction) * 80 : 0.0;
          
          return Expanded(
            child: Container(
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedAnalysis(Map<String, dynamic> analysisData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall efficiency factors
        _buildInfoRow('Weather Factor', '${((analysisData['overallWeatherFactor'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Shading Factor', '${((analysisData['overallShadingFactor'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Combined Efficiency', '${((analysisData['combinedEfficiencyFactor'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        
        const SizedBox(height: 8),
        
        // Google Solar data availability
        if (analysisData['googleSolarDataAvailable'] == true)
          _buildInfoRow('Google Solar Data', 'Available ✓')
        else
          _buildInfoRow('Google Solar Data', 'Using PVGIS fallback'),
        
        // Shadow analysis
        const SizedBox(height: 8),
        Text(
          'Shadow Analysis',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        _buildInfoRow('Average Shading', '${((analysisData['averageShading'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Morning Shading', '${((analysisData['morningShading'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Noon Shading', '${((analysisData['noonShading'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Evening Shading', '${((analysisData['eveningShading'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Winter Shading', '${((analysisData['winterShading'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Summer Shading', '${((analysisData['summerShading'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildWeatherInfo(List<dynamic> monthlyWeatherData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Weather Data Points', '${monthlyWeatherData.length} months'),
        
        // Find best and worst months
        if (monthlyWeatherData.isNotEmpty) ...[
          const SizedBox(height: 8),
          
          // Calculate average efficiency
          Builder(
            builder: (context) {
              double avgEfficiency = monthlyWeatherData
                  .map((m) => (m['solarEfficiencyFactor'] ?? 0.0) as double)
                  .reduce((a, b) => a + b) / monthlyWeatherData.length;
              
              return _buildInfoRow('Avg. Weather Efficiency', '${(avgEfficiency * 100).toStringAsFixed(1)}%');
            }
          ),
          
          // Best month
          Builder(
            builder: (context) {
              var bestMonth = monthlyWeatherData.reduce((curr, next) => 
                (curr['solarEfficiencyFactor'] ?? 0.0) > (next['solarEfficiencyFactor'] ?? 0.0) ? curr : next);
              String bestMonthName = _getMonthName(bestMonth['month'] ?? 1);
              return _buildInfoRow('Best Month', '$bestMonthName (${((bestMonth['solarEfficiencyFactor'] ?? 0.0) * 100).toStringAsFixed(1)}%)');
            }
          ),
          
          // Worst month
          Builder(
            builder: (context) {
              var worstMonth = monthlyWeatherData.reduce((curr, next) => 
                (curr['solarEfficiencyFactor'] ?? 0.0) < (next['solarEfficiencyFactor'] ?? 0.0) ? curr : next);
              String worstMonthName = _getMonthName(worstMonth['month'] ?? 1);
              return _buildInfoRow('Worst Month', '$worstMonthName (${((worstMonth['solarEfficiencyFactor'] ?? 0.0) * 100).toStringAsFixed(1)}%)');
            }
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendations(List<dynamic> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations.map<Widget>((rec) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(rec.toString())),
            ],
          ),
        )
      ).toList(),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[(month - 1).clamp(0, 11)];
  }
}
