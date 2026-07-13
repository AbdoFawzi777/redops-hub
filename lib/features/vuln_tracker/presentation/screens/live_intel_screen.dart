import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../../../shared/widgets/tactical_loader.dart';
import '../providers/vuln_providers.dart';
import '../../data/models/cve_model.dart';

class LiveIntelScreen extends ConsumerWidget {
  const LiveIntelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvesAsync = ref.watch(latestCvesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const RedOpsHeader(
              title: 'LIVE CVE FEED',
              subtitle: 'Global vulnerability intelligence stream',
              showBackButton: true,
            ),
            Expanded(
              child: cvesAsync.when(
                data: (cves) => ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cves.length,
                  separatorBuilder: (_, __) => const Gap(16),
                  itemBuilder: (context, index) => _CveCard(cve: cves[index], index: index),
                ),
                loading: () => const TacticalLoader(size: 100),
                error: (e, _) => Center(
                  child: Text(
                    'UPLINK FAILED: $e',
                    style: const TextStyle(color: AppColors.criticalFg, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CveCard extends StatelessWidget {
  const _CveCard({required this.cve, required this.index});
  final CveModel cve;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor(cve.severity);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cve.id,
                  style: TextStyle(
                    color: isDark ? AppColors.textCode : AppColors.deepBlue,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _SeverityBadge(label: cve.severity, color: severityColor),
              ],
            ),
            const Gap(12),
            Text(
              cve.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const Gap(16),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textTertiary),
                const Gap(6),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(cve.publishedDate),
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
                const Spacer(),
                if (cve.score != null)
                  Text(
                    'SCORE: ${cve.score}',
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL': return AppColors.criticalFg;
      case 'HIGH': return AppColors.highFg;
      case 'MEDIUM': return AppColors.mediumFg;
      case 'LOW': return AppColors.lowFg;
      default: return AppColors.textTertiary;
    }
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
