import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CircularStepGauge extends StatefulWidget {
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

  @override
  State<CircularStepGauge> createState() => _CircularStepGaugeState();
}

class _CircularStepGaugeState extends State<CircularStepGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Wrap around: if steps exceed goal, show remainder
  double get _targetStepsProgress {
    if (widget.goalSteps <= 0) return 0.0;
    final wrapped = widget.currentSteps % widget.goalSteps;
    // If exactly at goal boundary, show full
    if (widget.currentSteps > 0 && wrapped == 0) return 1.0;
    return wrapped.toDouble() / widget.goalSteps.toDouble();
  }

  double get _targetXpProgress {
    if (widget.xpToNextLevel <= 0) return 0.0;
    return (widget.currentXP.toDouble() / widget.xpToNextLevel.toDouble())
        .clamp(0.0, 1.0);
  }

  int get _laps => widget.goalSteps > 0 ? widget.currentSteps ~/ widget.goalSteps : 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // Animate from 0 on first build
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularStepGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If values changed, replay animation from 0
    if (oldWidget.currentSteps != widget.currentSteps ||
        oldWidget.currentXP != widget.currentXP) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedSteps = _targetStepsProgress * _animation.value;
        final animatedXp = _targetXpProgress * _animation.value;

        return SizedBox(
          width: double.infinity,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: _StepGaugePainter(
                    stepsProgress: animatedSteps,
                    xpProgress: animatedXp,
                    currentXP: widget.currentXP,
                    backgroundColor: AppColors.stepsGaugeBackground,
                    stepsProgressColor: AppColors.stepsGaugeOrange,
                    xpProgressColor: AppColors.secondary,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatNumber(widget.currentSteps),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_formatNumber(widget.goalSteps ~/ 2)} meta',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_laps > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_laps}x',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  final int currentXP;
  final Color backgroundColor;
  final Color stepsProgressColor;
  final Color xpProgressColor;

  _StepGaugePainter({
    required this.stepsProgress,
    required this.xpProgress,
    required this.currentXP,
    required this.backgroundColor,
    required this.stepsProgressColor,
    required this.xpProgressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 20;
    final innerRadius = outerRadius - 16;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    // Draw step milestones FIRST (behind the bar)
    _drawMilestoneLabels(canvas, center, outerRadius);

    // Draw background arc for steps (outer)
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

    // Draw progress arc for XP (inner)
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

    // Draw inner tick marks for XP
    _drawInnerTickMarks(canvas, center, innerRadius);

    // Draw tick marks on the outside
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

  void _drawInnerTickMarks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;
    const numTicks = 20;

    for (int i = 0; i <= numTicks; i++) {
      final angle = startAngle + (sweepAngle * i / numTicks);
      final outerTick = radius - 8;
      final innerTick = i % 5 == 0 ? radius - 14 : radius - 11;

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

    // Draw XP label at the end of the progress
    if (xpProgress > 0) {
      final xpAngle = startAngle + (sweepAngle * xpProgress);
      final labelRadius = radius - 28;

      final position = Offset(
        center.dx + labelRadius * math.cos(xpAngle),
        center.dy + labelRadius * math.sin(xpAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$currentXP',
          style: TextStyle(
            color: xpProgressColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
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

  void _drawMilestoneLabels(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final milestones = [0, 2500, 5000, 10000, 15000, 20000];
    final labels = ['0', '2,500', '5,000', '10,000', '15,000', '20,000'];

    for (int i = 0; i < milestones.length; i++) {
      final progress = milestones[i] / 20000;
      final angle = startAngle + (sweepAngle * progress);
      final labelRadius = radius + 38;

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
