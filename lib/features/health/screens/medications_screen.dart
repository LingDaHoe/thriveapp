import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/medication_bloc.dart';
import '../models/medication.dart';
import '../models/medication_preset.dart';
import '../widgets/medication_form.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load medications on init
    context.read<MedicationBloc>().add(LoadMedications());
  }

  Future<void> _refreshMedications() async {
    context.read<MedicationBloc>().add(LoadMedications());
    // Wait for state to update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Medications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              if (value == 'preset') {
                _showPresetDialog(context);
              } else {
                _showAddMedicationDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'preset',
                child: Row(
                  children: [
                    Icon(Icons.medical_services),
                    SizedBox(width: 8),
                    Text('Add from Presets'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Add Custom'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<MedicationBloc, MedicationState>(
        listener: (context, state) {
          // Auto-refresh after operations complete
          if (state is MedicationLoaded) {
            // Already loaded, no need to do anything
          }
        },
        builder: (context, state) {
          if (state is MedicationInitial || state is MedicationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MedicationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshMedications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is MedicationLoaded) {
            if (state.medications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medication, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No medications added yet', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showPresetDialog(context),
                      icon: const Icon(Icons.medical_services),
                      label: const Text('Add from Presets'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showAddMedicationDialog(context),
                      child: const Text('Add Custom Medication'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshMedications,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.medications.length,
                itemBuilder: (context, index) {
                  final medication = state.medications[index];
                  return _buildMedicationCard(context, medication);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, Medication medication) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(medication.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${medication.dosage}'),
            Text('Frequency: ${medication.frequency}'),
            if (medication.notes?.isNotEmpty ?? false)
              Text('Notes: ${medication.notes}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditMedicationDialog(context, medication),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmationDialog(context, medication),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: const MedicationForm(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditMedicationDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medication'),
        content: MedicationForm(medication: medication),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MedicationBloc>().add(DeleteMedication(medication.id));
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPresetDialog(BuildContext context) {
    // Group presets by category
    final categories = <String, List<MedicationPreset>>{};
    for (final preset in medicationPresets) {
      categories.putIfAbsent(preset.category, () => []).add(preset);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Common Medications',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories.keys.elementAt(index);
                    final presets = categories[category]!;
                    
                    return ExpansionTile(
                      leading: Icon(
                        _getCategoryIcon(category),
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: presets.map((preset) {
                        return ListTile(
                          title: Text(preset.name),
                          subtitle: Text(
                            preset.instructions,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            Navigator.pop(context);
                            _showPresetDetailsDialog(context, preset);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresetDetailsDialog(BuildContext context, MedicationPreset preset) {
    String? selectedDosage = preset.commonDosages.first;
    String? selectedFrequency = preset.commonFrequencies.first;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(preset.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.category,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dosage',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: preset.commonDosages.map((dosage) {
                    return ChoiceChip(
                      label: Text(dosage),
                      selected: selectedDosage == dosage,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedDosage = dosage);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Frequency',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...preset.commonFrequencies.map((frequency) {
                  return RadioListTile<String>(
                    title: Text(frequency),
                    value: frequency,
                    groupValue: selectedFrequency,
                    onChanged: (value) {
                      setState(() => selectedFrequency = value);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preset.instructions,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDosage != null && selectedFrequency != null) {
                  final now = DateTime.now();
                  final medication = Medication(
                    id: now.millisecondsSinceEpoch.toString(),
                    name: preset.name,
                    dosage: selectedDosage!,
                    frequency: selectedFrequency!,
                    times: [],
                    startDate: now,
                    instructions: preset.instructions,
                    createdAt: now,
                    updatedAt: now,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                  context.read<MedicationBloc>().add(AddMedication(medication));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${preset.name} added successfully')),
                  );
                  // Refresh list
                  _refreshMedications();
                }
              },
              child: const Text('Add Medication'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Blood Pressure':
        return Icons.favorite;
      case 'Cholesterol':
        return Icons.water_drop;
      case 'Diabetes':
        return Icons.bloodtype;
      case 'Pain Relief':
        return Icons.healing;
      case 'Thyroid':
        return Icons.health_and_safety;
      case 'Acid Reflux':
        return Icons.local_dining;
      case 'Blood Thinner':
        return Icons.medical_information;
      case 'Vitamins':
        return Icons.medication_liquid;
      default:
        return Icons.medication;
    }
  }
} 