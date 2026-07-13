import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/vuln_tracker/data/datasources/vuln_local_datasource.dart';
import '../../features/vuln_tracker/presentation/providers/vuln_providers.dart';

Future<void> bootstrapApp(ProviderContainer container) async {
  await Hive.initFlutter();

  final vulnLocal = await VulnLocalDataSource.open();
  await vulnLocal.seedIfEmpty();

  container.updateOverrides([
    vulnLocalDataSourceProvider.overrideWithValue(vulnLocal),
  ]);
}
