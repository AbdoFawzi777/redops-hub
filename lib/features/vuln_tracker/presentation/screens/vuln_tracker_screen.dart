import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../../../shared/widgets/tactical_loader.dart';
import '../../domain/entities/vulnerability.dart';
import '../providers/vuln_providers.dart';
import '../widgets/vuln_card.dart';

class VulnTrackerScreen extends ConsumerStatefulWidget {
  const VulnTrackerScreen({super.key});

  @override
  ConsumerState<VulnTrackerScreen> createState() => _VulnTrackerScreenState();
}

class _VulnTrackerScreenState extends ConsumerState<VulnTrackerScreen> {
  bool _isManualRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredVulnsProvider);
    final statsAsync = ref.watch(vulnStatsProvider);
    final filter = ref.watch(vulnFilterProvider);
    final s = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.vulnCreate),
        backgroundColor: AppColors.redPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          s.newFinding,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RedOpsHeader(
              title: s.vulnsTitle,
              subtitle: s.vulnsSubtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.public_rounded, color: AppColors.textTertiary),
                    onPressed: () => context.push(AppRoutes.hackerNews),
                    tooltip: 'Hacker Intelligence',
                  ),
                  IconButton(
                    icon: const Icon(Icons.rss_feed_rounded, color: AppColors.redPrimary),
                    onPressed: () => context.push(AppRoutes.liveIntel),
                    tooltip: 'Live CVE Feed',
                  ),
                ],
              ),
            ),
            statsAsync.when(
              data: (stats) => VulnStatsRow(
                total: stats.total,
                critical: stats.critical,
                open: stats.open,
                remediated: stats.remediated,
              ),
              loading: () => const SizedBox(height: 72),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Gap(16),
            _SearchBar(
              query: filter.query,
              onChanged: (q) => ref.read(vulnFilterProvider.notifier).state =
                  filter.copyWith(query: q),
            ),
            const Gap(12),
            _FilterChips(filter: filter),
            const Gap(8),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bg800 : AppColors.lightSurface,
                    color: AppColors.redPrimary,
                    onRefresh: () async {
                      setState(() => _isManualRefreshing = true);
                      ref.invalidate(vulnsStreamProvider);
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) setState(() => _isManualRefreshing = false);
                    },
                    child: filteredAsync.when(
                      data: (vulns) {
                        if (vulns.isEmpty) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400,
                              child: _EmptyState(
                                onCreate: () => context.push(AppRoutes.vulnCreate),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: vulns.length,
                          separatorBuilder: (_, __) => const Gap(16),
                          itemBuilder: (context, index) {
                            final vuln = vulns[index];
                            return VulnCard(
                              vulnerability: vuln,
                              index: index,
                              onTap: () => context.push(
                                AppRoutes.vulnDetailPath(vuln.id),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: TacticalLoader(size: 100)),
                      error: (e, _) => Center(
                        child: Text(
                          'FAILED TO LOAD INTEL: $e',
                          style: const TextStyle(color: AppColors.criticalFg, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  
                  // Show tactical loader overlay ONLY during manual pull-to-refresh
                  if (_isManualRefreshing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(child: TacticalLoader(size: 120)),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, 
          fontSize: 14, 
          fontFamily: 'monospace'
        ),
        decoration: InputDecoration(
          hintText: s.searchHint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, 
            fontSize: 13, 
            letterSpacing: 1
          ),
          prefixIcon: Icon(
            Icons.search, 
            color: isDark ? AppColors.redPrimary : AppColors.deepBlue, 
            size: 20
          ),
          filled: true,
          fillColor: isDark ? AppColors.bg800 : AppColors.lightSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? AppColors.border : AppColors.lightBorder, 
              width: 1
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? AppColors.redPrimary : AppColors.deepBlue, 
              width: 2
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0);
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.filter});

  final VulnFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'ALL',
            selected: filter.severity == null && filter.status == null,
            onTap: () => ref.read(vulnFilterProvider.notifier).state =
                filter.copyWith(clearSeverity: true, clearStatus: true),
          ),
          const Gap(10),
          ...VulnSeverity.values.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _FilterChip(
                label: s.label.toUpperCase(),
                selected: filter.severity == s,
                color: _severityColor(s),
                onTap: () {
                  ref.read(vulnFilterProvider.notifier).state = filter.copyWith(
                        severity: filter.severity == s ? null : s,
                        clearSeverity: filter.severity == s,
                      );
                },
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Color _severityColor(VulnSeverity s) => switch (s) {
        VulnSeverity.critical => AppColors.criticalFg,
        VulnSeverity.high => AppColors.highFg,
        VulnSeverity.medium => AppColors.mediumFg,
        VulnSeverity.low => AppColors.lowFg,
        VulnSeverity.info => AppColors.infoFg,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? (isDark ? AppColors.redPrimary : AppColors.deepBlue);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected 
              ? activeColor.withValues(alpha: 0.15) 
              : (isDark ? AppColors.cardBg : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? activeColor : (isDark ? AppColors.border : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(color: activeColor.withValues(alpha: 0.1), blurRadius: 8)
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected 
                ? activeColor 
                : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_update_warning_outlined,
            size: 80,
            color: primaryColor.withValues(alpha: 0.3),
          ).animate(onPlay: (c) => c.repeat()).shake(hz: 2, duration: 2.seconds),
          const Gap(24),
          Text(
            'NO VULNERABILITIES DETECTED',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Gap(12),
          Text(
            'Initial scanning complete. No active findings in this scope.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, 
              fontSize: 13
            ),
          ),
          const Gap(32),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_moderator),
            label: const Text('MANUAL ENTRY'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor),
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
