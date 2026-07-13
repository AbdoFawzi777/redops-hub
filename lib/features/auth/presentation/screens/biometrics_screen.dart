import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

class BiometricsScreen extends ConsumerStatefulWidget {
  const BiometricsScreen({super.key});

  @override
  ConsumerState<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends ConsumerState<BiometricsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    final securityService = ref.read(securityServiceProvider);
    try {
      final bool isReady = await securityService.initialize();
      if (!isReady) {
        _success();
        return;
      }

      final bool didAuthenticate =
          await securityService.authenticateWithBiometrics();
      if (didAuthenticate) {
        _success();
      }
    } catch (e) {
      debugPrint('Biometric Error: $e');
      _success();
    }
  }

  void _success() {
    ref.read(isSessionUnlockedProvider.notifier).state = true;

    // عرض رسالة ترحيب بعد اكتمال تسجيل الدخول والتحقق
    if (mounted) {
      final auth = ref.read(firebaseAuthProvider);
      final user = auth?.currentUser;
      final name =
          (user?.displayName ?? user?.email ?? user?.uid ?? 'Operator').trim();
      _showWelcomeBottomSheet(name);
    }
  }

  void _showWelcomeBottomSheet(String name) {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Welcome',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Builder(builder: (context) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardBg.withValues(alpha: 0.98)
                      : Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: primaryColor.withValues(alpha: 0.22), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.20),
                      blurRadius: 22,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: primaryColor.withValues(alpha: 0.28)),
                          ),
                          child:
                              Icon(Icons.shield_rounded, color: primaryColor),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.lightTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تم التحقق بنجاح. جارٍ فتح لوحة التحكم...',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textTertiary
                                  : AppColors.lightTextTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms),
            );
          }),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
            opacity: curved,
            child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.15), end: Offset.zero)
                    .animate(curved),
                child: child));
      },
    );

    // بعد عرض الرسالة انتقل للشاشة الرئيسية
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      context.go(AppRoutes.c2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint_rounded,
              size: 100,
              color: primaryColor,
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2.seconds, color: Colors.white30)
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1.seconds),
            const Gap(32),
            Text(
              'BIOMETRIC VERIFICATION',
              style: TextStyle(
                color:
                    isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const Gap(12),
            Text(
              'Scan face or fingerprint to unlock terminal',
              style: TextStyle(
                color: isDark
                    ? AppColors.textTertiary
                    : AppColors.lightTextTertiary,
                fontSize: 13,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const Gap(60),
            OutlinedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY AUTHENTICATION'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ).animate().fadeIn(delay: 800.ms),
            const Gap(16),
            TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              child: const Text(
                'SWITCH ACCOUNT',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
