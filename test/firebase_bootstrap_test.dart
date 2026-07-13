import 'package:flutter_test/flutter_test.dart';
import 'package:redops_hub/core/firebase/firebase_bootstrap.dart';

void main() {
  test('firebase bootstrap reports a clear status for the current platform',
      () async {
    final result = await FirebaseBootstrapService.instance.initialize();

    expect(result.statusMessage, isNotEmpty);
  });
}
