import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 12,
    this.child,
    this.colors,
    this.trackColor,
  });

  /// 0.0 to 1.0
  final double value;
  final double size;
  final double strokeWidth;
  final Widget? child;

  /// Two or more gradient colors. Defaults to the app accent gradient.
  final List<Color>? colors;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final track =
        trackColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              value: value.clamp(0.0, 1.0),
              trackColor: track,
              strokeWidth: strokeWidth,
              colors: colors ?? const [AppColors.purple, AppColors.blue],
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.trackColor,
    required this.strokeWidth,
    required this.colors,
  });

  final double value;
  final Color trackColor;
  final double strokeWidth;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (value <= 0) return;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: colors.length >= 2 ? colors : [colors.first, colors.first],
      transform: const GradientRotation(-math.pi / 2),
    );
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);
    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * value, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.colors != colors;
}
