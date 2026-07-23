import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ai_assistant_dialog.dart';
import '../../features/chat_forum/presentation/providers/chat_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime _lastReadChatTime = DateTime.now();

  static const _tabs = [
    _TabItem(
      icon: Icons.radar_outlined,
      label: 'C2',
      path: AppRoutes.c2,
      activeColor: AppColors.v3Live, // #00FF85
    ),
    _TabItem(
      icon: Icons.bug_report_outlined,
      label: 'Vulns',
      path: AppRoutes.vulns,
      activeColor: AppColors.v3Critical, // #FF3B3B
    ),
    _TabItem(
      icon: Icons.mic_none_outlined,
      label: 'Report',
      path: AppRoutes.reporter,
      activeColor: AppColors.v3Covert, // #9B59B6
    ),
    _TabItem(
      icon: Icons.terminal_outlined,
      label: 'Vault',
      path: AppRoutes.vault,
      activeColor: AppColors.v3Code, // #00FFD1
    ),
    _TabItem(
      icon: Icons.shield_outlined,
      label: 'Devs',
      path: AppRoutes.playbooks,
      activeColor: AppColors.v3Intel, // #00D4FF
    ),
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
    final location = GoRouterState.of(context).uri.toString();
    final isChatOpen = location.startsWith(AppRoutes.chatForum);

    if (isChatOpen) {
      _lastReadChatTime = DateTime.now();
    }

    final chatMessages = ref.watch(chatMessagesStreamProvider).valueOrNull ?? [];
    final myEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    final unreadCount = isChatOpen
        ? 0
        : chatMessages.where((m) => m.senderEmail != myEmail && m.timestamp.isAfter(_lastReadChatTime)).length;

    return Scaffold(
      backgroundColor: AppColors.dynamicBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.dynamicOuterBg(context),
            border: Border(bottom: BorderSide(color: AppColors.dynamicCardBorder(context), width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.v3OpsRed, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'REDOPS HUB',
                        style: TextStyle(
                          color: AppColors.dynamicTextPrimary(context),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // AI Assistant Button
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, color: AppColors.v3OpsRed, size: 18),
                        onPressed: () => AiAssistantDialog.show(context),
                        tooltip: 'Cyber AI Assistant',
                      ),
                      // Tactical Chat Quick Button with Unread Badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.forum_outlined, color: AppColors.v3Code, size: 18),
                            onPressed: () {
                              setState(() {
                                _lastReadChatTime = DateTime.now();
                              });
                              context.go(AppRoutes.chatForum);
                            },
                            tooltip: 'Tactical Chat',
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.v3OpsRed,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.dynamicOuterBg(context), width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Settings & Security Quick Button
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.v3Intel, size: 18),
                        onPressed: () => context.go(AppRoutes.settings),
                        tooltip: 'Settings & Security',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.dynamicOuterBg(context),
          border: Border(
            top: BorderSide(
              color: AppColors.dynamicCardBorder(context),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isSelected = i == selectedIndex;
                return Expanded(
                  child: _NavButton(
                    icon: tab.icon,
                    label: tab.label,
                    activeColor: tab.activeColor,
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
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : AppColors.dynamicTextMuted(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
              ),
              child: Icon(icon, color: color, size: 18)
                  .animate(target: isSelected ? 1 : 0)
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontFamily: 'monospace',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 12 : 0,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
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
    required this.activeColor,
  });
  final IconData icon;
  final String label;
  final String path;
  final Color activeColor;
}
