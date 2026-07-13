import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../../../shared/widgets/tactical_loader.dart';
import '../providers/vuln_providers.dart';

class VulnDetailScreen extends ConsumerWidget {
  const VulnDetailScreen({super.key, required this.vulnId});

  final String vulnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vulnAsync = ref.watch(vulnDetailProvider(vulnId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedOpsHeader(
              title: 'Finding Detail',
              subtitle: 'ID: $vulnId',
              showBackButton: true,
            ),
            Expanded(
              child: vulnAsync.when(
                data: (vuln) {
                  if (vuln == null) {
                    return const Center(
                      child: Text('Finding not found',
                          style: TextStyle(color: AppColors.criticalFg)),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        vuln.title,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        vuln.description,
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const TacticalLoader(size: 100),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.criticalFg)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
