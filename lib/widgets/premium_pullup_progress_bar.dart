import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/pullup_counter.dart';
import '../utils/app_colors.dart';
import 'package:REPX/l10n/app_localizations.dart';

/// Barra diagonal premium que muestra el progreso del movimiento Pull-Up
class PremiumPullUpProgressBar extends StatefulWidget {
  final PullUpCounter counter;
  final double currentHeadHeight;
  final double barHeight;

  const PremiumPullUpProgressBar({
    super.key,
    required this.counter,
    required this.currentHeadHeight,
    required this.barHeight,
  });

  @override
  State<PremiumPullUpProgressBar> createState() =>
      _PremiumPullUpProgressBarState();
}

class _PremiumPullUpProgressBarState extends State<PremiumPullUpProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(PremiumPullUpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentHeadHeight != widget.currentHeadHeight) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 480,
      child: CustomPaint(
        painter: PullUpProgressPainter(
          counter: widget.counter,
          currentHeadHeight: widget.currentHeadHeight,
          barHeight: widget.barHeight,
          pulseAnimation: _pulseAnimation,
          progressAnimation: _progressAnimation,
          l10n: AppLocalizations.of(context)!,
        ),
      ),
    );
  }
}

class PullUpProgressPainter extends CustomPainter {
  final PullUpCounter counter;
  final double currentHeadHeight;
  final double barHeight;
  final Animation<double> pulseAnimation;
  final Animation<double> progressAnimation;
  final AppLocalizations l10n;

  PullUpProgressPainter({
    required this.counter,
    required this.currentHeadHeight,
    required this.barHeight,
    required this.pulseAnimation,
    required this.progressAnimation,
    required this.l10n,
  }) : super(repaint: Listenable.merge([pulseAnimation, progressAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;

    // Calcular progreso basado en posición de cabeza relativa a la barra
    double progress = _calculateProgress();

    // Dibujar fondo de la barra diagonal
    _drawDiagonalTrack(canvas, center, radius);

    // Dibujar progreso actual
    _drawProgressArc(canvas, center, radius, progress);

    // Dibujar marcador de barra
    _drawBarMarker(canvas, center, radius);

    // Dibujar posición actual de cabeza
    _drawHeadPosition(canvas, center, radius, progress);

    // Dibujar información de tiempo
    _drawTimeInfo(canvas, center, radius);

    // Dibujar estadísticas de fase
    _drawPhaseStats(canvas, center, radius);
  }

  double _calculateProgress() {
    // Normalizar la posición de la cabeza entre 0 (arriba) y 1 (abajo)
    // La barra está en barHeight, así que:
    // - Si headHeight < barHeight, está arriba (progress > 0.5)
    // - Si headHeight > barHeight, está abajo (progress < 0.5)

    const double maxRange = 0.4; // Rango máximo esperado de movimiento
    double relativePosition = (currentHeadHeight - barHeight) / maxRange;

    // Invertir y normalizar: 0 = abajo, 1 = arriba
    double progress = 0.5 - (relativePosition * 0.5);
    return progress.clamp(0.0, 1.0);
  }

  void _drawDiagonalTrack(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dibujar arco de fondo (semicírculo diagonal)
    final rect =
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.5, false, paint);
  }

  void _drawProgressArc(
      Canvas canvas, Offset center, double radius, double progress) {
    final paint = Paint()
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gradiente basado en la fase actual
    Color progressColor;
    switch (counter.currentPhase) {
      case PullUpPhase.up:
        progressColor = AppColors.successGreen;
        break;
      case PullUpPhase.down:
        progressColor = AppColors.primaryCyan;
        break;
      case PullUpPhase.transition:
        progressColor = Colors.orange;
        break;
    }

    paint.color = progressColor.withValues(alpha: 0.8);

    final rect =
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);
    final sweepAngle = (math.pi * 0.5) * progress * progressAnimation.value;
    canvas.drawArc(rect, -math.pi * 0.75, sweepAngle, false, paint);

    // Efecto de brillo en el extremo
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = progressColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final endAngle = -math.pi * 0.75 + sweepAngle;
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      canvas.drawCircle(endPoint, 6 * pulseAnimation.value, glowPaint);
    }
  }

  void _drawBarMarker(Canvas canvas, Offset center, double radius) {
    // Marcador en el punto medio (posición de la barra)
    final markerAngle = -math.pi * 0.5; // Punto medio del arco
    final markerPoint = Offset(
      center.dx + radius * math.cos(markerAngle),
      center.dy + radius * math.sin(markerAngle),
    );

    final paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    canvas.drawCircle(markerPoint, 4, paint);

    // Marcador de barra más sutil (sin texto)
  }

  void _drawHeadPosition(
      Canvas canvas, Offset center, double radius, double progress) {
    final headAngle = -math.pi * 0.75 + (math.pi * 0.5) * progress;
    final headPoint = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );

    // Círculo principal de posición
    final paint = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.fill;

    canvas.drawCircle(headPoint, 8, paint);

    // Efecto de pulso
    final pulsePaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(headPoint, 12 * pulseAnimation.value, pulsePaint);
  }

  void _drawTimeInfo(Canvas canvas, Offset center, double radius) {
    // Información de tiempo en cada posición
    final upTime = _formatDuration(counter.timeInUpPosition);
    final downTime = _formatDuration(counter.timeInDownPosition);

    // Tiempo arriba (izquierda)
    _drawTimeBox(
      canvas,
      Offset(center.dx - radius - 60, center.dy - 40),
      l10n.phaseUp,
      upTime,
      AppColors.successGreen,
    );

    // Tiempo abajo (derecha)
    _drawTimeBox(
      canvas,
      Offset(center.dx + radius + 20, center.dy + 20),
      l10n.phaseDown,
      downTime,
      AppColors.primaryCyan,
    );
  }

  void _drawTimeBox(
      Canvas canvas, Offset position, String label, String time, Color color) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(position.dx, position.dy, 80, 50),
      const Radius.circular(8),
    );

    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, paint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, borderPaint);

    // Texto del label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(position.dx + 8, position.dy + 6));

    // Texto del tiempo
    final timePainter = TextPainter(
      text: TextSpan(
        text: time,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    timePainter.layout();
    timePainter.paint(canvas, Offset(position.dx + 8, position.dy + 22));
  }

  void _drawPhaseStats(Canvas canvas, Offset center, double radius) {
    // ROM actual
    final romText = 'ROM: ${(counter.currentROM * 100).toStringAsFixed(0)}%';
    final romPainter = TextPainter(
      text: TextSpan(
        text: romText,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    romPainter.layout();
    romPainter.paint(canvas, Offset(center.dx - 30, center.dy + radius + 20));

    // Fase actual
    final phaseText = _getPhaseText(counter.currentPhase);
    final phasePainter = TextPainter(
      text: TextSpan(
        text: phaseText,
        style: TextStyle(
          color: _getPhaseColor(counter.currentPhase),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    phasePainter.layout();
    phasePainter.paint(canvas, Offset(center.dx - 25, center.dy + radius + 40));
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  String _getPhaseText(PullUpPhase phase) {
    switch (phase) {
      case PullUpPhase.up:
        return '↑ ${l10n.phaseRising}';
      case PullUpPhase.down:
        return '↓ ${l10n.phaseLowering}';
      case PullUpPhase.transition:
        return '~ ${l10n.phaseTransition}';
    }
  }

  Color _getPhaseColor(PullUpPhase phase) {
    switch (phase) {
      case PullUpPhase.up:
        return AppColors.successGreen;
      case PullUpPhase.down:
        return AppColors.primaryCyan;
      case PullUpPhase.transition:
        return Colors.orange;
    }
  }

  @override
  bool shouldRepaint(PullUpProgressPainter oldDelegate) {
    return oldDelegate.currentHeadHeight != currentHeadHeight ||
        oldDelegate.counter.currentPhase != counter.currentPhase ||
        oldDelegate.pulseAnimation.value != pulseAnimation.value ||
        oldDelegate.progressAnimation.value != progressAnimation.value;
  }
}
