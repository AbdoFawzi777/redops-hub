import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:redops_hub/core/router/app_router.dart';
import 'package:redops_hub/core/theme/app_theme.dart';
import 'package:redops_hub/features/vuln_tracker/data/datasources/vuln_local_datasource.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/providers/vuln_providers.dart';
import 'package:redops_hub/firebase_options.dart';

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
