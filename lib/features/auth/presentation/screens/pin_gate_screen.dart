import 'dart:async' as dart_async;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_providers.dart';

class PinGateScreen extends ConsumerStatefulWidget {
  const PinGateScreen({super.key});

  @override
  ConsumerState<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends ConsumerState<PinGateScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;
  dart_async.Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _startLockoutCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _startLockoutCheck() {
    _timer = dart_async.Timer.periodic(const Duration(seconds: 1), (timer) {
      final lockoutUntil = ref.read(lockoutUntilProvider);
      if (lockoutUntil != null) {
        final diff = lockoutUntil.difference(DateTime.now()).inSeconds;
        if (diff > 0) {
          if (mounted) setState(() => _secondsRemaining = diff);
        } else {
          ref.read(lockoutUntilProvider.notifier).state = null;
          if (mounted) setState(() => _secondsRemaining = 0);
        }
      }
    });
  }

  void _checkBiometrics() async {
    final lockoutUntil = ref.read(lockoutUntilProvider);
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) return;

    final settings = ref.read(securitySettingsProvider);
    if (settings.isBiometricsEnabled) {
      final success = await ref.read(authControllerProvider.notifier).authenticateWithBiometrics();
      if (success && mounted) {
        context.go(AppRoutes.c2);
      }
    }
  }

  void _verify() async {
    final success = await ref.read(authControllerProvider.notifier).verifyPin(_pinController.text);
    if (success) {
      if (mounted) context.go(AppRoutes.c2);
    } else {
      setState(() => _isError = true);
      _pinController.clear();
      Future.delayed(2.seconds, () {
        if (mounted) setState(() => _isError = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;
    final lockoutUntil = ref.watch(lockoutUntilProvider);
    final isLocked = lockoutUntil != null && DateTime.now().isBefore(lockoutUntil);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg900 : AppColors.lightScaffold,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.timer_off_outlined : Icons.shield_outlined, 
                size: 80, 
                color: isLocked ? AppColors.criticalFg : AppColors.textTertiary
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2.seconds),
              const Gap(32),
              Text(
                isLocked ? 'SYSTEM LOCKOUT' : 'SECURITY CHALLENGE',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2,
                  color: isLocked ? AppColors.criticalFg : (isDark ? Colors.white : AppColors.deepBlue)
                ),
              ),
              const Gap(8),
              Text(
                isLocked 
                  ? 'Multiple failed attempts. Try again in $_secondsRemaining seconds.' 
                  : 'Enter access code to unlock terminal',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
              const Gap(40),
              if (!isLocked)
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _pinController,
                    obscureText: true,
                    enabled: !isLocked,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    onChanged: (v) {
                      if (v.length == 4) _verify();
                    },
                    style: TextStyle(
                      fontSize: 32, 
                      letterSpacing: 20, 
                      fontWeight: FontWeight.bold,
                      color: _isError ? AppColors.criticalFg : (isDark ? Colors.white : AppColors.deepBlue)
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '••••',
                    ),
                  ),
                ),
              if (_isError && !isLocked)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'INVALID ACCESS CODE',
                    style: TextStyle(color: AppColors.criticalFg, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ).animate().shake(),
              if (!isLocked) ...[
                const Gap(24),
                if (ref.watch(securitySettingsProvider).isBiometricsEnabled)
                  IconButton(
                    onPressed: _checkBiometrics,
                    icon: Icon(Icons.fingerprint, size: 48, color: primaryColor),
                    tooltip: 'USE BIOMETRICS',
                  ).animate().fadeIn(),
              ],
              const Gap(40),
              TextButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('SWITCH OPERATOR', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
