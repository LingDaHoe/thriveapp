import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _dataSharingAccepted = false;
  bool _healthDataAccepted = false;
  bool _locationAccepted = false;

  void _handleSubmit() {
    if (_termsAccepted && _privacyAccepted) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the required terms and privacy policy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent & Permissions'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Consent Icon
              const Icon(
                Icons.gavel,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              // Welcome Text
              const Text(
                'Please review and accept our terms',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Required Consents
              const Text(
                'Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Terms of Use
              CheckboxListTile(
                title: const Text('Terms of Use'),
                subtitle: const Text(
                  'I agree to the terms and conditions of using the Thrive app.',
                ),
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
              ),
              // Privacy Policy
              CheckboxListTile(
                title: const Text('Privacy Policy'),
                subtitle: const Text(
                  'I understand how my data will be collected and used.',
                ),
                value: _privacyAccepted,
                onChanged: (value) {
                  setState(() {
                    _privacyAccepted = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 32),
              // Optional Consents
              const Text(
                'Optional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Data Sharing
              CheckboxListTile(
                title: const Text('Data Sharing with Caregiver'),
                subtitle: const Text(
                  'Allow my caregiver to access my activity and health data.',
                ),
                value: _dataSharingAccepted,
                onChanged: (value) {
                  setState(() {
                    _dataSharingAccepted = value ?? false;
                  });
                },
              ),
              // Health Data
              CheckboxListTile(
                title: const Text('Health Data Access'),
                subtitle: const Text(
                  'Allow Thrive to access my health data from Google Fit/Apple HealthKit.',
                ),
                value: _healthDataAccepted,
                onChanged: (value) {
                  setState(() {
                    _healthDataAccepted = value ?? false;
                  });
                },
              ),
              // Location Services
              CheckboxListTile(
                title: const Text('Location Services'),
                subtitle: const Text(
                  'Allow Thrive to access my location for emergency features.',
                ),
                value: _locationAccepted,
                onChanged: (value) {
                  setState(() {
                    _locationAccepted = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 32),
              // Submit Button
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 