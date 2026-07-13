import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../domain/entities/vulnerability.dart';
import '../../../../shared/widgets/severity_badge.dart';

class VulnCard extends StatelessWidget {
  const VulnCard({
    super.key,
    required this.vulnerability,
    required this.onTap,
    this.index = 0,
  });

  final Vulnerability vulnerability;
  final VoidCallback onTap;
  final int index;

  Color get _severityColor => switch (vulnerability.severity) {
        VulnSeverity.critical => AppColors.criticalFg,
        VulnSeverity.high => AppColors.highFg,
        VulnSeverity.medium => AppColors.mediumFg,
        VulnSeverity.low => AppColors.lowFg,
        VulnSeverity.info => AppColors.infoFg,
      };

  @override
  Widget build(BuildContext context) {
    final v = vulnerability;
    final isCritical = v.severity == VulnSeverity.critical;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCritical 
                  ? AppColors.criticalFg.withValues(alpha: 0.4) 
                  : (isDark ? AppColors.border : AppColors.lightBorder),
              width: isCritical ? 1.5 : 1,
            ),
            boxShadow: isDark 
              ? (isCritical ? [BoxShadow(color: AppColors.criticalFg.withValues(alpha: 0.1), blurRadius: 15)] : null)
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (isCritical)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(color: AppColors.criticalFg),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (v.cveId != null)
                                  Text(
                                    v.cveId!.toUpperCase(),
                                    style: TextStyle(
                                      color: isDark ? AppColors.textCode : AppColors.deepBlue,
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                const Gap(4),
                                Text(
                                  v.title,
                                  style: TextStyle(
                                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(12),
                          SeverityBadge(v.severity.label),
                        ],
                      ),
                      const Gap(12),
                      Text(
                        v.description,
                        maxLines: 2,
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
                          StatusBadge(v.status.label),
                          const Gap(8),
                          if (v.assignedTo != null)
                            Flexible(
                              child: _MetaItem(
                                icon: Icons.person_3_outlined,
                                label: v.assignedTo!,
                              ),
                            ),
                          const Spacer(),
                          Flexible(
                            child: _MetaItem(
                              icon: Icons.terminal_outlined,
                              label: v.projectName,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Stack(
                        children: [
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.bg800 : AppColors.lightScaffold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: v.remediationProgress,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: _severityColor,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _severityColor.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TYPE: ${v.type.label.toUpperCase()}',
                            style: TextStyle(
                              color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _timeAgo(v.updatedAt).toUpperCase(),
                            style: TextStyle(
                              color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.textTertiary : AppColors.lightTextTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const Gap(4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class VulnStatsRow extends ConsumerWidget {
  const VulnStatsRow({
    super.key,
    required this.total,
    required this.critical,
    required this.open,
    required this.remediated,
  });

  final int total;
  final int critical;
  final int open;
  final int remediated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatCard(label: s.total, value: '$total', color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
          const Gap(8),
          _StatCard(label: s.critical, value: '$critical', color: AppColors.criticalFg, isAlert: critical > 0),
          const Gap(8),
          _StatCard(label: s.open, value: '$open', color: AppColors.highFg),
          const Gap(8),
          _StatCard(label: s.fixed, value: '$remediated', color: AppColors.lowFg),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg800 : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAlert 
                ? AppColors.criticalFg.withValues(alpha: 0.5) 
                : (isDark ? AppColors.border : AppColors.lightBorder),
            width: isAlert ? 1.5 : 1,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
            const Gap(2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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
