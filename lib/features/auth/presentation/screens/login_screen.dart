import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'operator@redops.com');
  final _passwordController = TextEditingController(text: 'RedOps#2026!');
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid email and password.'),
          backgroundColor: AppColors.v3Warning,
        ),
      );
      return;
    }

    ref.read(authControllerProvider.notifier).signInWithEmail(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final firebaseStatus = ref.watch(firebaseStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.v3OpsRed : AppColors.deepBlue;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NOTICE: ${next.error}'),
            backgroundColor: AppColors.v3Warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.dynamicBg(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.bg900, AppColors.cardBg, AppColors.deepBlue]
                : [
                    AppColors.lightScaffold,
                    Colors.white,
                    AppColors.lightSurface
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.08),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.25),
                          width: 1.5),
                    ),
                    child: Icon(Icons.shield_rounded,
                        size: 64, color: primaryColor),
                  ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
                  const Gap(16),
                  Text(
                    'REDOPS HUB',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      fontFamily: 'monospace',
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  Text(
                    'TACTICAL COMMAND CENTER',
                    style: TextStyle(
                      color: isDark ? AppColors.v3OpsRed : AppColors.deepBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      fontFamily: 'monospace',
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : AppColors.deepBlue)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_tethering_rounded,
                            size: 14, color: primaryColor),
                        const Gap(8),
                        Flexible(
                          child: Text(
                            firebaseStatus,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                  const Gap(24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.20),
                          width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(
                              alpha: isDark ? 0.18 : 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            labelText: 'OPERATOR EMAIL',
                            labelStyle: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                            prefixIcon: Icon(Icons.email_outlined,
                                color: primaryColor, size: 18),
                            filled: true,
                            fillColor: primaryColor.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: primaryColor.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                        const Gap(14),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: TextStyle(
                            color: AppColors.dynamicTextPrimary(context),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            labelText: 'SECURITY PASSCODE',
                            labelStyle: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                color: primaryColor, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.dynamicTextMuted(context),
                                size: 18,
                              ),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                            filled: true,
                            fillColor: primaryColor.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: primaryColor.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                        const Gap(18),
                        ElevatedButton.icon(
                          onPressed: authState.isLoading ? null : _handleSignIn,
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: Text(
                            authState.isLoading
                                ? 'AUTHENTICATING...'
                                : 'AUTHENTICATE & ENTER',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                        ),
                        const Gap(16),
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: AppColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'OR ALTERNATIVE PROVIDER',
                                style: TextStyle(
                                  color: AppColors.dynamicTextMuted(context),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const Gap(14),
                        Row(
                          children: [
                            Expanded(
                              child: _SmallOAuthButton(
                                label: 'GOOGLE',
                                icon: Icons.g_mobiledata_rounded,
                                onTap: () => ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithGoogle(),
                              ),
                            ),
                            const Gap(10),
                            Expanded(
                              child: _SmallOAuthButton(
                                label: 'GITHUB',
                                icon: Icons.code_rounded,
                                onTap: () => ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithGitHub(),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),
                        TextButton.icon(
                          onPressed: () {
                            ref
                                .read(authControllerProvider.notifier)
                                .enterOfflineMode();
                            ref
                                .read(authControllerProvider.notifier)
                                .unlockSession();
                            GoRouter.of(context).go(AppRoutes.c2);
                          },
                          icon: const Icon(Icons.cloud_off_rounded, size: 16),
                          label: const Text(
                            'EMERGENCY OFFLINE TACTICAL ACCESS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              fontFamily: 'monospace',
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? AppColors.textSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security_rounded,
                            color: primaryColor, size: 16),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            'Protected End-to-End. Tactical local protocol active.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallOAuthButton extends StatelessWidget {
  const _SmallOAuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.v3OpsRed : AppColors.deepBlue;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: primaryColor, size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.dynamicTextPrimary(context),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
