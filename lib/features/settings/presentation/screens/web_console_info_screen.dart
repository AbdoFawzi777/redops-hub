import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class WebConsoleInfoScreen extends StatelessWidget {
  const WebConsoleInfoScreen({super.key});

  Future<void> _launchWebConsole() async {
    final url = Uri.parse('https://redops-hub.web.app');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WEB CONSOLE GATEWAY'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.computer_rounded, color: primaryColor, size: 36),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RedOps Web Gateway',
                              style: TextStyle(
                                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'Unlock advanced capabilities on the web console.',
                              style: TextStyle(
                                color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                const Gap(28),
                Text(
                  'PREMIUM WEB FEATURES',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const Gap(16),
                _buildFeatureCard(
                  context,
                  icon: Icons.terminal_rounded,
                  title: 'Live C2 Shell Terminals',
                  description: 'Interact directly with active target agents using a fully-featured, secure command terminal on your big screen.',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, end: 0),
                const Gap(12),
                _buildFeatureCard(
                  context,
                  icon: Icons.radar_rounded,
                  title: 'Network Recon Scanner',
                  description: 'Run network discovery, map IP ranges, perform advanced port scanning, and view asset vulnerability heatmaps.',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, end: 0),
                const Gap(12),
                _buildFeatureCard(
                  context,
                  icon: Icons.grid_view_rounded,
                  title: 'MITRE ATT&CK Mapping',
                  description: 'Visualize your security findings mapped to the international MITRE ATT&CK Matrix to demonstrate business risks.',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, end: 0),
                const Gap(12),
                _buildFeatureCard(
                  context,
                  icon: Icons.picture_as_pdf_rounded,
                  title: 'Professional PDF Reports',
                  description: 'Generate beautiful, client-ready compliance reports and vulnerability audits from your field data in one click.',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05, end: 0),
                const Gap(12),
                _buildFeatureCard(
                  context,
                  icon: Icons.wifi_tethering_rounded,
                  title: 'HQ Operations Telemetry',
                  description: 'Monitor real-time operator feeds, active sessions, credential security, and live threat logs in the operations room.',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.05, end: 0),
                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _launchWebConsole,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(
                      'LAUNCH WEB CONSOLE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.95, 0.95)),
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(6),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                    fontSize: 11.5,
                    height: 1.45,
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
