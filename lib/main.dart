import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:redops_hub/core/router/app_router.dart';
import 'package:redops_hub/core/router/app_routes.dart';
import 'package:redops_hub/core/theme/app_colors.dart';
import 'package:redops_hub/core/theme/app_theme.dart';
import 'package:redops_hub/features/vuln_tracker/data/datasources/vuln_local_datasource.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/providers/vuln_providers.dart';
import 'package:redops_hub/features/vuln_tracker/domain/entities/vulnerability.dart';
import 'package:redops_hub/features/chat_forum/presentation/providers/chat_providers.dart';
import 'package:redops_hub/features/chat_forum/domain/entities/chat_message.dart';
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
  // 1. Critical: Ensure native channels are bound
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('MAIN: System initializing...');

  // Give the native side a moment to fully settle its channels
  await Future.delayed(const Duration(milliseconds: 200));

  try {
    // 2. Initialize Firebase
    debugPrint('MAIN: Checking Firebase apps...');
    // We use a try-catch even for the check because it might throw channel-error
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

    // 3. Optional: App Check
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

  // 4. Local Storage & DB
  await Hive.initFlutter();
  await Hive.openBox('redops_settings');

  final vulnDataSource = await VulnLocalDataSource.open();
  await vulnDataSource.seedIfEmpty();

  // 5. App Launch
  runApp(
    ProviderScope(
      overrides: [
        vulnLocalDataSourceProvider.overrideWithValue(vulnDataSource),
      ],
      child: const RedOpsHubApp(),
    ),
  );
}

class RedOpsHubApp extends ConsumerWidget {
  const RedOpsHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider);
    final router = ref.watch(appRouterProvider);

    // Save preferences to Hive when changed
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

    // 1. Listen to app updates
    ref.listen<AsyncValue<Map<String, dynamic>?>>(appUpdateStreamProvider, (previous, next) {
      next.whenData((data) {
        if (data != null) {
          final version = data['version'] as String?;
          final prevVersion = previous?.value?['version'] as String?;
          if (version != null && version != '1.0.0' && version != prevVersion) {
            SystemSound.play(SystemSoundType.alert);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚡ TACTICAL UPDATE AVAILABLE: Version $version is ready!'),
                backgroundColor: AppColors.live,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 6),
              ),
            );
          }
        }
      });
    });

    // 2. Listen to vulnerabilities (new threats)
    ref.listen<AsyncValue<List<Vulnerability>>>(vulnsStreamProvider, (previous, next) {
      next.whenData((vulns) {
        if (vulns.isNotEmpty) {
          final prevVulns = previous?.value;
          if (prevVulns != null && vulns.length > prevVulns.length) {
            SystemSound.play(SystemSoundType.alert);
            final newVuln = vulns.first;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ NEW THREAT DETECTED: ${newVuln.title}'),
                backgroundColor: AppColors.criticalFg,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    });

    // 3. Listen to messages (new chat messages)
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
              SystemSound.play(SystemSoundType.alert);
              
              // Only show banner if we are not in the chat screen
              final routerConfig = ref.read(appRouterProvider);
              final currentPath = routerConfig.routeInformationProvider.value.uri.toString();
              if (currentPath != AppRoutes.chatForum) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('💬 ${latestMsg.senderName}: ${latestMsg.text}'),
                    backgroundColor: AppColors.deepBlue,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'OPEN',
                      textColor: Colors.white,
                      onPressed: () => routerConfig.push(AppRoutes.chatForum),
                    ),
                  ),
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
