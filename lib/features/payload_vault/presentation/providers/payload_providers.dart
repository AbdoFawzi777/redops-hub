import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/payload_local_datasource.dart';
import '../../domain/entities/payload.dart';

final payloadDataSourceProvider = Provider<PayloadLocalDataSource>((ref) {
  return PayloadLocalDataSource();
});

final payloadListProvider = FutureProvider<List<Payload>>((ref) async {
  return ref.watch(payloadDataSourceProvider).getPayloads();
});

final payloadSearchQueryProvider = StateProvider<String>((ref) => '');
final payloadCategoryProvider = StateProvider<String>((ref) => 'ALL');

final filteredPayloadsProvider = Provider<AsyncValue<List<Payload>>>((ref) {
  final listAsync = ref.watch(payloadListProvider);
  final query = ref.watch(payloadSearchQueryProvider).toLowerCase();
  final selectedCat = ref.watch(payloadCategoryProvider);

  return listAsync.whenData((payloads) {
    return payloads.where((p) {
      final matchesCat = selectedCat == 'ALL' || p.category == selectedCat || p.source == selectedCat;
      final matchesSearch = p.title.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.code.toLowerCase().contains(query);
      return matchesCat && matchesSearch;
    }).toList();
  });
});
