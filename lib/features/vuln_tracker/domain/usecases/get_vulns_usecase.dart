import '../entities/vulnerability.dart';
import '../repositories/vuln_repository.dart';

class GetVulnsUseCase {
  const GetVulnsUseCase(this._repository);

  final VulnRepository _repository;

  Stream<List<Vulnerability>> watch() => _repository.watchAll();

  Future<List<Vulnerability>> call() => _repository.getAll();
}
