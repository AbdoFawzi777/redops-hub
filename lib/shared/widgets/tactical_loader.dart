import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class TacticalLoader extends StatelessWidget {
  const TacticalLoader({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = isDark ? AppColors.redPrimary : AppColors.deepBlue;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Core Glowing Aura (Pulsing behind the animation)
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.5.seconds),

          // 2. The Animated Tech GIF
          ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.asset(
              'assets/images/loading_tech.gif',
              width: size,
              height: size,
              fit: BoxFit.contain,
              // Blend slightly with theme color for maximum "integration" feeling
              color: isDark ? null : AppColors.deepBlue.withValues(alpha: 0.2),
              colorBlendMode: isDark ? null : BlendMode.darken,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.radar_rounded,
                size: size * 0.5,
                color: glowColor,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),

          // 3. Cybernetic Scan Line (Horizontal beam passing through)
          Positioned(
            child: Container(
              width: size * 1.2,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    glowColor.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat())
             .moveY(begin: -size/2, end: size/2, duration: 2.seconds, curve: Curves.easeInOut),
          ),

          // 4. Circular Outer Ring (Tech Decoration)
          Container(
            width: size * 1.1,
            height: size * 1.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: glowColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat())
           .rotate(duration: 10.seconds),
        ],
      ),
    );
  }
}
