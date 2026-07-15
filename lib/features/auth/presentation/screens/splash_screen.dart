import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('SPLASH: Screen Initialized');
    _startTransition();
  }

  void _startTransition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (kDebugMode && !kReleaseMode) {
        debugPrint('SPLASH: Skipping delayed transition in debug mode');
        _navigateToLogin();
        return;
      }

      Future.delayed(const Duration(milliseconds: 4500), () {
        if (!mounted) return;
        debugPrint('SPLASH: Attempting to navigate to Login via context.go');
        _navigateToLogin();
      });
    });
  }

  void _navigateToLogin() {
    const targetPath = AppRoutes.login;
    try {
      context.go(targetPath);
    } catch (e) {
      debugPrint('SPLASH: Navigation error: $e');
      context.pushReplacement(targetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && !kReleaseMode) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.jpg',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const Gap(24),
                const Text(
                  'REDOPS HUB',
                  style: TextStyle(
                    color: AppColors.deepBlue,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Gap(12),
                Text(
                  'ESTABLISHING SECURE PROTOCOL',
                  style: TextStyle(
                    color: AppColors.deepBlue.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: const Text('C2'),
                      backgroundColor:
                          AppColors.deepBlue.withValues(alpha: 0.08),
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      label: const Text('Vulns'),
                      backgroundColor:
                          AppColors.redPrimary.withValues(alpha: 0.08),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    const int gridSize = 8;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Ambient Glow
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.deepBlue.withValues(alpha: 0.05),
                    Colors.white,
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 3.seconds),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2. LOGO ASSEMBLY
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    children: [
                      // Final Logo Integrated
                      Center(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ).animate().fadeIn(delay: 3000.ms, duration: 600.ms),
                      ),

                      // Scattered Logo Pieces
                      for (int i = 0; i < gridSize; i++)
                        for (int j = 0; j < gridSize; j++)
                          _LogoFragment(
                            row: i,
                            col: j,
                            gridSize: gridSize,
                          ),
                    ],
                  ),
                ),

                const Gap(60),

                // 3. COLLIDING TITLE
                _CollidingTitle(),

                const Gap(20),

                // 4. STATUS
                Text(
                  'ESTABLISHING SECURE PROTOCOL',
                  style: TextStyle(
                    color: AppColors.deepBlue.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ).animate().fadeIn(delay: 2500.ms),

                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: const Text('C2'),
                      backgroundColor:
                          AppColors.deepBlue.withValues(alpha: 0.08),
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      label: const Text('Vulns'),
                      backgroundColor:
                          AppColors.redPrimary.withValues(alpha: 0.08),
                    ),
                  ],
                ),

                // Fallback manual button
                const Gap(40),
                GestureDetector(
                  onTap: () {
                    debugPrint('SPLASH: Manual tap on text');
                    context.go(AppRoutes.login);
                  },
                  child: Text('TAP TO INITIATE',
                      style: TextStyle(
                          color: AppColors.textTertiary.withValues(alpha: 0.3),
                          fontSize: 10)),
                ).animate().fadeIn(delay: 5000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoFragment extends StatelessWidget {
  final int row;
  final int col;
  final int gridSize;

  const _LogoFragment({
    required this.row,
    required this.col,
    required this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    final double blockSize = 180 / gridSize;
    final math.Random random = math.Random(row * gridSize + col);

    final double startX = (random.nextDouble() - 0.5) * 800;
    final double startY = (random.nextDouble() - 0.5) * 1000;
    final double delay = random.nextDouble() * 1500;

    return Positioned(
      left: 10 + (col * blockSize),
      top: 10 + (row * blockSize),
      child: Container(
        width: blockSize,
        height: blockSize,
        decoration: BoxDecoration(
          color: AppColors.deepBlue.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.deepBlue.withValues(alpha: 0.05)),
        ),
      )
          .animate()
          .custom(
            duration: 2500.ms,
            delay: delay.ms,
            curve: Curves.easeInOutExpo,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(startX * (1 - value), startY * (1 - value)),
                child: Transform.rotate(
                  angle: (1 - value) * math.pi * 2,
                  child: Opacity(
                    opacity: value.clamp(0, 1),
                    child: child,
                  ),
                ),
              );
            },
          )
          .then(delay: 500.ms)
          .fadeOut(duration: 400.ms),
    );
  }
}

class _CollidingTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: AppColors.deepBlue,
      fontSize: 38,
      fontWeight: FontWeight.w900,
      letterSpacing: 4,
      fontFamily: 'serif',
      shadows: [
        Shadow(color: Colors.blueAccent, blurRadius: 15),
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('RED', style: textStyle)
            .animate()
            .fadeIn(delay: 1500.ms)
            .moveX(
                begin: -200,
                end: 0,
                duration: 1000.ms,
                curve: Curves.bounceOut),
        const Gap(10),
        const Text('OPS', style: textStyle)
            .animate()
            .fadeIn(delay: 1500.ms)
            .moveX(
                begin: 200, end: 0, duration: 1000.ms, curve: Curves.bounceOut),
      ],
    ).animate().shimmer(delay: 3500.ms, duration: 1500.ms);
  }
}
