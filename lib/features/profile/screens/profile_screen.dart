import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../blocs/profile_bloc.dart';
import '../models/profile_model.dart';
import '../../auth/blocs/auth_bloc.dart';
import '../../admin/services/admin_service.dart';
import '../../../config/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String? _selectedGender;
  String _selectedLanguage = 'en';
  bool _isEditing = false;

  final Map<String, String> _languageNames = {
    'en': 'English',
    'ms': 'Malay',
    'zh': 'Mandarin',
    'ta': 'Tamil',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _startEditing(Profile profile) {
    setState(() {
      _isEditing = true;
      _nameController.text = profile.displayName;
      _ageController.text = profile.age.toString();
      _selectedGender = profile.gender;
      _selectedLanguage = _languageNames.entries
          .firstWhere(
            (entry) => entry.value == profile.preferredLanguage,
            orElse: () => const MapEntry('en', 'English'),
          )
          .key;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final currentState = context.read<ProfileBloc>().state;
      if (currentState is ProfileLoaded) {
        final updatedProfile = currentState.profile.copyWith(
          displayName: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          gender: _selectedGender,
          preferredLanguage: _languageNames[_selectedLanguage] ?? 'English',
        );
        context.read<ProfileBloc>().add(SaveProfile(updatedProfile));
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  void _updateSettings(ProfileSettings settings) {
    context.read<ProfileBloc>().add(UpdateSettings(settings));
    
    // Also update the theme provider for immediate UI changes
    final themeProvider = context.read<ThemeProvider>();
    
    // Update each setting individually to trigger proper notifications
    if (themeProvider.isDarkMode != settings.darkMode) {
      themeProvider.setDarkMode(settings.darkMode);
    }
    if (themeProvider.fontSize != settings.fontSize) {
      themeProvider.setFontSize(settings.fontSize);
    }
    if (themeProvider.voiceGuidance != settings.voiceGuidance) {
      themeProvider.setVoiceGuidance(settings.voiceGuidance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(LoadProfile());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.profile;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
                actions: [
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _startEditing(profile),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Header
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          profile.displayName.isNotEmpty 
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Information
                      if (_isEditing) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.cake),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your age';
                            }
                            final age = int.tryParse(value);
                            if (age == null || age < 65) {
                              return 'Age must be 65 or older';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender (Optional)',
                            prefixIcon: Icon(Icons.people),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Language',
                            prefixIcon: Icon(Icons.language),
                            border: OutlineInputBorder(),
                          ),
                          items: _languageNames.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedLanguage = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelEditing,
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _buildInfoCard(
                          'Personal Information',
                          [
                            _buildInfoRow('Name', profile.displayName),
                            _buildInfoRow('Age', profile.age.toString()),
                            if (profile.gender != null)
                              _buildInfoRow('Gender', profile.gender!),
                            _buildInfoRow(
                              'Language',
                              _languageNames[profile.preferredLanguage] ??
                                  profile.preferredLanguage,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Settings Section
                      _buildInfoCard(
                        'Settings',
                        [
                          SwitchListTile(
                            title: const Text('Notifications'),
                            subtitle: const Text('Receive app notifications'),
                            value: profile.settings.notifications,
                            onChanged: (value) {
                              _updateSettings(profile.settings.copyWith(
                                notifications: value,
                              ));
                            },
                          ),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              return SwitchListTile(
                                title: const Text('Dark Mode'),
                                subtitle: Text(themeProvider.isDarkMode 
                                    ? 'Switch to Light Mode' 
                                    : 'Switch to Dark Mode'),
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  _updateSettings(profile.settings.copyWith(
                                    darkMode: value,
                                  ));
                                },
                              );
                            },
                          ),
                          ListTile(
                            title: const Text('Font Size'),
                            subtitle: Text(profile.settings.fontSize),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              _showFontSizeDialog(profile);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Voice Guidance'),
                            subtitle: const Text('Enable voice assistance'),
                            value: profile.settings.voiceGuidance,
                            onChanged: (value) {
                              _updateSettings(profile.settings.copyWith(
                                voiceGuidance: value,
                              ));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Help & Support Section
                      _buildInfoCard(
                        'Help & Support',
                        [
                          ListTile(
                            leading: const Icon(Icons.help_outline),
                            title: const Text('FAQs'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to FAQs screen
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.contact_support),
                            title: const Text('Contact Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to support screen
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to privacy policy screen
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Terms of Service'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to terms of service screen
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Emergency Contacts Section
                      _buildInfoCard(
                        'Emergency Contacts',
                        [
                          ...profile.emergencyContacts.map((contact) {
                            return ListTile(
                              leading: const Icon(Icons.emergency),
                              title: Text(contact.name),
                              subtitle: Text(
                                '${contact.relationship} - ${contact.phoneNumber}',
                              ),
                              trailing: contact.isPrimary
                                  ? const Chip(
                                      label: Text('Primary'),
                                      backgroundColor: Colors.red,
                                      labelStyle: TextStyle(color: Colors.white),
                                    )
                                  : null,
                            );
                          }).toList(),
                          ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Add Emergency Contact'),
                            onTap: () {
                              // TODO: Implement add emergency contact
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: () => _showLogoutDialog(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const Center(child: Text('No profile data available'));
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(Profile profile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Font Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Small'),
                value: 'small',
                groupValue: profile.settings.fontSize,
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(profile.settings.copyWith(fontSize: value));
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Medium'),
                value: 'medium',
                groupValue: profile.settings.fontSize,
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(profile.settings.copyWith(fontSize: value));
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Large'),
                value: 'large',
                groupValue: profile.settings.fontSize,
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(profile.settings.copyWith(fontSize: value));
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear admin session if exists
              await AdminService.clearAdminSession();
              if (!mounted) return;
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
} 