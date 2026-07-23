import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/tactical_loader.dart';
import '../../../../shared/widgets/responsive_text.dart';
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
      backgroundColor: AppColors.dynamicBg(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.vulnCreate),
        backgroundColor: AppColors.v3OpsRed, // #E02E2E
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(),
            const Gap(12),
            _buildTitleSection(s),
            const Gap(14),
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
            const Gap(14),
            _SearchBar(
              query: filter.query,
              hint: s.searchHint,
              onChanged: (q) => ref.read(vulnFilterProvider.notifier).state =
                  filter.copyWith(query: q),
            ),
            const Gap(10),
            _FilterChips(filter: filter),
            const Gap(8),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    backgroundColor: AppColors.dynamicCardBg(context),
                    color: AppColors.v3Critical,
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
                              height: 350,
                              child: _EmptyState(
                                onCreate: () => context.push(AppRoutes.vulnCreate),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: vulns.length,
                          separatorBuilder: (_, __) => const Gap(12),
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
                          style: const TextStyle(
                            color: AppColors.v3Critical,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isManualRefreshing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
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

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.v3Critical.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.v3Critical.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.v3Critical,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
                const Gap(6),
                const Text(
                  'THREATS',
                  style: TextStyle(
                    color: AppColors.v3Critical,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.public_rounded, color: AppColors.dynamicTextMuted(context), size: 20),
                onPressed: () => context.push(AppRoutes.hackerNews),
                tooltip: 'Hacker Intelligence',
              ),
              IconButton(
                icon: const Icon(Icons.rss_feed_rounded, color: AppColors.v3Critical, size: 20),
                onPressed: () => context.push(AppRoutes.liveIntel),
                tooltip: 'Live CVE Feed',
              ),
              const Gap(4),
              const Text(
                '5 OPEN',
                style: TextStyle(
                  color: AppColors.v3Warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildTitleSection(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TacticalTitle(
            s.vulnsTitle,
            isHeading: true,
            color: AppColors.dynamicTextPrimary(context),
          ),
          const Gap(2),
          Text(
            s.vulnsSubtitle,
            style: TextStyle(
              color: AppColors.dynamicTextMuted(context),
              fontSize: 11.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.query, required this.hint, required this.onChanged});

  final String query;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(
          color: AppColors.dynamicTextPrimary(context),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.dynamicTextMuted(context),
            fontSize: 11.5,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.dynamicTextMuted(context),
            size: 18,
          ),
          filled: true,
          fillColor: AppColors.dynamicCardBg(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.dynamicCardBorder(context), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.v3Critical, width: 1.5),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 250.ms);
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.filter});

  final VulnFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'ALL',
            selected: filter.severity == null && filter.status == null,
            onTap: () => ref.read(vulnFilterProvider.notifier).state =
                filter.copyWith(clearSeverity: true, clearStatus: true),
          ),
          const Gap(8),
          ...VulnSeverity.values.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
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
    ).animate().fadeIn(delay: 350.ms);
  }

  Color _severityColor(VulnSeverity s) => switch (s) {
        VulnSeverity.critical => AppColors.v3Critical,
        VulnSeverity.high => AppColors.v3Warning,
        VulnSeverity.medium => AppColors.v3Intel,
        VulnSeverity.low => AppColors.v3Live,
        VulnSeverity.info => AppColors.v3Intel,
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
    final activeColor = color ?? AppColors.v3Critical;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.15) : AppColors.dynamicCardBg(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? activeColor : AppColors.dynamicCardBorder(context),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : AppColors.dynamicTextMuted(context),
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_update_warning_outlined,
            size: 64,
            color: AppColors.v3Critical.withValues(alpha: 0.4),
          ).animate(onPlay: (c) => c.repeat()).shake(hz: 2, duration: 2.seconds),
          const Gap(16),
          Text(
            'NO VULNERABILITIES DETECTED',
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
          const Gap(8),
          Text(
            'No active findings matching current scope.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.dynamicTextMuted(context),
              fontSize: 11.5,
              fontFamily: 'monospace',
            ),
          ),
          const Gap(24),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'MANUAL ENTRY',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.v3Critical),
              foregroundColor: AppColors.v3Critical,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}
