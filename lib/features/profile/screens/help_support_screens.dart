import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// FAQ Screen
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            context,
            'How do I track my activities?',
            'You can track activities by going to the Activities tab and selecting an activity to complete. Your progress will be automatically saved and displayed on the dashboard.',
          ),
          _buildFAQItem(
            context,
            'How do I add emergency contacts?',
            'Go to your Profile, scroll to Emergency Contacts section, and tap "Add Emergency Contact". You can also add contacts from the Emergency/SOS page.',
          ),
          _buildFAQItem(
            context,
            'How do I enable dark mode?',
            'Go to Settings in your Profile, and toggle the Dark Mode switch. The app will immediately switch to dark mode.',
          ),
          _buildFAQItem(
            context,
            'How do I change font size?',
            'Go to Settings in your Profile, tap on Font Size, and select Small, Medium, or Large. The change will apply immediately.',
          ),
          _buildFAQItem(
            context,
            'How do I track my health metrics?',
            'Go to the Health tab and select Health Monitoring. The app will request permissions to read health data from your device.',
          ),
          _buildFAQItem(
            context,
            'What should I do in an emergency?',
            'Tap the SOS button on the home screen or emergency page. This will immediately call your primary emergency contact and send location information to all your emergency contacts.',
          ),
          _buildFAQItem(
            context,
            'How do I earn points?',
            'You earn points by completing activities (physical, mental, social) and reading health content. Points are automatically added to your profile.',
          ),
          _buildFAQItem(
            context,
            'How do I add medications?',
            'Go to the Health tab, select Medications, and tap the Add button. You can choose from presets or add a custom medication.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Support Screen
class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We\'re here to help!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is available to assist you with any questions or issues.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildContactOption(
            context,
            Icons.email,
            'Email Support',
            'support@thriveapp.com',
            'Send us an email',
            () {
              // TODO: Implement email
            },
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            context,
            Icons.phone,
            'Phone Support',
            '+60 123 456 7890',
            'Call us during business hours',
            () {
              // TODO: Implement phone call
            },
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            context,
            Icons.chat,
            'Live Chat',
            'Available 9 AM - 5 PM',
            'Chat with our support team',
            () {
              // TODO: Implement chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat coming soon!')),
              );
            },
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Project',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app is developed as a Final Year Project (FYP) by student developers. We appreciate your patience and feedback as we continue to improve the app.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Updated: December 2024',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    '1. Information We Collect',
                    'We collect the following information:\n\n'
                    '• Personal information (name, age, email, phone number)\n'
                    '• Health data (steps, heart rate, sleep, medications)\n'
                    '• Activity data (completed activities, points earned)\n'
                    '• Device information (for app functionality)\n'
                    '• Location data (only when using SOS feature)',
                  ),
                  _buildSection(
                    context,
                    '2. How We Use Your Information',
                    'We use your information to:\n\n'
                    '• Provide health and wellness tracking services\n'
                    '• Send emergency alerts to your contacts\n'
                    '• Improve app functionality and user experience\n'
                    '• Provide personalized recommendations\n'
                    '• Ensure app security and prevent fraud',
                  ),
                  _buildSection(
                    context,
                    '3. Data Storage and Security',
                    'Your data is stored securely using Firebase services:\n\n'
                    '• All data is encrypted in transit and at rest\n'
                    '• We follow industry-standard security practices\n'
                    '• Regular security audits and updates\n'
                    '• Access controls and authentication',
                  ),
                  _buildSection(
                    context,
                    '4. Data Sharing',
                    'We do NOT sell your personal information. We only share data:\n\n'
                    '• With your emergency contacts (SOS alerts only)\n'
                    '• With authorized caregivers (with your consent)\n'
                    '• As required by law or legal process',
                  ),
                  _buildSection(
                    context,
                    '5. Your Rights',
                    'You have the right to:\n\n'
                    '• Access your personal data\n'
                    '• Request correction of inaccurate data\n'
                    '• Request deletion of your data\n'
                    '• Opt-out of data collection (may limit app functionality)\n'
                    '• Export your data',
                  ),
                  _buildSection(
                    context,
                    '6. Contact Us',
                    'For privacy concerns or data requests, please contact us at:\n\n'
                    'Email: privacy@thriveapp.com\n'
                    'Support: support@thriveapp.com',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note: This is a student project (FYP). Data practices are simplified for educational purposes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// Terms of Service Screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Updated: December 2024',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Terms of Service',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    '1. Acceptance of Terms',
                    'By using the Thrive app, you agree to these Terms of Service. If you do not agree, please do not use the app.',
                  ),
                  _buildSection(
                    context,
                    '2. Use of the App',
                    'You agree to:\n\n'
                    '• Use the app only for its intended purpose\n'
                    '• Provide accurate information\n'
                    '• Not misuse the app or its features\n'
                    '• Respect other users and their privacy\n'
                    '• Keep your account secure',
                  ),
                  _buildSection(
                    context,
                    '3. Health Information Disclaimer',
                    'IMPORTANT: This app is for informational purposes only and is NOT a substitute for professional medical advice, diagnosis, or treatment.\n\n'
                    '• Always consult healthcare professionals for medical decisions\n'
                    '• Do not rely solely on app data for medical decisions\n'
                    '• Seek immediate medical attention for emergencies\n'
                    '• The app developers are not medical professionals',
                  ),
                  _buildSection(
                    context,
                    '4. Emergency Services',
                    'The SOS feature is designed to assist in emergencies:\n\n'
                    '• It contacts your emergency contacts, not emergency services directly\n'
                    '• You may still need to call emergency services (e.g., 999/911)\n'
                    '• The app does not guarantee immediate response\n'
                    '• Location accuracy depends on device capabilities',
                  ),
                  _buildSection(
                    context,
                    '5. Student Project Disclaimer',
                    'This app is developed as a Final Year Project (FYP) by student developers:\n\n'
                    '• The app is provided "as is" without warranties\n'
                    '• Features may have limitations or bugs\n'
                    '• We appreciate your patience and feedback\n'
                    '• Continuous improvements are being made',
                  ),
                  _buildSection(
                    context,
                    '6. Limitation of Liability',
                    'To the maximum extent permitted by law:\n\n'
                    '• The developers are not liable for any damages\n'
                    '• Use the app at your own risk\n'
                    '• No guarantees of accuracy or reliability\n'
                    '• Technical issues may occur',
                  ),
                  _buildSection(
                    context,
                    '7. Changes to Terms',
                    'We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of modified terms.',
                  ),
                  _buildSection(
                    context,
                    '8. Contact',
                    'For questions about these terms, contact:\n\n'
                    'Email: support@thriveapp.com',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note: This is a student project. Terms are simplified for educational purposes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

