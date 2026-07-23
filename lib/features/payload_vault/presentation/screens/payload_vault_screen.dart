import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/tactical_loader.dart';
import '../../../../shared/widgets/responsive_text.dart';
import '../../domain/entities/payload.dart';
import '../providers/payload_providers.dart';

class PayloadVaultScreen extends ConsumerStatefulWidget {
  const PayloadVaultScreen({super.key});

  @override
  ConsumerState<PayloadVaultScreen> createState() => _PayloadVaultScreenState();
}

class _PayloadVaultScreenState extends ConsumerState<PayloadVaultScreen> {
  final List<String> _categories = [
    'ALL',
    'WIN',
    'LINUX',
    'WEB',
    'LOLBAS',
    'GTFOBins'
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredPayloadsProvider);
    final s = ref.watch(l10nProvider);

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
            _buildSearch(s),
            const Gap(10),
            _buildCategories(),
            const Gap(10),
            Expanded(
              child: filteredAsync.when(
                data: (payloads) => _buildList(payloads),
                loading: () => const Center(child: TacticalLoader(size: 100)),
                error: (err, _) => Center(
                  child: Text(
                    'FAILED TO SYNC PAYLOADS: $err',
                    style: const TextStyle(
                      color: AppColors.v3Critical,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
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
              color: AppColors.v3Code.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.v3Code.withValues(alpha: 0.3),
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
                    color: AppColors.v3Code,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
                const Gap(6),
                const Text(
                  'PAYLOAD VAULT - OFFLINE',
                  style: TextStyle(
                    color: AppColors.v3Code,
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
            'AES-256',
            style: TextStyle(
              color: AppColors.v3Intel,
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
            s.vaultTitle,
            isHeading: true,
            color: AppColors.dynamicTextPrimary(context),
          ),
          const Gap(2),
          Text(
            s.vaultSubtitle,
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

  Widget _buildSearch(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (v) => ref.read(payloadSearchQueryProvider.notifier).state = v,
        style: TextStyle(
          color: AppColors.dynamicTextPrimary(context),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: s.searchVault,
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
            borderSide: const BorderSide(color: AppColors.v3Code, width: 1.5),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildCategories() {
    final selectedCategory = ref.watch(payloadCategoryProvider);

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == selectedCategory || (cat == 'WIN' && selectedCategory == 'WINDOWS');
          return GestureDetector(
            onTap: () => ref.read(payloadCategoryProvider.notifier).state = (cat == 'WIN' ? 'WINDOWS' : cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.v3Code.withValues(alpha: 0.15) : AppColors.dynamicCardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.v3Code : AppColors.dynamicCardBorder(context),
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? AppColors.v3Code : AppColors.dynamicTextMuted(context),
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
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildList(List<Payload> payloads) {
    if (payloads.isEmpty) {
      return Center(
        child: Text(
          'NO PAYLOADS MATCHED',
          style: TextStyle(color: AppColors.dynamicTextMuted(context), fontFamily: 'monospace', fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: payloads.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (context, index) => _PayloadCard(payload: payloads[index], index: index),
    );
  }
}

class _PayloadCard extends ConsumerStatefulWidget {
  const _PayloadCard({required this.payload, required this.index});
  final Payload payload;
  final int index;

  @override
  ConsumerState<_PayloadCard> createState() => _PayloadCardState();
}

class _PayloadCardState extends ConsumerState<_PayloadCard> {
  bool _isCopied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.payload.code));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'COPIED TO CLIPBOARD: ${widget.payload.title.toUpperCase()}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
        backgroundColor: AppColors.v3Live,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon() {
    if (widget.payload.source == 'LOLBAS') return Icons.desktop_windows_rounded;
    if (widget.payload.source == 'GTFOBins') return Icons.terminal_rounded;
    switch (widget.payload.category.toUpperCase()) {
      case 'WINDOWS':
      case 'WIN':
        return Icons.desktop_windows_rounded;
      case 'LINUX':
        return Icons.terminal_rounded;
      case 'WEB':
        return Icons.language_rounded;
      default:
        return Icons.code_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Square Icon Container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicOuterBg(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.dynamicCardBorder(context), width: 1),
                  ),
                  child: Icon(_getCategoryIcon(), color: AppColors.v3Intel, size: 18),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payload.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          Text(
                            widget.payload.category.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.dynamicTextMuted(context),
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.v3Intel.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.payload.source.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.v3Intel,
                                fontSize: 8.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
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
            const Gap(12),
            // Code Box (Terminal Console Dark)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dynamicConsoleBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.dynamicCardBorder(context)),
              ),
              child: Text(
                widget.payload.code,
                style: const TextStyle(
                  color: AppColors.v3Code, // Turquoise #00FFD1
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ),
            const Gap(12),
            // Green Outlined Copy Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 14),
                label: Text(
                  _isCopied ? 'COPIED' : 'COPY PAYLOAD',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.v3Live,
                  side: const BorderSide(color: AppColors.v3Live, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (widget.index * 50).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}
