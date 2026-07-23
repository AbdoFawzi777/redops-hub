import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/hacker_news_service.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../../../shared/widgets/tactical_loader.dart';

final liveNewsProvider = FutureProvider<List<CyberNewsItem>>((ref) async {
  return HackerNewsService.getLiveCyberNews();
});

class HackerIntelScreen extends ConsumerWidget {
  const HackerIntelScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening Link: $url'),
            backgroundColor: AppColors.v3Live,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(liveNewsProvider);

    return Scaffold(
      backgroundColor: AppColors.dynamicBg(context),
      body: SafeArea(
        child: Column(
          children: [
            const RedOpsHeader(
              title: 'HACKER INTELLIGENCE',
              subtitle: 'Live global cybersecurity feeds & external advisories',
              showBackButton: true,
            ),
            Expanded(
              child: newsAsync.when(
                data: (newsItems) => ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection(context, 'EXPLOIT ADVISORIES & HACKERONE', [
                      _buildIntelCard(
                        context,
                        title: 'regreSSHion: OpenSSH RCE Vulnerability (CVE-2024-6387)',
                        subtitle: 'Qualys Security · High Severity Advisory',
                        tag: 'CRITICAL',
                        tagColor: AppColors.v3Critical,
                        url: 'https://cvedb.shodan.io/cve/CVE-2024-6387',
                      ),
                      _buildIntelCard(
                        context,
                        title: 'CISA Known Exploited Vulnerabilities Catalog Feed',
                        subtitle: 'CISA Official · Real-time Exploited Vulns Stream',
                        tag: 'CISA KEV',
                        tagColor: AppColors.v3Warning,
                        url: 'https://cvedb.shodan.io/cves?is_kev=true',
                      ),
                    ]),
                    const Gap(24),
                    _buildSection(context, 'LIVE GLOBAL CYBER NEWS', [
                      ...newsItems.map(
                        (item) => _buildNewsTile(
                          context,
                          title: item.title,
                          subtitle: '${item.source} · ${item.pubDate}',
                          category: item.category,
                          url: item.link,
                        ),
                      ),
                    ]),
                  ],
                ),
                loading: () => const Center(child: TacticalLoader(size: 100)),
                error: (e, _) => Center(
                  child: Text(
                    'FAILED TO LOAD NEWS: $e',
                    style: const TextStyle(color: AppColors.v3Critical, fontFamily: 'monospace'),
                  ),
                ),
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
          style: TextStyle(
            color: AppColors.dynamicTextMuted(context),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
        const Gap(12),
        ...children,
      ],
    );
  }

  Widget _buildIntelCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required String url,
  }) {
    return InkWell(
      onTap: () => _openUrl(context, url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dynamicCardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dynamicCardBorder(context)),
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
                    border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_outward, size: 18, color: AppColors.v3OpsRed),
                  onPressed: () => _openUrl(context, url),
                  tooltip: 'Open Report Source',
                ),
              ],
            ),
            const Gap(8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.dynamicTextPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.dynamicTextMuted(context),
                fontSize: 11.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildNewsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String category,
    required String url,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.dynamicCardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dynamicCardBorder(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () => _openUrl(context, url),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.v3OpsRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.article_outlined, color: AppColors.v3OpsRed, size: 20),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.dynamicTextPrimary(context),
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$category · $subtitle',
            style: TextStyle(
              color: AppColors.dynamicTextMuted(context),
              fontSize: 10.5,
              fontFamily: 'monospace',
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_outward_rounded, size: 18, color: AppColors.v3Live),
          onPressed: () => _openUrl(context, url),
          tooltip: 'Open Full Article',
        ),
      ),
    );
  }
}
