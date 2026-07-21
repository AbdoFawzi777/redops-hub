import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../../../shared/widgets/tactical_loader.dart';
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
    'WINDOWS',
    'LINUX',
    'WEB',
    'LOLBAS',
    'GTFOBins'
  ];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredAsync = ref.watch(filteredPayloadsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedOpsHeader(
              title: s.vaultTitle,
              subtitle: 'Tactical bypass and exploit payload repository',
            ),
            _buildSearch(isDark, s),
            const Gap(6),
            _buildCategories(isDark),
            const Gap(10),
            Expanded(
              child: filteredAsync.when(
                data: (payloads) => _buildList(payloads, s),
                loading: () => const Center(child: TacticalLoader(size: 100)),
                error: (err, _) => Center(
                  child: Text(
                    'FAILED TO SYNC PAYLOADS: $err',
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

  Widget _buildSearch(bool isDark, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        onChanged: (v) => ref.read(payloadSearchQueryProvider.notifier).state = v,
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, 
          fontSize: 14, 
          fontFamily: 'monospace'
        ),
        decoration: InputDecoration(
          hintText: 'Search LOLBAS, GTFOBins, Web shells...',
          prefixIcon: Icon(
            Icons.search, 
            color: isDark ? AppColors.redPrimary : AppColors.deepBlue, 
            size: 20
          ),
          filled: true,
          fillColor: isDark ? AppColors.bg800 : AppColors.lightSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppColors.redPrimary : AppColors.deepBlue, width: 2),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCategories(bool isDark) {
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;
    final selectedCategory = ref.watch(payloadCategoryProvider);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == selectedCategory;
          return GestureDetector(
            onTap: () => ref.read(payloadCategoryProvider.notifier).state = cat,
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.15) : (isDark ? AppColors.bg800 : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? primaryColor : (isDark ? AppColors.border : AppColors.lightBorder),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? primaryColor : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildList(List<Payload> payloads, AppStrings s) {
    if (payloads.isEmpty) {
      return Center(
        child: Text(s.noDataFound, style: const TextStyle(color: AppColors.textTertiary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: payloads.length,
      separatorBuilder: (_, __) => const Gap(16),
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
  bool _isExpanded = false;
  bool _isCopied = false;

  void _copyToClipboard(AppStrings s) {
    Clipboard.setData(ClipboardData(text: widget.payload.code));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('COPIED: ${widget.payload.title.toUpperCase()}'),
        backgroundColor: AppColors.redPrimary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon() {
    if (widget.payload.source == 'LOLBAS') return Icons.desktop_windows_rounded;
    if (widget.payload.source == 'GTFOBins') return Icons.terminal_rounded;
    switch (widget.payload.category.toUpperCase()) {
      case 'WINDOWS': return Icons.desktop_windows_rounded;
      case 'LINUX': return Icons.terminal_rounded;
      case 'WEB': return Icons.language_rounded;
      default: return Icons.code_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder, width: 1),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bg800 : AppColors.lightScaffold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getCategoryIcon(), color: primaryColor, size: 20),
            ),
            title: Text(
              widget.payload.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, 
                fontWeight: FontWeight.bold, 
                fontSize: 14
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  widget.payload.category,
                  style: TextStyle(
                    color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, 
                    fontSize: 10, 
                    fontWeight: FontWeight.w900
                  ),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.payload.source.toUpperCase(),
                    style: TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.border),
                  const Gap(8),
                  Text(
                    widget.payload.description,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, 
                      fontSize: 13
                    ),
                  ),
                  const Gap(16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : AppColors.lightTextPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      widget.payload.code,
                      style: const TextStyle(
                        color: AppColors.textCode,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(s),
                      icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 16),
                      label: Text(_isCopied ? 'COPIED' : 'COPY PAYLOAD'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isCopied ? AppColors.live : primaryColor,
                        side: BorderSide(color: _isCopied ? AppColors.live : primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate(delay: (widget.index * 50).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}
