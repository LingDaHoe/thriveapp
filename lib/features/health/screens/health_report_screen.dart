import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/health_report_service.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<HealthReportService>().getHealthReports(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final reports = snapshot.data!;
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No health reports available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _generateReport,
                          icon: const Icon(Icons.add),
                          label: const Text('Generate Report'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportCard(report);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateReport,
        icon: const Icon(Icons.add),
        label: const Text('Generate Report'),
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Period: ${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextButton.icon(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.edit),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final period = report['period'] as Map<String, dynamic>;
    final startDate = DateTime.parse(period['start']);
    final endDate = DateTime.parse(period['end']);
    final insights = report['insights'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report: ${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareReport(report),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insights.isNotEmpty) ...[
              Text(
                'Insights',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...insights.map((insight) => _buildInsightTile(insight)),
              const SizedBox(height: 16),
            ],
            _buildHealthMetricsSection(report),
            const SizedBox(height: 16),
            _buildMedicationAdherenceSection(report),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(Map<String, dynamic> insight) {
    final severity = insight['severity'] as String;
    final color = severity == 'warning'
        ? Colors.orange
        : severity == 'positive'
            ? Colors.green
            : Colors.blue;

    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(
          severity == 'warning'
              ? Icons.warning
              : severity == 'positive'
                  ? Icons.check_circle
                  : Icons.info,
          color: color,
        ),
        title: Text(
          insight['message'] as String,
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  Widget _buildHealthMetricsSection(Map<String, dynamic> report) {
    final healthData = report['healthData'] as Map<String, dynamic>;
    final metrics = <Widget>[];

    if (healthData.containsKey('HealthDataType.STEPS')) {
      metrics.add(_buildMetricCard(
        'Steps',
        healthData['HealthDataType.STEPS'],
        Icons.directions_walk,
        Colors.blue,
      ));
    }

    if (healthData.containsKey('HealthDataType.HEART_RATE')) {
      metrics.add(_buildMetricCard(
        'Heart Rate',
        healthData['HealthDataType.HEART_RATE'],
        Icons.favorite,
        Colors.red,
      ));
    }

    if (healthData.containsKey('HealthDataType.SLEEP_ASLEEP')) {
      metrics.add(_buildMetricCard(
        'Sleep',
        healthData['HealthDataType.SLEEP_ASLEEP'],
        Icons.bedtime,
        Colors.purple,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Metrics',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    Map<String, dynamic> data,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Avg: ${data['average'].toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Min: ${data['min'].toStringAsFixed(1)} | Max: ${data['max'].toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationAdherenceSection(Map<String, dynamic> report) {
    final adherence = report['medicationAdherence'] as Map<String, dynamic>;
    final medications = adherence.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medication Adherence',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...medications.map((medication) {
          final data = medication.value as Map<String, dynamic>;
          final adherenceRate = data['adherenceRate'] as double;

          return Card(
            child: ListTile(
              title: Text(data['name'] as String),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: adherenceRate / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      adherenceRate >= 80
                          ? Colors.green
                          : adherenceRate >= 60
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adherence: ${adherenceRate.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    try {
      await context.read<HealthReportService>().generateHealthReport(
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareReport(Map<String, dynamic> report) async {
    // TODO: Implement report sharing functionality
  }
} 