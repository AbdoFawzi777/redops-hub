import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/security/security_service.dart';

final firebaseBootstrapProvider = Provider<FirebaseBootstrapService>(
    (ref) => FirebaseBootstrapService.instance);

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FirebaseAuth.instance;
});

final isFirebaseReadyProvider =
    Provider<bool>((ref) => ref.watch(firebaseBootstrapProvider).isReady);

final firebaseStatusProvider = Provider<String>(
    (ref) => ref.watch(firebaseBootstrapProvider).statusMessage);

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) return const Stream.empty();
  return auth.authStateChanges();
});

final biometricAuthProvider =
    Provider<LocalAuthentication>((ref) => LocalAuthentication());

final securityServiceProvider =
    Provider<SecurityService>((ref) => SecurityService.instance);

// Persistent Security Settings
class SecuritySettings {
  final bool isPinSet;
  final bool isBiometricsEnabled;

  SecuritySettings({required this.isPinSet, required this.isBiometricsEnabled});
}

final securitySettingsProvider = StateProvider<SecuritySettings>((ref) {
  try {
    final box = Hive.box('redops_settings');
    return SecuritySettings(
      isPinSet: box.get('is_pin_set', defaultValue: false),
      isBiometricsEnabled:
          box.get('is_biometrics_enabled', defaultValue: false),
    );
  } catch (_) {
    return SecuritySettings(
      isPinSet: false,
      isBiometricsEnabled: false,
    );
  }
});

final isSessionUnlockedProvider = StateProvider<bool>((ref) => false);
final isOfflineModeProvider = StateProvider<bool>((ref) => false);

// منطق الحظر وعدد المحاولات
final authAttemptsProvider = StateProvider<int>((ref) => 0);
final lockoutUntilProvider = StateProvider<DateTime?>((ref) => null);

// PIN System Logic
final pinCodeProvider = StateProvider<String?>((ref) {
  final box = Hive.box('redops_settings');
  return box.get('security_pin');
});

final isPinEnabledProvider = Provider<bool>((ref) {
  return ref.watch(pinCodeProvider) != null;
});

final isBiometricsSupportedProvider = FutureProvider<bool>((ref) async {
  return ref.read(securityServiceProvider).initialize();
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._auth, this._googleSignIn, this._ref)
      : super(const AsyncData(null));

  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  final Ref _ref;

  void enterOfflineMode() {
    _ref.read(isOfflineModeProvider.notifier).state = true;
  }

  Future<void> setPinCode(String pin) async {
    final box = Hive.box('redops_settings');
    await box.put('security_pin', pin);
    await box.put('is_pin_set', true);
    _ref.read(pinCodeProvider.notifier).state = pin;
    
    final currentSettings = _ref.read(securitySettingsProvider);
    _ref.read(securitySettingsProvider.notifier).state = SecuritySettings(
      isPinSet: true,
      isBiometricsEnabled: currentSettings.isBiometricsEnabled,
    );
  }

  Future<void> toggleBiometrics(bool enabled) async {
    final box = Hive.box('redops_settings');
    await box.put('is_biometrics_enabled', enabled);
    
    final currentSettings = _ref.read(securitySettingsProvider);
    _ref.read(securitySettingsProvider.notifier).state = SecuritySettings(
      isPinSet: currentSettings.isPinSet,
      isBiometricsEnabled: enabled,
    );
  }

  bool _checkLockout() {
    final lockoutUntil = _ref.read(lockoutUntilProvider);
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      return true;
    }
    if (lockoutUntil != null && DateTime.now().isAfter(lockoutUntil)) {
      _ref.read(lockoutUntilProvider.notifier).state = null;
      _ref.read(authAttemptsProvider.notifier).state = 0;
    }
    return false;
  }

  void _handleFailure() {
    final attempts = _ref.read(authAttemptsProvider) + 1;
    _ref.read(authAttemptsProvider.notifier).state = attempts;

    if (attempts >= 3) {
      // حظر لمدة دقيقة عند أول 3 محاولات، ثم تضاعف المدة
      final penaltyMinutes = (attempts - 2) * 1; 
      _ref.read(lockoutUntilProvider.notifier).state = 
          DateTime.now().add(Duration(minutes: penaltyMinutes));
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (_checkLockout()) return false;

    final success = await _ref.read(securityServiceProvider).authenticateWithBiometrics();
    if (success) {
      _ref.read(isSessionUnlockedProvider.notifier).state = true;
      _ref.read(authAttemptsProvider.notifier).state = 0;
    } else {
      _handleFailure();
    }
    return success;
  }

  Future<bool> verifyPin(String pin) async {
    if (_checkLockout()) return false;

    final storedPin = _ref.read(pinCodeProvider);
    if (storedPin == pin) {
      _ref.read(isSessionUnlockedProvider.notifier).state = true;
      _ref.read(authAttemptsProvider.notifier).state = 0;
      return true;
    }
    
    _handleFailure();
    return false;
  }

  void unlockSession() {
    _ref.read(isSessionUnlockedProvider.notifier).state = true;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      if (_auth == null) {
        throw Exception('Firebase Tactical Link is currently offline. Please use Offline Mode.');
      }
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncData(null);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth!.signInWithCredential(credential);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signInWithGitHub() async {
    state = const AsyncLoading();
    try {
      if (_auth == null) {
        throw Exception('Firebase Tactical Link is currently offline. Please use Offline Mode.');
      }
      
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      await _auth!.signInWithProvider(githubProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _googleSignIn.signOut();
      if (_auth != null) await _auth!.signOut();
      _ref.read(isSessionUnlockedProvider.notifier).state = false;
      _ref.read(isOfflineModeProvider.notifier).state = false;
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthNotifier(
    auth,
    GoogleSignIn(
      serverClientId: '1074549343563-03m8ualudrp0o5m03269lrd733dmg9c8.apps.googleusercontent.com',
    ),
    ref,
  );
});
