import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final firebaseStatus = ref.watch(firebaseStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AUTHENTICATION FAILED: ${next.error}'),
            backgroundColor: AppColors.criticalFg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
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
                        size: 72, color: primaryColor),
                  ).animate().fadeIn(duration: 700.ms).scale(
                      begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
                  const Gap(20),
                  Text(
                    'REDOPS HUB',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.5,
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  Text(
                    'TACTICAL COMMAND CENTER',
                    style: TextStyle(
                      color: isDark ? AppColors.redPrimary : AppColors.deepBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const Gap(20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 300),
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
                            size: 16, color: primaryColor),
                        const Gap(8),
                        Flexible(
                          child: Text(
                            firebaseStatus,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const Gap(28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.16),
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
                      children: [
                        _LoginButton(
                          label: 'AUTHENTICATE WITH GOOGLE',
                          icon: Icons.g_mobiledata_rounded,
                          isLoading: authState.isLoading,
                          onTap: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                        ),
                        const Gap(14),
                        _LoginButton(
                          label: 'AUTHENTICATE WITH GITHUB',
                          icon: Icons.code_rounded,
                          isLoading: authState.isLoading,
                          onTap: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGitHub(),
                        ),
                        const Gap(14),
                        const Divider(color: AppColors.border),
                        const Gap(14),
                        TextButton.icon(
                          onPressed: () {
                            ref.read(authControllerProvider.notifier).enterOfflineMode();
                            GoRouter.of(context).go(AppRoutes.c2);
                          },
                          icon: const Icon(Icons.cloud_off_rounded, size: 18),
                          label: const Text(
                            'CONTINUE IN OFFLINE MODE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1,
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
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                  const Gap(18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security_rounded,
                            color: primaryColor, size: 18),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            'Authorized access only. Secure operations are monitored and protected end-to-end.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 11,
                              height: 1.4,
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

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: primaryColor.withValues(alpha: 0.5), width: 1.5),
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: primaryColor),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: primaryColor, size: 28),
                      const Gap(12),
                      Text(
                        label,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
