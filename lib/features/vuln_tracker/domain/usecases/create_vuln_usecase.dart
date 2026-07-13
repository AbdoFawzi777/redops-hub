import '../entities/vulnerability.dart';
import '../repositories/vuln_repository.dart';

class CreateVulnUseCase {
  const CreateVulnUseCase(this._repository);

  final VulnRepository _repository;

  Future<Vulnerability> call(Vulnerability vulnerability) {
    if (vulnerability.title.trim().isEmpty) {
      throw ArgumentError('Title is required');
    }
    return _repository.create(vulnerability);
  }
}
