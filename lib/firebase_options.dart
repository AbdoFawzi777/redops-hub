import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDfuULBbTywKiN89zLvMN_0sT55dZD0ww',
    appId: '1:1074549343563:android:66a357b9834ccaccdb14ce',
    messagingSenderId: '1074549343563',
    projectId: 'redops-hub',
    storageBucket: 'redops-hub.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDfuULBbTywKiN89zLvMN_0sT55dZD0ww',
    appId: '1:1074549343563:android:66a357b9834ccaccdb14ce',
    messagingSenderId: '1074549343563',
    projectId: 'redops-hub',
    storageBucket: 'redops-hub.firebasestorage.app',
  );
}
