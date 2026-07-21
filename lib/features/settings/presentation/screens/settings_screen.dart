
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
import '../../../../shared/widgets/redops_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider);
    final s = ref.watch(l10nProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth?.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Scaffold(
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
          child: Column(
            children: [
              RedOpsHeader(
                title: s.settingsTitle,
                subtitle: s.settingsSubtitle,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildOperatorCard(context, user, primaryColor, isDark),
                    const Gap(24),
                    _buildSectionHeader('OPERATOR PREFERENCES', isDark),
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
                        activeThumbColor: primaryColor,
                      ),
                    ),
                    const Gap(12),
                    _buildSettingTile(
                      context,
                      icon: Icons.language_outlined,
                      title: s.language,
                      subtitle: locale.languageCode == 'en' ? 'English (US)' : 'العربية',
                      onTap: () {
                        ref.read(languageProvider.notifier).state = locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
                      },
                      trailing: const Icon(Icons.swap_horiz, color: AppColors.textTertiary),
                    ),
                    const Gap(12),
                    _buildSettingTile(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Security PIN Protocol',
                      subtitle: ref.watch(isPinEnabledProvider) ? 'Access code configured' : 'Set your secure PIN code',
                      onTap: () => context.push(AppRoutes.pinSetup),
                      trailing: Icon(
                        ref.watch(isPinEnabledProvider) ? Icons.verified_user : Icons.add_moderator, 
                        color: ref.watch(isPinEnabledProvider) ? AppColors.live : primaryColor, 
                        size: 20
                      ),
                    ),
                    const Gap(12),
                    ref.watch(isBiometricsSupportedProvider).when(
                      data: (isSupported) => isSupported 
                        ? _buildSettingTile(
                            context,
                            icon: Icons.fingerprint,
                            title: 'Biometric Unlock',
                            subtitle: 'Use fingerprint for quick access',
                            trailing: Switch(
                              value: ref.watch(securitySettingsProvider).isBiometricsEnabled,
                              onChanged: (val) async {
                                await ref.read(authControllerProvider.notifier).toggleBiometrics(val);
                              },
                              activeThumbColor: primaryColor,
                            ),
                          )
                        : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const Gap(24),
                    _buildSectionHeader('TEAM COLLABORATION', isDark),
                    _buildSettingTile(
                      context,
                      icon: Icons.forum_outlined,
                      title: 'Tactical Chat Room',
                      subtitle: 'Secure audio & text team exchange',
                      onTap: () => context.push(AppRoutes.chatForum),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
                    ),
                    const Gap(24),
                    _buildSectionHeader('WEB CONSOLE GATEWAY', isDark),
                    _buildWebConsoleCard(context, isDark),
                    const Gap(24),
                    _buildSectionHeader('SYSTEM STATUS', isDark),
                    _buildSystemInfo(isDark),
                    const Gap(24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(s.terminateSession),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redPrimary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.redPrimary,
                          side: const BorderSide(color: AppColors.redPrimary, width: 1),
                        ),
                      ),
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorCard(BuildContext context, dynamic user, Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg.withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person_outline, color: primaryColor, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'ANONYMOUS OPERATOR',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(4),
                Text(
                  user?.email ?? 'No identity linked',
                  style: TextStyle(
                    color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.profile),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            color: primaryColor,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? AppColors.redPrimary : AppColors.deepBlue,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bg800 : AppColors.lightScaffold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
            fontSize: 12,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildSystemInfo(bool isDark) {
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Codename', style: TextStyle(color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, fontSize: 12)),
              Text('NIGHTFALL', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Version', style: TextStyle(color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, fontSize: 12)),
              Text('1.0.0-STABLE', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12)),
            ],
          ),
          const Gap(10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Connection', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              Text('Secure Tunnel Active', style: TextStyle(color: AppColors.live, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ).animate().shimmer(delay: 1.seconds, duration: 2.seconds);
  }



  Widget _buildWebConsoleCard(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg.withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: 0.16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.webConsole),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dashboard_customize_outlined, color: primaryColor, size: 22),
                      const Gap(10),
                      Text(
                        'RedOps Hub Web Console',
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                  const Gap(10),
                  Text(
                    'Unlock advanced operations on the big screen. Sync your mobile account to access C2 terminal shells, network recon scanner, credential vault, MITRE matrix mapping, and PDF report generator.',
                    style: TextStyle(
                      color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.webConsole),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('EXPLORE WEB FEATURES'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}