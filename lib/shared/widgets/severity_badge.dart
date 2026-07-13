import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SeverityBadge extends StatelessWidget {
  const SeverityBadge(this.severity, {super.key});
  final String severity;

  static const _config = {
    'Critical': (AppColors.criticalFg, AppColors.criticalBg),
    'High':     (AppColors.highFg,     AppColors.highBg),
    'Medium':   (AppColors.mediumFg,   AppColors.mediumBg),
    'Low':      (AppColors.lowFg,      AppColors.lowBg),
    'Info':     (AppColors.infoFg,     AppColors.infoBg),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _config[severity];
    final fg = colors?.$1 ?? AppColors.textSecondary;
    final bg = colors?.$2 ?? AppColors.bg700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  static const _config = {
    'Open':          (AppColors.criticalFg, AppColors.criticalBg),
    'In Review':     (AppColors.highFg,     AppColors.highBg),
    'Remediated':    (AppColors.lowFg,      AppColors.lowBg),
    'Accepted':      (AppColors.infoFg,     AppColors.infoBg),
    'False Positive':(AppColors.textTertiary, AppColors.bg700),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _config[status];
    final fg = colors?.$1 ?? AppColors.textSecondary;
    final bg = colors?.$2 ?? AppColors.bg700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}