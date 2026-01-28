import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CircularStepGauge extends StatelessWidget {
  final int currentSteps;
  final int goalSteps;
  final int currentXP;
  final int xpToNextLevel;

  const CircularStepGauge({
    super.key,
    required this.currentSteps,
    this.goalSteps = 20000,
    this.currentXP = 450,
    this.xpToNextLevel = 1000,
  });

  double get stepsProgress => goalSteps > 0
      ? (currentSteps.toDouble() / goalSteps.toDouble()).clamp(0.0, 1.0)
      : 0.0;
  double get xpProgress => xpToNextLevel > 0
      ? (currentXP.toDouble() / xpToNextLevel.toDouble()).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The gauge itself
          SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: _StepGaugePainter(
                stepsProgress: stepsProgress,
                xpProgress: xpProgress,
                backgroundColor: AppColors.stepsGaugeBackground,
                stepsProgressColor: AppColors.stepsGaugeOrange,
                xpProgressColor: AppColors.secondary,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Step count
                    Text(
                      _formatNumber(currentSteps),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // Goal indicator
                    Text(
                      '${_formatNumber(goalSteps ~/ 2)} meta',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}

class _StepGaugePainter extends CustomPainter {
  final double stepsProgress;
  final double xpProgress;
  final Color backgroundColor;
  final Color stepsProgressColor;
  final Color xpProgressColor;

  _StepGaugePainter({
    required this.stepsProgress,
    required this.xpProgress,
    required this.backgroundColor,
    required this.stepsProgressColor,
    required this.xpProgressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 20;
    final innerRadius = outerRadius - 16; // XP bar closer inside

    // Arc parameters
    const startAngle = 0.75 * math.pi; // Start from bottom left
    const sweepAngle = 1.5 * math.pi; // Sweep to bottom right (270 degrees)

    // Draw step milestones FIRST (behind the bar)
    _drawMilestoneLabels(canvas, center, outerRadius);

    // Draw background arc for steps (outer, medium thickness)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw progress arc for steps (outer)
    final stepsProgressPaint = Paint()
      ..color = stepsProgressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle * stepsProgress,
      false,
      stepsProgressPaint,
    );

    // Draw background arc for XP (inner)
    final xpBackgroundPaint = Paint()
      ..color = backgroundColor.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      sweepAngle,
      false,
      xpBackgroundPaint,
    );

    // Draw progress arc for XP (inner, light blue)
    final xpProgressPaint = Paint()
      ..color = xpProgressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      sweepAngle * xpProgress,
      false,
      xpProgressPaint,
    );

    // Draw tick marks on the outside AFTER the bars
    _drawTickMarks(canvas, center, outerRadius);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;
    const numTicks = 40;

    for (int i = 0; i <= numTicks; i++) {
      final angle = startAngle + (sweepAngle * i / numTicks);
      // Position ticks OUTSIDE the bar
      final innerTick = radius + 12;
      final outerTick = i % 5 == 0 ? radius + 20 : radius + 16;

      final inner = Offset(
        center.dx + innerTick * math.cos(angle),
        center.dy + innerTick * math.sin(angle),
      );
      final outer = Offset(
        center.dx + outerTick * math.cos(angle),
        center.dy + outerTick * math.sin(angle),
      );

      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  void _drawMilestoneLabels(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final milestones = [0, 2500, 5000, 10000, 15000, 20000];
    final labels = ['0', '2,500', '5,000', '10,000', '15,000', '20,000'];

    for (int i = 0; i < milestones.length; i++) {
      final progress = milestones[i] / 20000;
      final angle = startAngle + (sweepAngle * progress);
      final labelRadius = radius + 38; // Further out past ticks

      final position = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepGaugePainter oldDelegate) {
    return oldDelegate.stepsProgress != stepsProgress ||
        oldDelegate.xpProgress != xpProgress;
  }
}
