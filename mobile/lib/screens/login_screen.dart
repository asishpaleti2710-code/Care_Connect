import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
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
  String _currentBaseUrl = ApiConfig.baseUrl;
  String? _serverLatency;

  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
  }

  Future<void> _loadCurrentServer() async {
    final stored = await StorageService().getApiBaseUrl();
    if (mounted) {
      setState(() {
        _currentBaseUrl = (stored != null && stored.isNotEmpty) ? stored : ApiConfig.baseUrl;
      });
      _pingServer(_currentBaseUrl);
    }
  }

  Future<void> _pingServer(String url) async {
    final res = await ApiService().checkOnlineHealth(url);
    if (mounted) {
      setState(() {
        _serverLatency = res['isOnline'] == true ? '${res['latencyMs']}ms' : 'Offline';
      });
    }
  }

  void _showServerSwitcherDialog(BuildContext context) {
    final customUrlController = TextEditingController(text: _currentBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Text(
              'Backend Server Connection',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select server connection for your Moto G32 or development device:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              _serverOptionTile(
                title: '☁️ Cloud Production (Railway)',
                subtitle: 'Recommended for real phones (online 24/7)',
                url: ApiConfig.cloudProductionUrl,
                ctx: ctx,
              ),
              const SizedBox(height: 8),
              _serverOptionTile(
                title: '💻 Local PC Wi-Fi',
                subtitle: 'Direct local server on same Wi-Fi',
                url: ApiConfig.localLanUrl,
                ctx: ctx,
              ),
              const SizedBox(height: 8),
              _serverOptionTile(
                title: '📱 Android Emulator',
                subtitle: '10.0.2.2 loopback for emulator only',
                url: ApiConfig.emulatorUrl,
                ctx: ctx,
              ),
              const SizedBox(height: 16),
              const Text(
                'Or Custom Server URL:',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: customUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = customUrlController.text.trim();
              if (newUrl.isNotEmpty) {
                await StorageService().saveApiBaseUrl(newUrl);
                if (mounted) setState(() => _currentBaseUrl = newUrl);
                if (ctx.mounted) Navigator.pop(ctx);
                _pingServer(newUrl);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            child: const Text('Save & Connect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _serverOptionTile({
    required String title,
    required String subtitle,
    required String url,
    required BuildContext ctx,
  }) {
    final isSelected = _currentBaseUrl == url;
    return InkWell(
      onTap: () async {
        await StorageService().saveApiBaseUrl(url);
        if (mounted) setState(() => _currentBaseUrl = url);
        if (ctx.mounted) Navigator.pop(ctx);
        _pingServer(url);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488).withValues(alpha: 0.2) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF334155),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      const SizedBox(height: 16),

                      // Interactive Server Connection Chip & Switcher
                      InkWell(
                        onTap: () => _showServerSwitcherDialog(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _serverLatency == 'Offline'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _serverLatency == 'Offline'
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentBaseUrl.contains('railway')
                                      ? 'Server: Cloud Production (${_serverLatency ?? 'checking...'})'
                                      : 'Server: $_currentBaseUrl (${_serverLatency ?? 'checking...'})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.settings_ethernet_rounded,
                                size: 14,
                                color: Color(0xFF38BDF8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

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

