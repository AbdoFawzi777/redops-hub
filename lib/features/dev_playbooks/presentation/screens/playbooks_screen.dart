import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/dev_playbooks_service.dart';
import '../../../../shared/widgets/responsive_text.dart';
import '../../../../shared/widgets/tactical_loader.dart';

final livePlaybooksProvider = FutureProvider<List<DevPlaybookItem>>((ref) async {
  return DevPlaybooksService.getLivePlaybooks();
});

class PlaybooksScreen extends ConsumerStatefulWidget {
  const PlaybooksScreen({super.key});

  @override
  ConsumerState<PlaybooksScreen> createState() => _PlaybooksScreenState();
}

class _PlaybooksScreenState extends ConsumerState<PlaybooksScreen> {
  String _selectedCategory = 'ALL';
  final _categories = ['ALL', 'AD', 'WEB', 'PIVOT'];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final playbooksAsync = ref.watch(livePlaybooksProvider);

    return Scaffold(
      backgroundColor: AppColors.dynamicBg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(),
            const Gap(12),
            _buildTitleSection(s),
            const Gap(14),
            _buildCategories(),
            const Gap(12),
            Expanded(
              child: playbooksAsync.when(
                data: (playbooks) {
                  final filtered = _selectedCategory == 'ALL'
                      ? playbooks
                      : playbooks.where((p) => p.category == _selectedCategory).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'NO PLAYBOOKS MATCHED',
                        style: TextStyle(
                            color: AppColors.dynamicTextMuted(context),
                            fontFamily: 'monospace',
                            fontSize: 13),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemBuilder: (context, index) =>
                        _V3PlaybookCard(playbook: filtered[index], index: index),
                  );
                },
                loading: () => const Center(child: TacticalLoader(size: 100)),
                error: (e, _) => Center(
                  child: Text(
                    'FAILED TO SYNC PLAYBOOKS: $e',
                    style: const TextStyle(
                        color: AppColors.v3Critical, fontFamily: 'monospace'),
                  ),
                ),
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
              color: AppColors.v3Intel.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.v3Intel.withValues(alpha: 0.3),
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
                    color: AppColors.v3Intel,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
                const Gap(6),
                const Text(
                  'LIVE DEV PLAYBOOKS - API STREAM',
                  style: TextStyle(
                    color: AppColors.v3Intel,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'LIVE STREAM',
            style: TextStyle(
              color: AppColors.v3Live,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
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
            s.playbooksTitle,
            isHeading: true,
            color: AppColors.dynamicTextPrimary(context),
          ),
          const Gap(2),
          Text(
            s.playbooksSubtitle,
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

  Widget _buildCategories() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.v3Intel.withValues(alpha: 0.15)
                    : AppColors.dynamicCardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.v3Intel
                      : AppColors.dynamicCardBorder(context),
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.v3Intel
                      : AppColors.dynamicTextMuted(context),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 250.ms);
  }
}

class _V3PlaybookCard extends StatelessWidget {
  const _V3PlaybookCard({required this.playbook, required this.index});
  final DevPlaybookItem playbook;
  final int index;

  void _copyCommand(BuildContext context) {
    Clipboard.setData(ClipboardData(text: playbook.command));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'COMMAND COPIED: ${playbook.command}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
        backgroundColor: AppColors.v3Live,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.v3Critical.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: AppColors.v3Critical.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              playbook.phase,
              style: const TextStyle(
                color: AppColors.v3Critical,
                fontSize: 9.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Gap(10),
          Text(
            playbook.title,
            style: TextStyle(
              color: AppColors.dynamicTextPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const Gap(10),
          ...playbook.steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '› ',
                    style: TextStyle(
                      color: AppColors.v3Code,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: AppColors.dynamicTextSecondary(context),
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),
          GestureDetector(
            onTap: () => _copyCommand(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dynamicConsoleBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.dynamicCardBorder(context), width: 1),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  playbook.command,
                  style: const TextStyle(
                    color: AppColors.v3Live,
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}
