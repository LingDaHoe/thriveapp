import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../admin/services/caregiver_service.dart';
import '../../admin/models/caregiver_invitation.dart';

class CaregiverInvitationNotification extends StatelessWidget {
  const CaregiverInvitationNotification({super.key});

  @override
  Widget build(BuildContext context) {
    final caregiverService = CaregiverService();

    return StreamBuilder<List<CaregiverInvitation>>(
      stream: caregiverService.getReceivedInvitationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final invitations = snapshot.data ?? [];
        final pendingInvitations =
            invitations.where((inv) => inv.status == 'pending').toList();

        if (pendingInvitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Caregiver Invitation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...pendingInvitations.take(3).map((invitation) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${invitation.caregiverName} wants to be your caregiver',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                try {
                                  await caregiverService
                                      .rejectInvitation(invitation.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invitation rejected'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Decline'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await caregiverService
                                      .acceptInvitation(invitation.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Caregiver added successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (pendingInvitations.length > 3)
                TextButton(
                  onPressed: () {
                    // Navigate to notifications page
                    context.push('/notifications');
                  },
                  child: Text(
                    'View ${pendingInvitations.length - 3} more invitation${pendingInvitations.length - 3 == 1 ? '' : 's'}',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

