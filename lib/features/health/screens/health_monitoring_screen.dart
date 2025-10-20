import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/health_monitoring_service.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthMonitoringScreen extends StatefulWidget {
  const HealthMonitoringScreen({super.key});

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  Map<String, dynamic> _metrics = {};
  Map<String, List<FlSpot>> _historicalData = {};
  bool _isLoading = true;
  String _error = '';
  String _selectedMetric = 'heartRate';

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final service = context.read<HealthMonitoringService>();
      
      // First request permissions if needed
      final hasPermissions = await service.requestHealthPermissions();
      if (!hasPermissions) {
        setState(() {
          _error = 'Health permissions are required to access health data. Please grant permissions in your device settings.';
          _isLoading = false;
        });
        return;
      }

      // Load current metrics
      final metrics = await service.getHealthMetrics();
      
      // Load historical data
      final historical = await service.getHistoricalHealthData();
      
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _historicalData = historical;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load health data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHealthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading health data...'),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadHealthData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHealthData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVitalSignsSection(),
                        const SizedBox(height: 24),
                        _buildActivitySection(),
                        const SizedBox(height: 24),
                        _buildBodyMetricsSection(),
                        const SizedBox(height: 24),
                        _buildHistoricalDataSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildVitalSignsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Signs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Heart Rate',
                    '${_metrics['heartRate']?.toStringAsFixed(0) ?? 0}',
                    'BPM',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Blood Pressure',
                    '${_metrics['bloodPressure']?['systolic']?.toStringAsFixed(0) ?? 0}/${_metrics['bloodPressure']?['diastolic']?.toStringAsFixed(0) ?? 0}',
                    'mmHg',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Blood Oxygen',
                    '${_metrics['bloodOxygen']?.toStringAsFixed(1) ?? 0}',
                    '%',
                    Icons.air,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Temperature',
                    '${_metrics['bodyTemperature']?.toStringAsFixed(1) ?? 0}',
                    '°C',
                    Icons.thermostat,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Steps',
                    '${_metrics['steps'] ?? 0}',
                    'steps',
                    Icons.directions_walk,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Sleep',
                    '${_metrics['sleepHours']?.toStringAsFixed(1) ?? 0}',
                    'hours',
                    Icons.bedtime,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Body Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Weight',
                    '${_metrics['weight']?.toStringAsFixed(1) ?? 0}',
                    'kg',
                    Icons.monitor_weight,
                    Colors.brown,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Height',
                    '${_metrics['height']?.toStringAsFixed(1) ?? 0}',
                    'cm',
                    Icons.height,
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              'Blood Glucose',
              '${_metrics['bloodGlucose']?.toStringAsFixed(1) ?? 0}',
              'mg/dL',
              Icons.water_drop,
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMetricSelector(),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = [
      {'id': 'heartRate', 'name': 'Heart Rate'},
      {'id': 'steps', 'name': 'Steps'},
      {'id': 'sleepHours', 'name': 'Sleep Hours'},
      {'id': 'bloodOxygen', 'name': 'Blood Oxygen'},
      {'id': 'bodyTemperature', 'name': 'Temperature'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.map((metric) {
          final isSelected = _selectedMetric == metric['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(metric['name']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMetric = metric['id']!;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = _historicalData[_selectedMetric] ?? [];
    if (spots.isEmpty) {
      return const Center(
        child: Text('No historical data available'),
      );
    }

    // Get min and max values for y-axis
    final yMin = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final yMax = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final yRange = yMax - yMin;

    // Format y-axis labels based on metric type
    String formatYValue(double value) {
      switch (_selectedMetric) {
        case 'heartRate':
          return '${value.toInt()} BPM';
        case 'steps':
          return '${value.toInt()}';
        case 'sleepHours':
          return '${value.toStringAsFixed(1)}h';
        case 'bloodOxygen':
          return '${value.toInt()}%';
        case 'bodyTemperature':
          return '${value.toStringAsFixed(1)}°C';
        default:
          return value.toStringAsFixed(1);
      }
    }

    // Format x-axis labels (days)
    String formatXValue(double value) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final index = (value * (days.length - 1) / 7).round();
      return days[index.clamp(0, days.length - 1)];
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yRange / 4,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    formatXValue(value),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yRange / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    formatYValue(value),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        minX: 0,
        maxX: 7,
        minY: yMin - (yRange * 0.1),
        maxY: yMax + (yRange * 0.1),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _getMetricColor(_selectedMetric),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getMetricColor(_selectedMetric),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _getMetricColor(_selectedMetric).withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  formatYValue(spot.y),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'heartRate':
        return Colors.red;
      case 'steps':
        return Colors.purple;
      case 'sleepHours':
        return Colors.indigo;
      case 'bloodOxygen':
        return Colors.green;
      case 'bodyTemperature':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 