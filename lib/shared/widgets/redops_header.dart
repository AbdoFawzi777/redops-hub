import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_routes.dart';
import '../../core/localization/app_translations.dart';

class RedOpsHeader extends ConsumerWidget {
  const RedOpsHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showLiveDot = true,
    this.showBackButton = false,
    this.showSettingsButton = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showLiveDot;
  final bool showBackButton;
  final bool showSettingsButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(l10nProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios,
                          size: 14, color: isDark ? AppColors.redPrimary : AppColors.deepBlue),
                      const SizedBox(width: 4),
                      Text(
                        s.back.toUpperCase(),
                        style: TextStyle(
                          color: (isDark ? AppColors.redPrimary : AppColors.deepBlue).withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Text(
                      'RedOps',
                      style: TextStyle(
                        color: (isDark ? AppColors.redPrimary : AppColors.deepBlue).withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                    if (showLiveDot) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.live,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.live.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                       .shimmer(duration: 2.seconds, color: Colors.white30),
                    ],
                  ],
                ),
              if (showSettingsButton && !showBackButton)
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined, 
                    color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, 
                    size: 20
                  ),
                  onPressed: () => context.push(AppRoutes.settings),
                ).animate().rotate(begin: 0, end: 0.25, duration: 500.ms, curve: Curves.easeOut),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            width: 40,
            color: isDark ? AppColors.redPrimary : AppColors.deepBlue,
          ).animate().scaleX(begin: 0, end: 1, duration: 600.ms, alignment: Alignment.centerLeft),
        ],
      ),
    );
  }
}
