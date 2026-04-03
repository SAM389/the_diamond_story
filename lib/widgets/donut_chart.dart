import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double size;
  final String centerLabel;
  final String centerValue;
  final TextStyle? centerLabelStyle;
  final TextStyle? centerValueStyle;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 260,
    required this.centerLabel,
    required this.centerValue,
    this.centerLabelStyle,
    this.centerValueStyle,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.segments.fold<double>(0, (sum, s) => sum + s.value);

    return Column(
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _DonutPainter(
                  segments: widget.segments,
                  progress: _controller.value,
                  hoveredIndex: _hoveredIndex,
                ),
                child: child,
              );
            },
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.centerLabel, style: widget.centerLabelStyle),
                  const SizedBox(height: 6),
                  Text(widget.centerValue, style: widget.centerValueStyle),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: List.generate(widget.segments.length, (index) {
            final segment = widget.segments[index];
            final pct = total == 0 ? 0 : (segment.value / total) * 100;
            final isHovered = _hoveredIndex == index;
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: segment.color.withValues(alpha: isHovered ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: segment.color.withValues(alpha: isHovered ? 0.6 : 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: segment.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${segment.label} ${pct.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double progress;
  final int? hoveredIndex;

  const _DonutPainter({
    required this.segments,
    required this.progress,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width * 0.35),
        -math.pi / 2,
        math.pi * 2,
        false,
        paint,
      );
      return;
    }

    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width * 0.35,
    );
    double start = -math.pi / 2;
    final maxSweep = math.pi * 2 * progress;
    double drawn = 0;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweep = (segment.value / total) * (math.pi * 2);
      final remaining = maxSweep - drawn;
      if (remaining <= 0) break;
      final drawSweep = sweep < remaining ? sweep : remaining;
      final isHovered = hoveredIndex == i;
      final paint = Paint()
        ..color = isHovered
            ? _brighten(segment.color, 0.20)
            : segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 28 : 24
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, start, drawSweep, false, paint);
      start += sweep;
      drawn += drawSweep;
    }
  }

  static Color _brighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final light = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(light).toColor();
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.segments != segments;
  }
}

