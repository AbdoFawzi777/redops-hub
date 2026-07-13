import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapResult {
  FirebaseBootstrapResult({
    required this.isReady,
    required this.statusMessage,
  });

  final bool isReady;
  final String statusMessage;
}

class FirebaseBootstrapService {
  FirebaseBootstrapService._();
  static final instance = FirebaseBootstrapService._();

  bool get isReady => Firebase.apps.isNotEmpty;
  
  String get statusMessage {
    if (Firebase.apps.isNotEmpty) {
      return 'Secure Tactical Link Established';
    }
    return 'Local Protocol Active (Offline)';
  }

  // This is now just a dummy call for compatibility with existing code, 
  // as actual init happens in main.dart
  Future<FirebaseBootstrapResult> initialize() async {
    return FirebaseBootstrapResult(
      isReady: isReady,
      statusMessage: statusMessage,
    );
  }
}
