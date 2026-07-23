import 'package:flutter/material.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseSize;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.baseSize = 16,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Dynamic scale factor calculation
    double scaleFactor = 1.0;

    if (screenWidth < 360) {
      scaleFactor = 0.65;
    } else if (screenWidth < 400) {
      scaleFactor = 0.80;
    } else if (screenWidth < 600) {
      scaleFactor = 0.90;
    } else if (screenWidth > 1000) {
      scaleFactor = 1.2;
    }

    if (screenHeight < 600) {
      scaleFactor *= 0.85;
    }

    final fontSize = baseSize * scaleFactor;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: color ?? Colors.white,
          fontWeight: fontWeight ?? FontWeight.normal,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Custom title widget for Tactical UI headers
class TacticalTitle extends StatelessWidget {
  final String title;
  final bool isHeading;
  final Color? color;

  const TacticalTitle(
    this.title, {
    super.key,
    this.isHeading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double baseSize = isHeading ? 24 : 18;

    if (screenWidth < 360) {
      baseSize = isHeading ? 18 : 14;
    } else if (screenWidth < 400) {
      baseSize = isHeading ? 20 : 16;
    }

    return ResponsiveText(
      title,
      baseSize: baseSize,
      color: color,
      fontWeight: isHeading ? FontWeight.bold : FontWeight.w500,
    );
  }
}
