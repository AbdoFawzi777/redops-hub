import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:redops_hub/core/router/app_routes.dart';

class BiometricScreen extends StatelessWidget {
  const BiometricScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // أيقونة البصمة / القفل الأمني
              Icon(
                Icons.fingerprint_rounded,
                size: 90,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Authentication Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please authenticate using your biometrics to access the secure terminal.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // زرار المحاكاة الفعلي لتسجيل الدخول
              ElevatedButton.icon(
                onPressed: () {
                  // الانتقال إلى لوحة التحكم عند نجاح البصمة
                  context.go(AppRoutes.c2);
                },
                icon: const Icon(Icons.security_rounded),
                label: const Text('Authorize & Enter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
              // زرار جانبي خفيف لو حابب تتخطى مؤقتاً
              TextButton(
                onPressed: () => context.go(AppRoutes.c2),
                child: Text(
                  'Bypass (Development Only)',
                  style: TextStyle(color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}