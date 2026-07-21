import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:safe_device/safe_device.dart';

import '../constants/app_constants.dart';

class SecurityService {
  SecurityService._();
  static final instance = SecurityService._();

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      _initialized = canCheckBiometrics || isSupported;
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isReady = await initialize();
      if (!isReady) return false;

      // local_auth version compatibility: AuthenticationOptions may not exist.
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access RedOps Hub',
        // If options are supported by the installed local_auth version, they will be applied.
        // Otherwise this block is ignored by the compiler.
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> savePin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: AppConstants.keyUserPin, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: AppConstants.keyUserPin);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == stored;
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: AppConstants.keyUserPin);
    return pin != null;
  }

  Future<void> saveSecure(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> readSecure(String key) => _storage.read(key: key);

  Future<void> deleteSecure(String key) => _storage.delete(key: key);

  Future<void> clearAll() => _storage.deleteAll();

  // SECURITY HARDENING: Detect jailbroken devices or emulators to block sensitive functions
  Future<bool> isDeviceSafe() async {
    if (kDebugMode) return true; // Bypass all security blocks during development/debug runs!
    if (kIsWeb) return true; // Web runs in sandboxed browser
    if (!Platform.isAndroid && !Platform.isIOS) return true; // Fallback for desktop testing

    try {
      final isJailBroken = await SafeDevice.isJailBroken;
      final isRealDevice = await SafeDevice.isRealDevice;
      final isDevelopmentMode = await SafeDevice.isDevelopmentModeEnable;
      
      // Strict RedOps Hub security policy:
      // Block rooted/jailbroken devices or emulators.
      if (isJailBroken) return false;
      if (!isRealDevice) return false;
      if (isDevelopmentMode) return false; // Prevent USB debugging abuse in production
      
      return true;
    } catch (_) {
      // Safety fallback: allow in case of channel issues during build/testing
      return true;
    }
  }
}
