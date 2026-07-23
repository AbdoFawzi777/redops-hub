import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/vulnerability.dart';

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
        VulnSeverity.critical => AppColors.v3Critical, // #FF3B3B
        VulnSeverity.high => AppColors.v3Warning,   // #FF9F00
        VulnSeverity.medium => AppColors.v3Intel,   // #00D4FF
        VulnSeverity.low => AppColors.v3Live,       // #00FF85
        VulnSeverity.info => AppColors.v3Intel,     // #00D4FF
      };

  @override
  Widget build(BuildContext context) {
    final v = vulnerability;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.dynamicCardBorder(context),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Left 2px severity border line
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 2,
                child: Container(color: _severityColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                                  '● ${v.cveId!.toUpperCase()}',
                                  style: TextStyle(
                                    color: _severityColor,
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              const Gap(4),
                              Text(
                                v.title,
                                style: TextStyle(
                                  color: AppColors.dynamicTextPrimary(context),
                                  fontSize: 14.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _severityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _severityColor.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Text(
                            v.severity.label.toUpperCase(),
                            style: TextStyle(
                              color: _severityColor,
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      v.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.dynamicTextSecondary(context),
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        height: 1.35,
                      ),
                    ),
                    const Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TARGET: ${v.projectName.toUpperCase()}',
                          style: TextStyle(
                            color: AppColors.dynamicTextMuted(context),
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          _timeAgo(v.updatedAt).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.dynamicTextMuted(context),
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    // Bottom Remediation Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 3,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.dynamicOuterBg(context),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: v.remediationProgress.clamp(0.05, 1.0),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: _severityColor,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
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
    )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'TOTAL',
              value: '$total',
              color: AppColors.dynamicTextPrimary(context),
            ),
          ),
          const Gap(12),
          Expanded(
            child: _StatBox(
              label: 'CRITICAL',
              value: '$critical',
              color: AppColors.v3Critical,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.dynamicTextMuted(context),
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
