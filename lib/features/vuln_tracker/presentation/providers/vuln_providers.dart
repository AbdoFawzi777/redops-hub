import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/vuln_local_datasource.dart';
import '../../data/repositories/vuln_repository_impl.dart';
import '../../domain/entities/vulnerability.dart';
import '../../domain/repositories/vuln_repository.dart';
import '../../domain/usecases/create_vuln_usecase.dart';
import '../../domain/usecases/get_vulns_usecase.dart';
import '../../domain/usecases/update_vuln_usecase.dart';

import '../../data/datasources/cve_remote_datasource.dart';
import '../../data/models/cve_model.dart';

final cveRemoteDataSourceProvider = Provider<CveRemoteDataSource>((ref) {
  return CveRemoteDataSource();
});

final latestCvesProvider = FutureProvider<List<CveModel>>((ref) async {
  return ref.watch(cveRemoteDataSourceProvider).getLatestCves();
});

final vulnLocalDataSourceProvider = Provider<VulnLocalDataSource>((ref) {
  throw UnimplementedError('VulnLocalDataSource not initialized');
});

final vulnRepositoryProvider = Provider<VulnRepository>((ref) {
  return VulnRepositoryImpl(ref.watch(vulnLocalDataSourceProvider));
});

final getVulnsUseCaseProvider = Provider((ref) {
  return GetVulnsUseCase(ref.watch(vulnRepositoryProvider));
});

final createVulnUseCaseProvider = Provider((ref) {
  return CreateVulnUseCase(ref.watch(vulnRepositoryProvider));
});

final updateVulnUseCaseProvider = Provider((ref) {
  return UpdateVulnUseCase(ref.watch(vulnRepositoryProvider));
});

final vulnsStreamProvider = StreamProvider<List<Vulnerability>>((ref) {
  return ref.watch(getVulnsUseCaseProvider).watch();
});

final vulnDetailProvider =
    FutureProvider.family<Vulnerability?, String>((ref, id) async {
  return ref.watch(vulnRepositoryProvider).getById(id);
});

class VulnFilter {
  const VulnFilter({
    this.severity,
    this.status,
    this.query = '',
  });

  final VulnSeverity? severity;
  final VulnStatus? status;
  final String query;

  VulnFilter copyWith({
    VulnSeverity? severity,
    VulnStatus? status,
    String? query,
    bool clearSeverity = false,
    bool clearStatus = false,
  }) {
    return VulnFilter(
      severity: clearSeverity ? null : (severity ?? this.severity),
      status: clearStatus ? null : (status ?? this.status),
      query: query ?? this.query,
    );
  }
}

final vulnFilterProvider = StateProvider<VulnFilter>((ref) {
  return const VulnFilter();
});

final filteredVulnsProvider = Provider<AsyncValue<List<Vulnerability>>>((ref) {
  final vulnsAsync = ref.watch(vulnsStreamProvider);
  final filter = ref.watch(vulnFilterProvider);

  return vulnsAsync.whenData((vulns) {
    return vulns.where((v) {
      final matchSeverity =
          filter.severity == null || v.severity == filter.severity;
      final matchStatus = filter.status == null || v.status == filter.status;
      final q = filter.query.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          v.title.toLowerCase().contains(q) ||
          v.description.toLowerCase().contains(q) ||
          (v.cveId?.toLowerCase().contains(q) ?? false) ||
          v.tags.any((t) => t.toLowerCase().contains(q));
      return matchSeverity && matchStatus && matchQuery;
    }).toList();
  });
});

final vulnStatsProvider = Provider<AsyncValue<VulnStats>>((ref) {
  return ref.watch(vulnsStreamProvider).whenData((vulns) {
    return VulnStats(
      total: vulns.length,
      critical: vulns.where((v) => v.severity == VulnSeverity.critical).length,
      open: vulns.where((v) => v.isOpen).length,
      remediated:
          vulns.where((v) => v.status == VulnStatus.remediated).length,
    );
  });
});

class VulnStats {
  const VulnStats({
    required this.total,
    required this.critical,
    required this.open,
    required this.remediated,
  });

  final int total;
  final int critical;
  final int open;
  final int remediated;
}
