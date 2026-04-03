import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String Function(double) formatter;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.duration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOutCubic,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, current, _) {
        return Text(formatter(current), style: style);
      },
    );
  }
}

