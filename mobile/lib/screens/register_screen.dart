import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'resident';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        if (success) {
          final isAuth = ref.read(authProvider).isAuthenticated;
          if (isAuth) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! Please sign in.'),
                backgroundColor: AppColors.statusSafe,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          final error = ref.read(authProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Registration failed'),
              backgroundColor: AppColors.statusEmergency,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                padding: const EdgeInsets.all(28.0),
                radius: 24.0,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Brand Icon
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.statusEmergency.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Create Account',
                        style: AppTheme.heading(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Join CareConnect Community Emergency Network',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      const Text(
                        'Full Name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: AppGlass.inputDecoration(
                          hintText: 'Ashish Sharma',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Address
                      const Text(
                        'Email Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: AppGlass.inputDecoration(
                          hintText: 'ashish@careconnect.org',
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary, size: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      const Text(
                        'Password',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: AppGlass.inputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // System Role Dropdown
                      const Text(
                        'System Role',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        dropdownColor: AppColors.bgSecondary,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: AppGlass.inputDecoration(
                          hintText: 'Select Role',
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 18),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'resident', child: Text('Resident')),
                          DropdownMenuItem(value: 'guardian', child: Text('Guardian / Family')),
                          DropdownMenuItem(value: 'volunteer', child: Text('Volunteer Responder')),
                          DropdownMenuItem(value: 'security', child: Text('Campus Security')),
                          DropdownMenuItem(value: 'caregiver', child: Text('Nurse Caregiver')),
                          DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.tealGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentTeal.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : () => _handleRegister(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Already have an account link
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Already have an account? Sign In',
                            style: TextStyle(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

