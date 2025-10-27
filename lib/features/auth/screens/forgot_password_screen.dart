import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isResetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        ResetPasswordEvent(
          email: _emailController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/login-bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Image.asset(
                'assets/images/thrive-logo-transparent.png',
                width: 84,
                height: 35,
              ),
            ),
            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 10, right: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/thrive-logo.png',
                        width: 208,
                        height: 87,
                      ),
                      const SizedBox(height: 7),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 25,
                                color: Color(0xFF393D37),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isResetSent
                                  ? 'Check your email for password reset instructions. If you don\'t see it, please check your spam folder.'
                                  : 'Enter your email address and we\'ll send you instructions to reset your password.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (!_isResetSent) ...[
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0097B2),
                                      width: 1,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 12.0),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Reset Button
                              BlocConsumer<AuthBloc, AuthState>(
                                listener: (context, state) {
                                  if (state is AuthError) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(state.message),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else if (state is AuthLoading) {
                                    setState(() {
                                      _isResetSent = true;
                                    });
                                  }
                                },
                                builder: (context, state) {
                                  return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: state is AuthLoading
                                            ? null
                                            : _handleResetPassword,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                          backgroundColor: const Color(0xFF0097B2),
                                        ),
                                        child: state is AuthLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Send Reset Link',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ));
                                },
                              ),
                            ] else ...[
                              // Success Message
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Reset link sent successfully!',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Back to Login
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  context.go('/login');
                                },
                                child: const Text(
                                  'Back to Login',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0097B2)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 