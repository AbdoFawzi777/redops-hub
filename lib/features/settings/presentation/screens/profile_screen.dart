import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redops_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const RedOpsHeader(
                title: 'OPERATOR PROFILE',
                subtitle: 'Tactical identity management',
                showBackButton: true,
                showSettingsButton: false,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardBg.withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.16)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: primaryColor.withValues(alpha: 0.12),
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null ? Icon(Icons.person, size: 52, color: primaryColor) : null,
                          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                          const Gap(16),
                          Text(
                            user?.displayName ?? 'ANONYMOUS OPERATOR',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            user?.email ?? 'N/A',
                            style: TextStyle(color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, fontSize: 13, fontFamily: 'monospace'),
                          ),
                          const Gap(14),
                          _buildStatusBadge('AUTHORIZED PERSONNEL', AppColors.live),
                        ],
                      ),
                    ),
                    const Gap(24),
                    _buildInfoSection(context, 'SECURITY CLEARANCE', [
                      _buildInfoTile(context, 'UID', user?.uid ?? 'UNKNOWN', Icons.fingerprint),
                      _buildInfoTile(context, 'Provider', 'Google Cloud Auth', Icons.cloud_done_outlined),
                      _buildInfoTile(context, 'Join Date', user?.metadata.creationTime?.toString().split(' ')[0] ?? 'N/A', Icons.calendar_today_outlined),
                    ]),
                    const Gap(24),
                    _buildInfoSection(context, 'OPERATIONAL HISTORY', [
                      _buildHistoryTile(context, 'Reports Submitted', '12', Icons.description_outlined),
                      _buildHistoryTile(context, 'Vulns Identified', '08', Icons.bug_report_outlined),
                      _buildHistoryTile(context, 'Total Bounties', '\$2,450', Icons.account_balance_wallet_outlined),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.redPrimary),
              const Gap(16),
              Text(label, style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value, style: const TextStyle(color: AppColors.redPrimary, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
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

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
              const Gap(2),
              Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
