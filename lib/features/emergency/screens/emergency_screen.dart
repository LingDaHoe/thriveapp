import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/emergency_bloc.dart';
import '../models/emergency_contact.dart';
import 'emergency_contact_form.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Emergency'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<EmergencyBloc, EmergencyState>(
        builder: (context, state) {
          if (state is EmergencyInitial) {
            context.read<EmergencyBloc>().add(LoadEmergencyContacts());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmergencyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmergencyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<EmergencyBloc>().add(LoadEmergencyContacts()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is EmergencyLoaded) {
            return Column(
              children: [
                _buildSOSButton(context, state),
                const Divider(height: 32),
                Expanded(
                  child: _buildContactsList(context, state),
                ),
              ],
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, EmergencyLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (state.isSOSActive) ...[
            Text(
              'SOS will be triggered in ${state.remainingSeconds} seconds',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<EmergencyBloc>().add(CancelSOS()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('CANCEL SOS'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: state.contacts.isEmpty 
                  ? null 
                  : () => _showSOSDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('SOS'),
            ),
            if (state.contacts.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Add an emergency contact to enable SOS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildContactsList(BuildContext context, EmergencyLoaded state) {
    if (state.contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contact_phone_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No emergency contacts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showAddContactDialog(context),
              child: const Text('Add Emergency Contact'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.contacts.length,
      itemBuilder: (context, index) {
        final contact = state.contacts[index];
        return _buildContactCard(context, contact);
      },
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          child: Icon(
            contact.isPrimary ? Icons.star : Icons.person,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(contact.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            if (contact.email != null) Text(contact.email!),
            Text(contact.relationship),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditContactDialog(context, contact),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteContactDialog(context, contact),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BlocProvider.value(
        value: context.read<EmergencyBloc>(),
        child: const EmergencyContactForm(),
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, EmergencyContact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BlocProvider.value(
        value: context.read<EmergencyBloc>(),
        child: EmergencyContactForm(contact: contact),
      ),
    );
  }

  void _showDeleteContactDialog(BuildContext context, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<EmergencyBloc>().add(DeleteEmergencyContact(contact.id));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trigger SOS'),
        content: const Text(
          'This will notify all your emergency contacts with your location. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<EmergencyBloc>().add(
                    const TriggerSOS('User triggered SOS'),
                  );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('TRIGGER SOS'),
          ),
        ],
      ),
    );
  }
} 