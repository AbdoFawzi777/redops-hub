import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../../features/vuln_tracker/domain/entities/vulnerability.dart';

enum NotificationToneType {
  criticalVuln,
  highVuln,
  medLowVuln,
  chatMessage,
  systemUpdate,
}

class TacticalNotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Plays distinctive audio sound tones and triggers haptic vibration based on notification category & severity
  static Future<void> playNotificationTone(NotificationToneType type) async {
    try {
      switch (type) {
        case NotificationToneType.criticalVuln:
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/critical_alert.wav'));
          await HapticFeedback.heavyImpact();
          break;

        case NotificationToneType.highVuln:
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/high_alert.wav'));
          await HapticFeedback.mediumImpact();
          break;

        case NotificationToneType.medLowVuln:
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/chat_ping.wav'));
          await HapticFeedback.lightImpact();
          break;

        case NotificationToneType.chatMessage:
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/chat_ping.wav'));
          await HapticFeedback.selectionClick();
          break;

        case NotificationToneType.systemUpdate:
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/system_update.wav'));
          await HapticFeedback.lightImpact();
          break;
      }
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    }
  }

  /// Displays tactical floating notification banner with distinct color and action button
  static void showTacticalBanner(
    BuildContext context, {
    required String title,
    required String message,
    required NotificationToneType type,
    VoidCallback? onTap,
    String actionLabel = 'VIEW',
  }) {
    playNotificationTone(type);

    final color = switch (type) {
      NotificationToneType.criticalVuln => AppColors.v3Critical,
      NotificationToneType.highVuln => AppColors.v3Warning,
      NotificationToneType.medLowVuln => AppColors.v3Intel,
      NotificationToneType.chatMessage => AppColors.v3OpsRed,
      NotificationToneType.systemUpdate => AppColors.v3Live,
    };

    final icon = switch (type) {
      NotificationToneType.criticalVuln => Icons.warning_amber_rounded,
      NotificationToneType.highVuln => Icons.error_outline_rounded,
      NotificationToneType.medLowVuln => Icons.info_outline_rounded,
      NotificationToneType.chatMessage => Icons.forum_outlined,
      NotificationToneType.systemUpdate => Icons.system_update_rounded,
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color, width: 1.2),
        ),
        backgroundColor: AppColors.v3CardBg, // #0C0C38
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.v3TextPrimary,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: onTap != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: color,
                onPressed: onTap,
              )
            : null,
      ),
    );
  }

  /// Maps vulnerability severity to distinctive tone
  static NotificationToneType getToneForSeverity(VulnSeverity severity) {
    return switch (severity) {
      VulnSeverity.critical => NotificationToneType.criticalVuln,
      VulnSeverity.high => NotificationToneType.highVuln,
      VulnSeverity.medium => NotificationToneType.medLowVuln,
      VulnSeverity.low => NotificationToneType.medLowVuln,
      VulnSeverity.info => NotificationToneType.medLowVuln,
    };
  }
}
