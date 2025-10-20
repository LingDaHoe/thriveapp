import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/health_report_service.dart';

class SelfReportedMetricsScreen extends StatefulWidget {
  const SelfReportedMetricsScreen({super.key});

  @override
  State<SelfReportedMetricsScreen> createState() => _SelfReportedMetricsScreenState();
}

class _SelfReportedMetricsScreenState extends State<SelfReportedMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _selectedMetric = 'pain_level';
  double _metricValue = 0;

  final Map<String, Map<String, dynamic>> _metrics = {
    'pain_level': {
      'name': 'Pain Level',
      'min': 0,
      'max': 10,
      'unit': 'scale',
      'icon': Icons.sick,
    },
    'mood': {
      'name': 'Mood',
      'min': 1,
      'max': 5,
      'unit': 'scale',
      'icon': Icons.mood,
    },
    'energy_level': {
      'name': 'Energy Level',
      'min': 0,
      'max': 10,
      'unit': 'scale',
      'icon': Icons.bolt,
    },
    'stress_level': {
      'name': 'Stress Level',
      'min': 0,
      'max': 10,
      'unit': 'scale',
      'icon': Icons.psychology,
    },
    'sleep_quality': {
      'name': 'Sleep Quality',
      'min': 1,
      'max': 5,
      'unit': 'scale',
      'icon': Icons.bedtime,
    },
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Reported Metrics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricSelector(),
              const SizedBox(height: 24),
              _buildMetricValueSlider(),
              const SizedBox(height: 24),
              _buildNotesField(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitMetric,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Metric'),
                ),
              ),
              const SizedBox(height: 32),
              _buildRecentMetrics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Metric',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMetric,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          items: _metrics.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Icon(entry.value['icon'] as IconData),
                  const SizedBox(width: 8),
                  Text(entry.value['name'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMetric = value;
                _metricValue = _metrics[value]!['min'] as double;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildMetricValueSlider() {
    final metric = _metrics[_selectedMetric]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${metric['name']}: ${_metricValue.toStringAsFixed(1)} ${metric['unit']}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Slider(
          value: _metricValue,
          min: metric['min'] as double,
          max: metric['max'] as double,
          divisions: ((metric['max'] as double) - (metric['min'] as double)).toInt(),
          label: _metricValue.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _metricValue = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Add any additional notes about this metric...',
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Metrics',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: context.read<HealthReportService>().getHealthReports(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = snapshot.data!;
            if (reports.isEmpty) {
              return const Text('No recent metrics available');
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final selfReportedData = report['selfReportedData'] as Map<String, dynamic>;
                
                return Card(
                  child: ListTile(
                    leading: Icon(_metrics[_selectedMetric]!['icon'] as IconData),
                    title: Text(_metrics[_selectedMetric]!['name'] as String),
                    subtitle: Text(
                      'Value: ${selfReportedData['value']} ${_metrics[_selectedMetric]!['unit']}',
                    ),
                    trailing: Text(
                      DateFormat('MMM d, h:mm a').format(
                        DateTime.parse(report['timestamp'] as String),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _submitMetric() async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<HealthReportService>().saveSelfReportedMetric(
          type: _selectedMetric,
          value: _metricValue,
          notes: _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Metric saved successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset form
          _formKey.currentState!.reset();
          _notesController.clear();
          setState(() {
            _metricValue = _metrics[_selectedMetric]!['min'] as double;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving metric: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 