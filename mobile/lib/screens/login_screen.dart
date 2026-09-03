import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin([String? email, String? password]) async {
    final emailToUse = email ?? _emailController.text.trim();
    final passToUse = password ?? _passwordController.text;

    if (email != null && password != null) {
      _emailController.text = email;
      _passwordController.text = password;
    } else {
      if (!_formKey.currentState!.validate()) return;
    }

    final success = await ref.read(authProvider.notifier).login(
          emailToUse,
          passToUse,
        );

    if (mounted) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Authentication failed. Please check credentials.'),
            backgroundColor: AppColors.statusEmergency,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
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
                      // Glowing Brand Header
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.statusEmergency.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Sign In to CareConnect',
                        style: AppTheme.heading(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Emergency Response & Resident Safety System',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Error banner if any
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.statusEmergency.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.statusEmergency.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // OAuth Social Login Buttons matching web
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleLogin('ashish@careconnect.org', 'resident123'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0x0FFFFFFF),
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.blueAccent, size: 24),
                              label: const Text('Google', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleLogin('ashish@careconnect.org', 'resident123'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0x0FFFFFFF),
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                              label: const Text('Apple', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Divider
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'OR EMAIL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Email Field
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
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
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Sign In Button
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
                          onPressed: authState.isLoading ? null : () => _handleLogin(),
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
                                    Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Quick 1-Tap Portal Access Section
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'PORTAL QUICK ACCESS (1-TAP DEMO)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: [
                                _DemoPortalChip(
                                  label: '🚨 Resident',
                                  color: AppColors.statusEmergency,
                                  onTap: () => _handleLogin('ashish@careconnect.org', 'resident123'),
                                ),
                                _DemoPortalChip(
                                  label: '🛡️ Security',
                                  color: AppColors.statusSafe,
                                  onTap: () => _handleLogin('security@careconnect.org', 'sec123'),
                                ),
                                _DemoPortalChip(
                                  label: '🤝 Volunteer',
                                  color: AppColors.accentBlue,
                                  onTap: () => _handleLogin('volunteer@careconnect.org', 'vol123'),
                                ),
                                _DemoPortalChip(
                                  label: '🏡 Neighbor',
                                  color: AppColors.accentTeal,
                                  onTap: () => _handleLogin('neighbor@careconnect.org', 'neighbor123'),
                                ),
                                _DemoPortalChip(
                                  label: '👨‍👩‍👦 Guardian',
                                  color: AppColors.accentPurple,
                                  onTap: () => _handleLogin('guardian@careconnect.org', 'guard123'),
                                ),
                                _DemoPortalChip(
                                  label: '🩺 Caregiver',
                                  color: AppColors.statusAlert,
                                  onTap: () => _handleLogin('caregiver@careconnect.org', 'care123'),
                                ),
                                _DemoPortalChip(
                                  label: '📊 Admin',
                                  color: AppColors.accentPurple,
                                  onTap: () => _handleLogin('admin@careconnect.org', 'admin123'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Toggle to Register
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            "Don't have an account? Sign Up",
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

class _DemoPortalChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DemoPortalChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

