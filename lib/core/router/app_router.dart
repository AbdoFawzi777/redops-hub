import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:redops_hub/features/auth/presentation/providers/auth_providers.dart';
import 'package:redops_hub/features/auth/presentation/screens/login_screen.dart';
import 'package:redops_hub/features/auth/presentation/screens/biometrics_screen.dart';
import 'package:redops_hub/features/auth/presentation/screens/splash_screen.dart';
import 'package:redops_hub/features/auth/presentation/screens/pin_setup_screen.dart';
import 'package:redops_hub/features/auth/presentation/screens/pin_gate_screen.dart';
import 'package:redops_hub/features/c2_dashboard/presentation/screens/c2_dashboard_screen.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/screens/vuln_tracker_screen.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/screens/vuln_create_screen.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/screens/vuln_detail_screen.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/screens/live_intel_screen.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/screens/hacker_intel_screen.dart';
import 'package:redops_hub/features/field_reporter/presentation/screens/field_reporter_screen.dart';
import 'package:redops_hub/features/payload_vault/presentation/screens/payload_vault_screen.dart';
import 'package:redops_hub/features/dev_playbooks/presentation/screens/playbooks_screen.dart';
import 'package:redops_hub/features/settings/presentation/screens/settings_screen.dart';
import 'package:redops_hub/features/settings/presentation/screens/profile_screen.dart';
import 'package:redops_hub/features/settings/presentation/screens/web_console_info_screen.dart';
import 'package:redops_hub/features/chat_forum/presentation/screens/chat_forum_screen.dart';
import '../../shared/widgets/main_shell.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool>(false);
  
  // نراقب حالة التسجيل والـ PIN والأوفلاين
  ref.listen(authStateProvider, (_, __) => listenable.value = !listenable.value);
  ref.listen(isSessionUnlockedProvider, (_, __) => listenable.value = !listenable.value);
  ref.listen(isOfflineModeProvider, (_, __) => listenable.value = !listenable.value);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final currentPath = state.uri.toString();
      if (currentPath == AppRoutes.splash) return null;

      final isOfflineMode = ref.read(isOfflineModeProvider);
      final isPinEnabled = ref.read(isPinEnabledProvider);
      final isUnlocked = ref.read(isSessionUnlockedProvider);
      
      User? user;
      if (Firebase.apps.isNotEmpty) {
        try {
          user = FirebaseAuth.instance.currentUser;
        } catch (_) {}
      }

      final isLoggingIn = currentPath == AppRoutes.login;
      final isPinGate = currentPath == AppRoutes.pinGate;

      // 1. Offline Mode Bypass
      if (isOfflineMode) {
        return isLoggingIn ? AppRoutes.c2 : null;
      }

      // 2. Auth Gate
      if (user == null) {
        return isLoggingIn ? null : AppRoutes.login;
      }

      // 3. PIN Gate
      if (isPinEnabled && !isUnlocked) {
        return isPinGate ? null : AppRoutes.pinGate;
      }

      // 4. Main Entry Redirect (عند النجاح ننتقل لـ C2)
      if (isLoggingIn || isPinGate) {
        return AppRoutes.c2;
      }

      return null;
    },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.pinGate,
      builder: (context, state) => const PinGateScreen(),
    ),
    GoRoute(
      path: AppRoutes.biometrics,
      builder: (context, state) => const BiometricsScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.c2,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: C2DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.vulns,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VulnTrackerScreen(),
          ),
          routes: [
            GoRoute(
              path: 'live',
              builder: (context, state) => const LiveIntelScreen(),
            ),
            GoRoute(
              path: 'hacker-news',
              builder: (context, state) => const HackerIntelScreen(),
            ),
            GoRoute(
              path: 'create',
              builder: (context, state) => const VulnCreateScreen(),
            ),
            GoRoute(
              path: ':vulnId',
              builder: (context, state) => VulnDetailScreen(
                vulnId: state.pathParameters['vulnId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.reporter,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FieldReporterScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.vault,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PayloadVaultScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.playbooks,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaybooksScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.chatForum,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatForumScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: 'pin-setup',
              builder: (context, state) => const PinSetupScreen(),
            ),
            GoRoute(
              path: 'web-console',
              builder: (context, state) => const WebConsoleInfoScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
});
