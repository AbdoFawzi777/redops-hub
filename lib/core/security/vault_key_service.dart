import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

abstract final class VaultKeyService {
  static const _storage = FlutterSecureStorage();

  static Future<Uint8List> getOrCreateKey() async {
    final stored = await _storage.read(key: AppConstants.keyEncryptKey);
    if (stored != null) {
      return Uint8List.fromList(stored.codeUnits);
    }
    final key = _generateKey();
    await _storage.write(
      key: AppConstants.keyEncryptKey,
      value: String.fromCharCodes(key),
    );
    return key;
  }

  static Uint8List _generateKey() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List.generate(32, (_) => rng.nextInt(256)),
    );
  }
}