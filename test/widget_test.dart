// This is a basic Flutter widget test for RedOps Hub.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redops_hub/main.dart';

void main() {
  testWidgets('RedOps Hub App navigation smoke test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame inside a ProviderScope for Riverpod.
    await tester.pumpWidget(
      const ProviderScope(
        child: RedOpsHubApp(),
      ),
    );

    // التحقق من أن التطبيق فتح بنجاح ويحتوي على أزرار القائمة السفلية الأساسية
    expect(find.text('C2'), findsOneWidget);
    expect(find.text('Vulns'), findsOneWidget);

    // التحقق من عدم وجود نصوص الـ Counter القديمة
    expect(find.text('0'), findsNothing);
  });
}
