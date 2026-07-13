import 'dart:async';

import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/security/vault_key_service.dart';
import '../../domain/entities/vulnerability.dart';
import '../models/vuln_model.dart';
import 'vuln_seed_data.dart';

class VulnLocalDataSource {
  VulnLocalDataSource(this._box);

  final Box<VulnModel> _box;

  Stream<List<Vulnerability>> watchAll() {
    final controller = StreamController<List<Vulnerability>>();

    void emit() {
      if (!controller.isClosed) {
        controller.add(_readAll());
      }
    }

    emit();
    final sub = _box.watch().listen((_) => emit());

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  List<Vulnerability> _readAll() {
    return _box.values
        .map((model) => model.toEntity())
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<Vulnerability>> getAll() async => _readAll();

  Future<Vulnerability?> getById(String id) async {
    final model = _box.get(id);
    return model?.toEntity();
  }

  Future<Vulnerability> save(Vulnerability vulnerability) async {
    final model = VulnModel.fromEntity(vulnerability);
    await _box.put(vulnerability.id, model);
    return vulnerability;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> seedIfEmpty() async {
    if (_box.isNotEmpty) return;

    for (final vuln in VulnSeedData.demoFindings) {
      await _box.put(vuln.id, VulnModel.fromEntity(vuln));
    }
  }

  static Future<VulnLocalDataSource> open() async {
    if (!Hive.isAdapterRegistered(AppConstants.typeIdVulnModel)) {
      Hive.registerAdapter(VulnModelAdapter());
    }
    
    final key = await VaultKeyService.getOrCreateKey();
    Box<VulnModel> box;
    try {
      box = await Hive.openBox<VulnModel>(
        AppConstants.boxVulns,
        encryptionCipher: HiveAesCipher(key),
      );
    } catch (_) {
      // If opening with encryption fails (e.g. if the box on disk was unencrypted),
      // delete the local box files and open a fresh encrypted one.
      await Hive.deleteBoxFromDisk(AppConstants.boxVulns);
      box = await Hive.openBox<VulnModel>(
        AppConstants.boxVulns,
        encryptionCipher: HiveAesCipher(key),
      );
    }
    return VulnLocalDataSource(box);
  }
}
