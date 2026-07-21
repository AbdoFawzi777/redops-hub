import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.radar_outlined, label: 'C2', path: AppRoutes.c2),
    _TabItem(
        icon: Icons.bug_report_outlined, label: 'Vulns', path: AppRoutes.vulns),
    _TabItem(
        icon: Icons.mic_none_outlined,
        label: 'REPORT',
        path: AppRoutes.reporter),
    _TabItem(
        icon: Icons.terminal_outlined, label: 'VAULT', path: AppRoutes.vault),
    _TabItem(
        icon: Icons.forum_outlined,
        label: 'CHAT',
        path: AppRoutes.chatForum),
    _TabItem(
        icon: Icons.shield_outlined,
        label: 'PLAYBOOKS',
        path: AppRoutes.playbooks),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 750;

    if (isLargeScreen) {
      final activeColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;
      final inactiveColor =
          isDark ? AppColors.textTertiary : AppColors.lightTextTertiary;

      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(_tabs[index].path),
              backgroundColor: isDark
                  ? AppColors.cardBg.withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.95),
              extended: screenWidth > 1000,
              minWidth: 72,
              minExtendedWidth: 200,
              selectedIconTheme: IconThemeData(color: activeColor, size: 24),
              unselectedIconTheme: IconThemeData(color: inactiveColor, size: 22),
              selectedLabelTextStyle: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: inactiveColor,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded, color: activeColor, size: 32),
                    if (screenWidth > 1000) ...[
                      const SizedBox(width: 12),
                      Text(
                        'REDOPS HUB',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              destinations: _tabs.map((tab) {
                return NavigationRailDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.icon, color: activeColor),
                  label: Text(tab.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBg.withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.border : AppColors.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.deepBlue : AppColors.deepBlue)
                  .withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isSelected = i == selectedIndex;
                return Expanded(
                  child: _NavButton(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: isSelected,
                    onTap: () => context.go(tab.path),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;
    final inactiveColor =
        isDark ? AppColors.textTertiary : AppColors.lightTextTertiary;
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22)
                .animate(target: isSelected ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12))
                .shimmer(color: Colors.white24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2.2,
                width: 20,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ).animate().scaleX(begin: 0, end: 1),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final String label;
  final String path;
}
