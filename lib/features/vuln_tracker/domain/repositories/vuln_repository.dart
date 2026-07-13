import '../entities/vulnerability.dart';

abstract class VulnRepository {
  Stream<List<Vulnerability>> watchAll();

  Future<List<Vulnerability>> getAll();

  Future<Vulnerability?> getById(String id);

  Future<Vulnerability> create(Vulnerability vulnerability);

  Future<Vulnerability> update(Vulnerability vulnerability);

  Future<void> delete(String id);

  Future<Vulnerability> addComment(String vulnId, VulnComment comment);

  Future<void> seedIfEmpty();
}
