import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class WebConsoleInfoScreen extends StatelessWidget {
  const WebConsoleInfoScreen({super.key});

  Future<void> _launchWebConsole() async {
    final url = Uri.parse('https://redops-hub.web.app');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.v3Bg, // #080824
      appBar: AppBar(
        backgroundColor: AppColors.v3Bg,
        elevation: 0,
        title: const Text(
          'WEB CONSOLE GATEWAY',
          style: TextStyle(
            color: AppColors.v3TextPrimary,
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.v3TextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const Gap(12),
              _buildTitleSection(),
              const Gap(16),
              _buildFeatureCard(
                icon: Icons.computer_rounded,
                title: 'Live C2 Shell Terminals',
                description: 'Browser-based interactive shells with real-time sync.',
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, end: 0),
              const Gap(12),
              _buildFeatureCard(
                icon: Icons.radar_rounded,
                title: 'Network Recon Scanner',
                description: 'Nmap-powered scanning with visual topology maps.',
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, end: 0),
              const Gap(12),
              _buildFeatureCard(
                icon: Icons.grid_view_rounded,
                title: 'MITRE ATT&CK Mapping',
                description: 'Auto-tag findings to TTPs with heatmap view.',
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, end: 0),
              const Gap(12),
              _buildFeatureCard(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Professional PDF Reports',
                description: 'Client-ready reports with executive summary.',
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05, end: 0),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _launchWebConsole,
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: const Text(
                    'LAUNCH WEB CONSOLE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.v3OpsRed, // #E02E2E
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.v3OpsRed.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.v3OpsRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.v3OpsRed.withValues(alpha: 0.3),
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
                  color: AppColors.v3OpsRed,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
              const Gap(6),
              const Text(
                'WEB CONSOLE GATEWAY',
                style: TextStyle(
                  color: AppColors.v3OpsRed,
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
          'PREMIUM',
          style: TextStyle(
            color: AppColors.v3Critical,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: TextStyle(
            color: AppColors.v3TextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
        Gap(2),
        Text(
          '// cloud command center',
          style: TextStyle(
            color: AppColors.v3TextMuted,
            fontSize: 11.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.v3CardBg, // #0C0C38
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.v3CardBorder, // #1A1A4A
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.v3OpsRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.v3OpsRed.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: AppColors.v3OpsRed, size: 20),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.v3TextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.v3TextMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
