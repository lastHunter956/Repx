import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/pose_keypoint.dart';
import 'app_colors.dart';

/// Utilidades para dibujar elementos visuales sobre la detección de pose
class DrawingUtils {
  // Colores del tema
  static const Color primaryColor = AppColors.primaryCyan;
  static const Color secondaryColor = AppColors.primaryPurple;
  static const Color accentColor = AppColors.primaryCyan;
  static const Color correctColor = AppColors.successGreen;
  static const Color errorColor = AppColors.errorPink;
  static const Color warningColor = AppColors.warningYellow;

  /// Dibuja el skeleton sobre la imagen
  static void drawSkeleton(
    Canvas canvas,
    Size size,
    PoseDetection pose, {
    bool showCorrectForm = true,
    Map<String, double>? angles,
  }) {
    // Contar keypoints válidos (umbral ligeramente permisivo)
    final validKeypoints = pose.keypoints.where((k) => k.isValid).toList();

    // Si no hay keypoints totalmente válidos, intentar fallback con confidencias bajas
    if (validKeypoints.isEmpty) {
      // Fallback: usar puntos con confianza mínima razonable (0.18)
      final fallback =
          pose.keypoints.where((k) => k.confidence >= 0.18).toList();
      if (fallback.isEmpty) {
        return; // No hay nada que dibujar
      }

      // Dibujar puntos sueltos (poca opacidad) para dar feedback visual
      final paintFallback = Paint()..style = PaintingStyle.fill;
      for (final keypoint in fallback) {
        final p = transformCoordinate(keypoint, size.width, size.height);
        paintFallback.color = AppColors.primaryCyan.withOpacity(0.25);
        canvas.drawCircle(p, 6.0, paintFallback);
      }

      // No intentamos dibujar conexiones en el fallback
      return;
    }

    // 🎯 PRECISIÓN MILITAR: Transformación matricial 2D directa
    // Cámara frontal landscape (sensorOrientation=270°):
    //   - MediaPipe: coordenadas (0,0) = top-left de imagen capturada
    //   - Canvas: necesita rotar -90° para vista landscape
    //
    // MATRIZ DE TRANSFORMACIÓN (SIN ESPEJO):
    //   1. Rotar -90° (counterclockwise) → swapea X,Y
    //   Resultado: (x', y') = (size.height * y, size.width * x)
    canvas.save();

    // NO aplicar transformaciones canvas (causan pérdida de precisión)
    // Usaremos mapeo directo en cada punto
    final displayWidth = size.width; // Ancho del canvas (portrait)
    final displayHeight = size.height; // Alto del canvas (portrait)

    // 🎯 Paint con anti-aliasing para sub-pixel precision
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 🎯 FUNCIÓN DE TRANSFORMACIÓN PIXEL-PERFECT (ahora pública via helper)
    Offset transformPoint(PoseKeypoint point) =>
        transformCoordinate(point, displayWidth, displayHeight);

    // Definir conexiones del skeleton completo - MUÑECO DE PALITOS
    final connections = [
      // CABEZA - Conectar ojos y nariz
      ['left_eye', 'right_eye'],
      ['left_eye', 'nose'],
      ['right_eye', 'nose'],

      // CUELLO - Conectar cabeza con hombros
      ['nose', 'left_shoulder'],
      ['nose', 'right_shoulder'],

      // BRAZOS COMPLETOS
      ['left_shoulder', 'left_elbow'],
      ['left_elbow', 'left_wrist'],
      ['right_shoulder', 'right_elbow'],
      ['right_elbow', 'right_wrist'],

      // TORSO - Línea de hombros y conexiones a caderas
      ['left_shoulder', 'right_shoulder'],
      ['left_shoulder', 'left_hip'],
      ['right_shoulder', 'right_hip'],

      // PELVIS - Línea de caderas
      ['left_hip', 'right_hip'],

      // PIERNAS COMPLETAS
      ['left_hip', 'left_knee'],
      ['left_knee', 'left_ankle'],
      ['right_hip', 'right_knee'],
      ['right_knee', 'right_ankle'],
    ];

    // Dibujar conexiones con sombras para profundidad
    for (final connection in connections) {
      final point1 = pose.getKeypoint(connection[0]);
      final point2 = pose.getKeypoint(connection[1]);

      // ✅ SOLO dibujar si AMBOS puntos tienen buena confianza (>40%)
      if (point1 != null &&
          point2 != null &&
          point1.isValid &&
          point2.isValid &&
          // Umbral de confianza algo más permisivo para evitar líneas intermitentes
          point1.confidence > 0.25 &&
          point2.confidence > 0.25) {
        // 🎯 Transformación pixel-perfect
        final p1 = transformPoint(point1);
        final p2 = transformPoint(point2);

        // Determinar color según la parte del cuerpo
        Color lineColor = AppColors.primaryCyan;

        if (showCorrectForm && angles != null) {
          lineColor = _getLineColor(connection, angles);
        }

        // Sombra de la línea
        paint.color = Colors.black.withOpacity(0.4);
        paint.strokeWidth = 5.0;
        canvas.drawLine(
          p1.translate(1, 1),
          p2.translate(1, 1),
          paint,
        );

        // Línea principal con gradiente
        paint.color = lineColor;
        paint.strokeWidth = 4.0;
        canvas.drawLine(p1, p2, paint);
      }
    }

    // Dibujar CABEZA como círculo
    _drawHead(canvas, size, pose);

    // Dibujar keypoints (articulaciones)
    _drawKeypoints(canvas, size, pose, showCorrectForm, angles);

    // ✅ RESTAURAR canvas a estado original
    canvas.restore();
  }

  /// Dibuja la cabeza como un círculo
  static void _drawHead(
    Canvas canvas,
    Size size,
    PoseDetection pose,
  ) {
    final nose = pose.getKeypoint('nose');
    final leftEye = pose.getKeypoint('left_eye');
    final rightEye = pose.getKeypoint('right_eye');

    // Solo dibujar cabeza si los 3 puntos tienen BUENA confianza
    if (nose != null &&
        nose.isValid &&
        nose.confidence > 0.5 &&
        leftEye != null &&
        leftEye.isValid &&
        leftEye.confidence > 0.5 &&
        rightEye != null &&
        rightEye.isValid &&
        rightEye.confidence > 0.5) {
      // 🎯 Transformación pixel-perfect (consistente con drawSkeleton)
      final displayWidth = size.width;
      final displayHeight = size.height;

      Offset transformPoint(PoseKeypoint point) =>
          transformCoordinate(point, displayWidth, displayHeight);

      final nosePos = transformPoint(nose);
      final leftEyePos = transformPoint(leftEye);
      final rightEyePos = transformPoint(rightEye);

      // Centro de cabeza (promedio geométrico exacto)
      final centerX = (nosePos.dx + leftEyePos.dx + rightEyePos.dx) / 3.0;
      final centerY = (nosePos.dy + leftEyePos.dy + rightEyePos.dy) / 3.0;
      final center = Offset(centerX, centerY);

      // Radio basado en distancia euclidiana entre ojos
      final eyeDistance = (leftEyePos - rightEyePos).distance;
      final headRadius = eyeDistance * 0.8;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = AppColors.primaryCyan;

      // Sombra del círculo
      paint.color = Colors.black.withOpacity(0.4);
      paint.strokeWidth = 4.0;
      canvas.drawCircle(center.translate(1, 1), headRadius, paint);

      // Círculo principal de la cabeza
      paint.color = AppColors.primaryCyan;
      paint.strokeWidth = 3.5;
      canvas.drawCircle(center, headRadius, paint);
    }
  }

  /// Dibuja los keypoints como círculos
  static void _drawKeypoints(
    Canvas canvas,
    Size size,
    PoseDetection pose,
    bool showCorrectForm,
    Map<String, double>? angles,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 🎯 Función de transformación local (consistente con drawSkeleton)
    final displayWidth = size.width;
    final displayHeight = size.height;

    Offset transformPoint(PoseKeypoint point) =>
        transformCoordinate(point, displayWidth, displayHeight);

    // Solo dibujar articulaciones principales (no todos los keypoints)
    final mainJoints = [
      'left_shoulder',
      'right_shoulder',
      'left_elbow',
      'right_elbow',
      'left_wrist',
      'right_wrist',
      'left_hip',
      'right_hip',
      'left_knee',
      'right_knee',
      'left_ankle',
      'right_ankle',
    ];

    for (final keypoint in pose.keypoints) {
      // Solo mostrar articulaciones principales con confianza razonable
      if (!mainJoints.contains(keypoint.name)) continue;
      if (keypoint.confidence < 0.25) {
        continue; // Umbral adaptado: mostrará puntos con confianza moderada
      }

      // 🎯 Transformación pixel-perfect
      final center = transformPoint(keypoint);

      // Color basado en confianza
      Color color = AppColors.primaryCyan;
      if (keypoint.confidence > 0.7) {
        color =
            showCorrectForm ? AppColors.successGreen : AppColors.primaryCyan;
      } else if (keypoint.confidence > 0.5) {
        color = AppColors.warningYellow;
      } else {
        color = AppColors.errorPink.withOpacity(0.6);
      }

      // 🎯 INDICADOR DE PRECISIÓN MILITAR
      // Sombra para profundidad
      paint.color = Colors.black.withOpacity(0.5);
      canvas.drawCircle(center.translate(0.5, 0.5), 9.0, paint);

      // Círculo exterior (borde)
      paint.color = Colors.white;
      canvas.drawCircle(center, 8.5, paint);

      // Círculo principal (color según confianza)
      paint.color = color;
      canvas.drawCircle(center, 7.5, paint);

      // Cruz central de precisión (marca exacta de articulación)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.5;
      paint.color = Colors.white.withOpacity(0.9);
      canvas.drawLine(
        center.translate(-3, 0),
        center.translate(3, 0),
        paint,
      );
      canvas.drawLine(
        center.translate(0, -3),
        center.translate(0, 3),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }
  }

  /// Determina el color de la línea según la conexión y los ángulos
  static Color _getLineColor(
    List<String> connection,
    Map<String, double> angles,
  ) {
    // Brazos - verificar ángulos de codos
    if (connection.contains('elbow')) {
      final side = connection[0].startsWith('left') ? 'left' : 'right';
      final elbowAngle = angles['${side}_elbow'];

      if (elbowAngle != null) {
        // Verde si está en rango correcto para cualquier fase
        if ((elbowAngle >= 160 && elbowAngle <= 180) ||
            (elbowAngle >= 40 && elbowAngle <= 90)) {
          return correctColor;
        }
        return warningColor;
      }
    }

    // Espalda - verificar ángulo de espalda
    if (connection.contains('shoulder') && connection.contains('hip')) {
      final side = connection[0].startsWith('left') ? 'left' : 'right';
      final backAngle = angles['${side}_back'];

      if (backAngle != null) {
        if (backAngle >= 160 && backAngle <= 180) {
          return correctColor;
        }
        return errorColor;
      }
    }

    return accentColor;
  }

  /// Dibuja indicadores de ángulo sobre las articulaciones
  ///
  /// IMPORTANTE: [position] debe estar en coordenadas de CANVAS transformadas,
  /// NO en coordenadas normalizadas de MediaPipe. Usar transformPoint() antes de llamar.
  static void drawAngleIndicator(
    Canvas canvas,
    Size size,
    Offset position, // YA TRANSFORMADO a coordenadas de canvas
    double angle,
    String label,
  ) {
    // Background glass circle
    final circlePaint = Paint()
      ..color = AppColors.cardBg.withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(position, 28, circlePaint);

    // Border glow
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(position, 28, glowPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${angle.toStringAsFixed(0)}°',
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(blurRadius: 8.0, color: primaryColor.withOpacity(0.8)),
            Shadow(blurRadius: 4.0, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
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

  /// Crea un gradiente para el fondo de la app
  static LinearGradient createAppGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );
  }

  /// Crea un color basado en la calidad de forma (0-100)
  static Color getQualityColor(double quality) {
    if (quality >= 80) return correctColor;
    if (quality >= 60) return accentColor;
    if (quality >= 40) return warningColor;
    return errorColor;
  }

  /// 🎯 MÉTODO HELPER PÚBLICO: Transformación de coordenadas MediaPipe → Canvas
  ///
  /// Convierte coordenadas normalizadas (0-1) de MediaPipe a coordenadas de canvas
  /// teniendo en cuenta la rotación de cámara frontal en landscape (270°).
  ///
  /// Parámetros:
  /// - [keypoint]: PoseKeypoint con coordenadas normalizadas (x,y ∈ [0,1])
  /// - [canvasWidth]: Ancho del canvas de dibujo
  /// - [canvasHeight]: Alto del canvas de dibujo
  ///
  /// Retorna: Offset con coordenadas transformadas listas para dibujar
  ///
  /// USO:
  /// ```dart
  /// final screenPos = DrawingUtils.transformCoordinate(
  ///   leftElbow,
  ///   size.width,
  ///   size.height
  /// );
  /// canvas.drawCircle(screenPos, 10, paint);
  /// ```
  static Offset transformCoordinate(
    PoseKeypoint keypoint,
    double canvasWidth,
    double canvasHeight,
  ) {
    // ✅ CORREGIDO: Transformación para landscape frontal SIN ESPEJO
    // Solo rotar -90° (counterclockwise) para que skeleton coincida con usuario
    //   x_display = height * y_mediapipe         [rotar -90°]
    //   y_display = width * x_mediapipe          [rotar -90°]
    //
    // ANTES: Tenía (1 - y) que causaba inversión horizontal (efecto espejo)
    final x = canvasHeight * keypoint.y; // SIN inversión
    final y = canvasWidth * keypoint.x;
    return Offset(x, y);
  }

  /// Dibuja una barra de progreso de calidad
  static void drawQualityBar(
    Canvas canvas,
    Size size,
    double quality, {
    Offset? position,
  }) {
    final barPosition = position ?? Offset(20, size.height - 60);
    final barWidth = size.width - 40;
    final barHeight = 35.0;

    // Glassmorphism background con blur
    final bgPaint = Paint()
      ..color = AppColors.cardBg.withOpacity(0.7)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Borde glass effect
    final borderPaint = Paint()
      ..color = AppColors.glassWhite
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barPosition.dx, barPosition.dy, barWidth, barHeight),
      const Radius.circular(20),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Barra de progreso con gradiente premium
    final progressWidth = (quality / 100) * (barWidth - 4);
    final progressPaint = Paint()
      ..shader = ui.Gradient.linear(
        barPosition,
        Offset(barPosition.dx + barWidth, barPosition.dy),
        quality > 80
            ? [correctColor, Color(0xFF00FFA3)]
            : quality > 50
                ? [warningColor, Color(0xFFFFE55C)]
                : [errorColor, Color(0xFFFF0080)],
      )
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barPosition.dx + 2, barPosition.dy + 2, progressWidth,
            barHeight - 4),
        const Radius.circular(18),
      ),
      progressPaint,
    );

    // Texto de porcentaje
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${quality.toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        barPosition.dx + barWidth / 2 - textPainter.width / 2,
        barPosition.dy + barHeight / 2 - textPainter.height / 2,
      ),
    );
  }
}
