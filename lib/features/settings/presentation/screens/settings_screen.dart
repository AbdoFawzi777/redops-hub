import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/ai_assistant_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider);
    final s = ref.watch(l10nProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth?.currentUser;

    return Scaffold(
      backgroundColor: AppColors.v3Bg, // #080824
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            const Gap(10),
            _buildTitleSection(),
            const Gap(14),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  _buildOperatorCard(context, user),
                  const Gap(20),
                  _buildSectionHeader('OPERATOR PREFERENCES'),
                  _buildSettingTile(
                    context,
                    icon: Icons.dark_mode_outlined,
                    title: s.themeMode,
                    subtitle: themeMode == ThemeMode.dark ? 'Dark Mode Active' : 'Light Mode Active',
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeTrackColor: AppColors.v3OpsRed,
                    ),
                  ),
                  const Gap(10),
                  _buildSettingTile(
                    context,
                    icon: Icons.language_outlined,
                    title: s.language,
                    subtitle: locale.languageCode == 'en' ? 'English (US)' : 'العربية',
                    onTap: () {
                      ref.read(languageProvider.notifier).state = locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
                    },
                    trailing: const Icon(Icons.swap_horiz, color: AppColors.v3TextMuted),
                  ),
                  const Gap(20),
                  _buildSectionHeader('SECURITY & AUTHENTICATION'),
                  _buildSettingTile(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Security PIN Protocol',
                    subtitle: ref.watch(isPinEnabledProvider) ? 'Access PIN configured' : 'Set your secure PIN code',
                    onTap: () => context.push(AppRoutes.pinSetup),
                    trailing: Icon(
                      ref.watch(isPinEnabledProvider) ? Icons.verified_user : Icons.add_moderator,
                      color: ref.watch(isPinEnabledProvider) ? AppColors.v3Live : AppColors.v3OpsRed,
                      size: 20,
                    ),
                  ),
                  const Gap(10),
                  ref.watch(isBiometricsSupportedProvider).when(
                    data: (isSupported) => isSupported
                        ? _buildSettingTile(
                            context,
                            icon: Icons.fingerprint,
                            title: 'Biometric Unlock',
                            subtitle: 'Use fingerprint / Face ID access',
                            trailing: Switch(
                              value: ref.watch(securitySettingsProvider).isBiometricsEnabled,
                              onChanged: (val) async {
                                await ref.read(authControllerProvider.notifier).toggleBiometrics(val);
                              },
                              activeTrackColor: AppColors.v3OpsRed,
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const Gap(20),
                  _buildSectionHeader('AI & TEAM COLLABORATION'),
                  _buildSettingTile(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'RedOps Cyber AI Assistant',
                    subtitle: 'Powered by Gemini API & Threat AI',
                    onTap: () => AiAssistantDialog.show(context),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.v3TextMuted),
                  ),
                  const Gap(10),
                  _buildSettingTile(
                    context,
                    icon: Icons.forum_outlined,
                    title: 'Tactical Chat Lounge',
                    subtitle: 'Encrypted operator messaging',
                    onTap: () => context.push(AppRoutes.chatForum),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.v3TextMuted),
                  ),
                  const Gap(20),
                  _buildSectionHeader('WEB CONSOLE GATEWAY'),
                  _buildWebConsoleTile(context),
                  const Gap(20),
                  _buildSectionHeader('SYSTEM INFRASTRUCTURE'),
                  _buildSystemStatusCard(),
                  const Gap(20),
                  _buildSectionHeader('DEVELOPER & INTELLECTUAL PROPERTY'),
                  _buildDeveloperCreditCard(context),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(
                        s.terminateSession,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.v3OpsRed.withValues(alpha: 0.15),
                        foregroundColor: AppColors.v3OpsRed,
                        side: const BorderSide(color: AppColors.v3OpsRed, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
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
                  'SYSTEM SETTINGS',
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
            'v1.0.0-STABLE',
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

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control Center',
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
            '// operator profile & security protocols',
            style: TextStyle(
              color: AppColors.v3TextMuted,
              fontSize: 11.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ).animate().fadeIn(delay: 150.ms),
    );
  }

  Widget _buildOperatorCard(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.v3CardBg, // #0C0C38
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.v3CardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.v3OpsRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.v3OpsRed.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.person_outline, color: AppColors.v3OpsRed, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'ANONYMOUS OPERATOR',
                  style: const TextStyle(
                    color: AppColors.v3TextPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Gap(4),
                Text(
                  user?.email ?? 'No identity linked',
                  style: const TextStyle(
                    color: AppColors.v3TextMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.profile),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            color: AppColors.v3OpsRed,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.v3TextMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.v3CardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.v3CardBorder, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.v3OuterBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.v3Intel, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.v3TextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.v3TextMuted,
            fontSize: 10.5,
            fontFamily: 'monospace',
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildWebConsoleTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.v3CardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.v3CardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_outlined, color: AppColors.v3OpsRed, size: 20),
              const Gap(10),
              const Text(
                'RedOps Hub Web Console',
                style: TextStyle(
                  color: AppColors.v3TextPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const Gap(6),
          const Text(
            'Access cloud command center, live C2 terminals, Nmap recon scanner, MITRE matrix, and PDF reports.',
            style: TextStyle(
              color: AppColors.v3TextSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.35,
            ),
          ),
          const Gap(14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.webConsole),
              icon: const Icon(Icons.launch, size: 16),
              label: const Text(
                'LAUNCH WEB CONSOLE',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.v3OpsRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.v3ConsoleBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.v3CardBorder, width: 1),
      ),
      child: Column(
        children: [
          const _SysRow(label: 'Codename', value: 'NIGHTFALL', valueColor: AppColors.v3OpsRed),
          const Gap(6),
          const _SysRow(label: 'Version', value: '1.0.0-STABLE', valueColor: AppColors.v3TextSecondary),
          const Gap(6),
          const _SysRow(label: 'Connection', value: 'TLS Tunnel Active', valueColor: AppColors.v3Live),
        ],
      ),
    );
  }

  Widget _buildDeveloperCreditCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.v3CardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.v3OpsRed.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.v3OpsRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user, color: AppColors.v3OpsRed, size: 20),
              ),
              const Gap(12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOFTWARE ENGINEER',
                      style: TextStyle(color: AppColors.v3Code, fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    Gap(2),
                    Text(
                      'Abdallah Fawzi Ali',
                      style: TextStyle(color: AppColors.v3TextPrimary, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.v3Elite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.v3Elite.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'SOLE OWNER',
                  style: TextStyle(color: AppColors.v3Elite, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const Gap(12),
          const Text(
            'RedOps Hub architecture, design, and intellectual property rights are exclusively created, engineered, and owned by Software Engineer Abdallah Fawzi Ali (عبد الله فوزي علي).',
            style: TextStyle(
              color: AppColors.v3TextSecondary,
              fontSize: 11,
              height: 1.4,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _SysRow extends StatelessWidget {
  const _SysRow({required this.label, required this.value, required this.valueColor});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.v3TextMuted, fontSize: 11, fontFamily: 'monospace')),
        Text(value, style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}