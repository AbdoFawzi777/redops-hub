import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redops_header.dart';

class HackerIntelScreen extends ConsumerWidget {
  const HackerIntelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const RedOpsHeader(
              title: 'HACKER INTELLIGENCE',
              subtitle: 'Global hacking news & HackerOne feeds',
              showBackButton: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSection(context, 'HACKERONE ACTIVITY', [
                    _buildIntelCard(
                      'RCE found in major Cloud Provider',
                      'HackerOne · \$15,000 Bounty',
                      'CRITICAL',
                      AppColors.criticalFg,
                    ),
                    _buildIntelCard(
                      'IDOR in Payment Gateway',
                      'HackerOne · \$5,000 Bounty',
                      'HIGH',
                      AppColors.highFg,
                    ),
                  ]),
                  const Gap(24),
                  _buildSection(context, 'GLOBAL CYBER NEWS', [
                    _buildNewsTile(
                      'New APT group targeting energy sector',
                      'The Hacker News · 2h ago',
                    ),
                    _buildNewsTile(
                      'Zero-day exploit released for popular VPN',
                      'BleepingComputer · 5h ago',
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const Gap(12),
        ...children,
      ],
    );
  }

  Widget _buildIntelCard(String title, String subtitle, String tag, Color tagColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.arrow_outward, size: 14, color: AppColors.textTertiary),
            ],
          ),
          const Gap(12),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const Gap(4),
          Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildNewsTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.article_outlined, color: AppColors.redPrimary, size: 20),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
