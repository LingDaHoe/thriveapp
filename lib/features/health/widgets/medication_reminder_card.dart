import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/medication_bloc.dart';
import '../models/medication.dart';

class MedicationReminderCard extends StatelessWidget {
  const MedicationReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationBloc, MedicationState>(
      builder: (context, state) {
        if (state is MedicationLoaded) {
          final upcomingMedications = _getUpcomingMedications(state.medications);
          if (upcomingMedications.isEmpty) {
            return const SizedBox.shrink();
          }

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(left: 5, right: 5, top: 0, bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0097B2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Color(0xFF0097B2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Upcoming Medications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Navigate to medications screen using GoRouter
                          context.go('/health/medications');
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF0097B2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...upcomingMedications.map((medication) => _buildMedicationItem(context, medication)),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<Medication> _getUpcomingMedications(List<Medication> medications) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    return medications.where((medication) {
      // Check if medication is active
      if (!medication.isActive) return false;
      
      // Check if any of the medication times are upcoming
      return medication.times.any((time) => time.compareTo(currentTime) > 0);
    }).toList();
  }

  Widget _buildMedicationItem(BuildContext context, Medication medication) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Find the next time for this medication
    final nextTime = medication.times
        .where((time) => time.compareTo(currentTime) > 0)
        .firstOrNull;

    if (nextTime == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0097B2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                nextTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.dosage} - ${medication.frequency}',
                  style: const TextStyle(
                    color: Color(0xFF0097B2),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            onPressed: () {
              context.read<MedicationBloc>().add(
                    MarkMedicationAsTaken(medication.id, DateTime.now()),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medication.name} marked as taken'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF0097B2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 