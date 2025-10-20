import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/medication.dart';
import '../blocs/medication_bloc.dart';

class MedicationForm extends StatefulWidget {
  final Medication? medication;

  const MedicationForm({super.key, this.medication});

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late TextEditingController _instructionsController;
  late TextEditingController _notesController;
  late List<String> _times;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name);
    _dosageController = TextEditingController(text: widget.medication?.dosage);
    _frequencyController = TextEditingController(text: widget.medication?.frequency);
    _instructionsController = TextEditingController(text: widget.medication?.instructions);
    _notesController = TextEditingController(text: widget.medication?.notes);
    _times = widget.medication?.times ?? [];
    _isActive = widget.medication?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addTime() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((time) {
      if (time != null) {
        setState(() {
          _times.add(time.format(context));
        });
      }
    });
  }

  void _removeTime(int index) {
    setState(() {
      _times.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_times.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one time')),
        );
        return;
      }

      final medication = Medication(
        id: widget.medication?.id ?? '',
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequencyController.text,
        times: _times,
        startDate: widget.medication?.startDate ?? DateTime.now(),
        endDate: widget.medication?.endDate,
        instructions: _instructionsController.text,
        isActive: _isActive,
        notes: _notesController.text,
        createdAt: widget.medication?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.medication == null) {
        context.read<MedicationBloc>().add(AddMedication(medication));
      } else {
        context.read<MedicationBloc>().add(UpdateMedication(medication));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                hintText: 'Enter medication name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'Enter dosage (e.g., 10mg)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                hintText: 'Enter frequency (e.g., Once daily)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter frequency';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'Enter instructions for taking the medication',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter instructions';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter any additional notes',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Times to take:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._times.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: () => _removeTime(entry.key),
                  );
                }),
                ActionChip(
                  label: const Text('Add Time'),
                  onPressed: _addTime,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(widget.medication == null ? 'Add Medication' : 'Update Medication'),
            ),
          ],
        ),
      ),
    );
  }
} 