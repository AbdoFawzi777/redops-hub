// This is a basic Flutter widget test for RedOps Hub.
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:redops_hub/main.dart';
import 'package:redops_hub/features/vuln_tracker/data/datasources/vuln_local_datasource.dart';
import 'package:redops_hub/features/vuln_tracker/presentation/providers/vuln_providers.dart';

void main() {
  late Directory tempDir;
  late VulnLocalDataSource vulnDataSource;

  setUpAll(() async {
    // Mock flutter_secure_storage platform channel calls
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return null; // Return null to simulate empty key storage
      }
      if (methodCall.method == 'write') {
        return null;
      }
      return null;
    });

    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox('redops_settings');
    vulnDataSource = await VulnLocalDataSource.open();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('RedOps Hub App navigation smoke test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame inside a ProviderScope for Riverpod.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vulnLocalDataSourceProvider.overrideWithValue(vulnDataSource),
        ],
        child: const RedOpsHubApp(),
      ),
    );

    // التحقق من أن التطبيق فتح بنجاح ويحتوي على أزرار القائمة السفلية الأساسية
    expect(find.text('C2'), findsOneWidget);
    expect(find.text('Vulns'), findsOneWidget);

    // التحقق من عدم وجود نصوص الـ Counter القديمة
    expect(find.text('0'), findsNothing);
  });
}
