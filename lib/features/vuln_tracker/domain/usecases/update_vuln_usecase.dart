import '../entities/vulnerability.dart';
import '../repositories/vuln_repository.dart';

class UpdateVulnUseCase {
  const UpdateVulnUseCase(this._repository);

  final VulnRepository _repository;

  Future<Vulnerability> call(Vulnerability vulnerability) {
    return _repository.update(
      vulnerability.copyWith(updatedAt: DateTime.now()),
    );
  }
}
