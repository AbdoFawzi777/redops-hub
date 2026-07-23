import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:redops_hub/core/router/app_router.dart';
import 'package:redops_hub/core/router/app_routes.dart';
import 'package:redops_hub/core/theme/app_theme.dart';
import 'package:redops_hub/core/services/tactical_notification_service.dart';
import 'package:redops_hub/features/vuln_tracker/data/datasources/vuln_local_datasource.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/providers/vuln_providers.dart';
import 'package:redops_hub/features/vuln_tracker/domain/entities/vulnerability.dart';
import 'package:redops_hub/features/chat_forum/presentation/providers/chat_providers.dart';
import 'package:redops_hub/features/chat_forum/domain/entities/chat_message.dart';
import 'package:redops_hub/core/services/threat_intel_service.dart';
import 'package:redops_hub/core/services/cached_search_service.dart';
import 'package:redops_hub/core/services/sync_service.dart';
import 'package:redops_hub/firebase_options.dart';

// Stream of system updates from Firestore
final appUpdateStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  try {
    if (Firebase.apps.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('system_updates')
        .doc('latest')
        .snapshots()
        .map((snap) => snap.data());
  } catch (_) {
    return const Stream.empty();
  }
});

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('MAIN: System initializing...');

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('CRITICAL FLUTTER ERROR: ${details.exception}');
    };

    await Future.delayed(const Duration(milliseconds: 150));

    try {
      bool alreadyInitialized = false;
      try {
        alreadyInitialized = Firebase.apps.isNotEmpty;
      } catch (_) {}

      if (!alreadyInitialized) {
        debugPrint('MAIN: Calling Firebase.initializeApp...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      debugPrint('MAIN: Firebase initialized successfully.');

      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
        );
        debugPrint('MAIN: App Check active with Production/PlayIntegrity providers.');
      } catch (e) {
        debugPrint('MAIN: App Check skipped/error -> $e');
      }
    } catch (e) {
      debugPrint('MAIN: Firebase CRITICAL error -> $e');
    }

    await Hive.initFlutter();
    await Hive.openBox('redops_settings');

    await ThreatIntelService().init();
    await CachedSearchService().init();
    await SyncService().init();

    final vulnDataSource = await VulnLocalDataSource.open();
    await vulnDataSource.seedIfEmpty();

    runApp(
      ProviderScope(
        overrides: [
          vulnLocalDataSourceProvider.overrideWithValue(vulnDataSource),
        ],
        child: const RedOpsHubApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('UNCAUGHT ASYNC EXCEPTION: $error\n$stack');
  });
}

class RedOpsHubApp extends ConsumerWidget {
  const RedOpsHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider);
    final router = ref.watch(appRouterProvider);

    ref.listen<ThemeMode>(themeModeProvider, (previous, next) {
      try {
        final box = Hive.box('redops_settings');
        box.put('theme_mode', next.index);
      } catch (_) {}
    });

    ref.listen<Locale>(languageProvider, (previous, next) {
      try {
        final box = Hive.box('redops_settings');
        box.put('language_code', next.languageCode);
      } catch (_) {}
    });

    // 1. System Updates Listener with Custom Update Ringtone
    ref.listen<AsyncValue<Map<String, dynamic>?>>(appUpdateStreamProvider, (previous, next) {
      next.whenData((data) {
        if (data != null) {
          final version = data['version'] as String?;
          final prevVersion = previous?.value?['version'] as String?;
          if (version != null && version != '1.0.0' && version != prevVersion) {
            TacticalNotificationService.showTacticalBanner(
              context,
              title: 'SYSTEM UPDATE AVAILABLE',
              message: 'Version $version is ready for tactical deployment.',
              type: NotificationToneType.systemUpdate,
            );
          }
        }
      });
    });

    // 2. Vulnerability Listener with Distinct Ringtone per Severity
    ref.listen<AsyncValue<List<Vulnerability>>>(vulnsStreamProvider, (previous, next) {
      next.whenData((vulns) {
        if (vulns.isNotEmpty) {
          final prevVulns = previous?.value;
          if (prevVulns != null && vulns.length > prevVulns.length) {
            final newVuln = vulns.first;
            final tone = TacticalNotificationService.getToneForSeverity(newVuln.severity);

            TacticalNotificationService.showTacticalBanner(
              context,
              title: '${newVuln.severity.label.toUpperCase()} THREAT DETECTED',
              message: '${newVuln.title} (Target: ${newVuln.projectName})',
              type: tone,
              onTap: () {
                ref.read(appRouterProvider).push(AppRoutes.vulnDetailPath(newVuln.id));
              },
            );
          }
        }
      });
    });

    // 3. Chat Messages Listener with Custom Comm Ping Ringtone
    ref.listen<AsyncValue<List<ChatMessage>>>(chatMessagesStreamProvider, (previous, next) {
      next.whenData((messages) {
        if (messages.isNotEmpty) {
          final prevMessages = previous?.value;
          if (prevMessages != null && messages.length > prevMessages.length) {
            final latestMsg = messages.first;
            String? myEmail;
            try {
              if (Firebase.apps.isNotEmpty) {
                myEmail = FirebaseAuth.instance.currentUser?.email;
              }
            } catch (_) {}

            if (latestMsg.senderEmail != myEmail) {
              final routerConfig = ref.read(appRouterProvider);
              final currentPath = routerConfig.routeInformationProvider.value.uri.toString();

              if (currentPath != AppRoutes.chatForum) {
                TacticalNotificationService.showTacticalBanner(
                  context,
                  title: 'TACTICAL COMM: ${latestMsg.senderName}',
                  message: latestMsg.text,
                  type: NotificationToneType.chatMessage,
                  actionLabel: 'OPEN CHAT',
                  onTap: () => routerConfig.push(AppRoutes.chatForum),
                );
              }
            }
          }
        }
      });
    });

    return MaterialApp.router(
      title: 'RedOps Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
