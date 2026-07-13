import '../../domain/entities/vulnerability.dart';
import '../../domain/repositories/vuln_repository.dart';
import '../datasources/vuln_local_datasource.dart';

class VulnRepositoryImpl implements VulnRepository {
  VulnRepositoryImpl(this._local);

  final VulnLocalDataSource _local;

  @override
  Stream<List<Vulnerability>> watchAll() => _local.watchAll();

  @override
  Future<List<Vulnerability>> getAll() => _local.getAll();

  @override
  Future<Vulnerability?> getById(String id) => _local.getById(id);

  @override
  Future<Vulnerability> create(Vulnerability vulnerability) {
    return _local.save(vulnerability);
  }

  @override
  Future<Vulnerability> update(Vulnerability vulnerability) {
    return _local.save(vulnerability);
  }

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<Vulnerability> addComment(String vulnId, VulnComment comment) async {
    final existing = await _local.getById(vulnId);
    if (existing == null) {
      throw StateError('Vulnerability not found: $vulnId');
    }
    final updated = existing.copyWith(
      comments: [...existing.comments, comment],
      updatedAt: DateTime.now(),
    );
    return _local.save(updated);
  }

  @override
  Future<void> seedIfEmpty() => _local.seedIfEmpty();
}
