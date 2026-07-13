import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/redops_header.dart';

class C2DashboardScreen extends ConsumerWidget {
  const C2DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.bg900, AppColors.cardBg]
                : [AppColors.lightScaffold, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RedOpsHeader(
                  title: s.c2Title,
                  subtitle: s.c2Subtitle,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildMissionCard(context),
                      const Gap(16),
                      _buildStatusCard(
                        context,
                        title: 'ACTIVE SESSIONS',
                        value: '03',
                        status: '3 AGENTS LIVE',
                        statusColor: AppColors.live,
                        details: 'WIN-DC01 · 192.168.1.5',
                        progress: 0.7,
                      ),
                      const Gap(16),
                      _buildStatusCard(
                        context,
                        title: 'LAST BEACON',
                        value: '2m',
                        status: 'DESKTOP-K9F',
                        statusColor: AppColors.highFg,
                        details: 'SYSTEM PRIVILEGES ACQUIRED',
                      ),
                      const Gap(16),
                      _buildTerminalCard(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
              const Gap(8),
              Text(
                'MISSION READINESS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Gap(12),
          const Text(
            '88% READY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const Gap(8),
          Text(
            'Threat perimeter stable · no critical anomalies detected',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallBadge('AUTO-HEAL', Colors.white.withValues(alpha: 0.9)),
              _buildSmallBadge('ENCRYPTED', Colors.white.withValues(alpha: 0.9)),
              _buildSmallBadge('SYNCED', Colors.white.withValues(alpha: 0.9)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required String details,
    double? progress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBg.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.border : AppColors.lightBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1),
              ),
              _buildSmallBadge(status, statusColor),
            ],
          ),
          const Gap(12),
          Text(
            value,
            style: TextStyle(
                color: primaryColor,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace'),
          ),
          const Gap(8),
          Text(
            details,
            style: TextStyle(
                color: isDark
                    ? AppColors.textTertiary
                    : AppColors.lightTextTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          if (progress != null) ...[
            const Gap(16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  isDark ? AppColors.bg800 : AppColors.lightScaffold,
              color: primaryColor,
              minHeight: 2,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTerminalCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.9)
            : AppColors.lightTextPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK CONSOLE',
            style: TextStyle(
                color: isDark ? AppColors.textTertiary : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1),
          ),
          const Gap(16),
          _buildTerminalLine('> whoami /all', AppColors.live),
          const Gap(8),
          _buildTerminalLine('> net localgroup administrators', AppColors.live),
          const Gap(8),
          _buildTerminalLine('> [!] Access Denied - UAC Bypass Required',
              AppColors.redPrimary),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms)
        .shimmer(delay: 2.seconds, duration: 2.seconds, color: Colors.white10);
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildTerminalLine(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
