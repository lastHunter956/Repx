import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../models/pose_keypoint.dart';
import '../utils/drawing_utils.dart';

/// Widget para mostrar la vista previa de la cámara con overlay de skeleton
///
/// IMPORTANTE: Usa transformación de coordenadas consistente en todos los elementos
/// visuales (skeleton, ángulos, indicadores) para evitar desalineación.
class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final PoseDetection? currentPose;
  final Map<String, double> angles;
  final double formQuality;
  final bool showSkeleton;
  final bool showAngles;
  final bool showQualityBar;
  
  /// Aspect ratio de la imagen de la cámara (width/height)
  /// Usado para compensar diferencias de aspect ratio en la transformación de skeleton
  final double? cameraAspectRatio;

  const CameraPreviewWidget({
    super.key,
    this.controller,
    this.currentPose,
    this.angles = const {},
    this.formQuality = 0.0,
    this.showSkeleton = true,
    this.showAngles = true,
    this.showQualityBar = true,
    this.cameraAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: DrawingUtils.accentColor),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular aspect ratios para compensación en transformación
          final previewSize = controller!.value.previewSize;
          final cameraAspect = previewSize != null 
              ? previewSize.height / previewSize.width  // Rotado para landscape
              : 4.0 / 3.0;  // Default 4:3
          final screenAspect = constraints.maxWidth / constraints.maxHeight;
          
          return Stack(
            fit: StackFit.expand,
            children: [
              // Vista previa de cámara (llena todo el espacio)
              CameraPreview(controller!),

              // Overlay de skeleton y pose
              if (currentPose != null)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _PoseOverlayPainter(
                      pose: currentPose!,
                      angles: angles,
                      formQuality: formQuality,
                      showAngles: showAngles && showSkeleton,
                      showQualityBar: showQualityBar,
                      showSkeleton: showSkeleton,
                      cameraAspectRatio: cameraAspect,
                      screenAspectRatio: screenAspect,
                    ),
                  ),
                ),

              // Marco decorativo
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DrawingUtils.accentColor.withOpacity(0.5),
                    width: 3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Painter personalizado para dibujar el skeleton y overlays
class _PoseOverlayPainter extends CustomPainter {
  final PoseDetection pose;
  final Map<String, double> angles;
  final double formQuality;
  final bool showAngles;
  final bool showQualityBar;
  final bool showSkeleton;
  final double? cameraAspectRatio;
  final double? screenAspectRatio;

  _PoseOverlayPainter({
    required this.pose,
    required this.angles,
    required this.formQuality,
    this.showAngles = true,
    this.showQualityBar = true,
    this.showSkeleton = true,
    this.cameraAspectRatio,
    this.screenAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // DEBUG: Verificar que estamos dibujando (solo en modo debug)
    if (kDebugMode) {
      // ignore: avoid_print
      print('🎨 Dibujando skeleton en canvas ${size.width}x${size.height}');
      // ignore: avoid_print
      print(
          '   Keypoints: ${pose.keypoints.length}, Válidos: ${pose.keypoints.where((k) => k.isValid).length}');
    }

    // Dibujar skeleton si está habilitado
    if (showSkeleton) {
      DrawingUtils.drawSkeleton(
        canvas,
        size,
        pose,
        showCorrectForm: true,
        angles: angles,
        cameraAspectRatio: cameraAspectRatio,
        screenAspectRatio: screenAspectRatio,
      );
    }

    // Dibujar indicadores de ángulos si está habilitado
    if (showAngles) {
      _drawAngleIndicators(canvas, size);
    }

    // Dibujar barra de calidad si está habilitada
    if (showQualityBar) {
      DrawingUtils.drawQualityBar(canvas, size, formQuality);
    }
  }

  void _drawAngleIndicators(Canvas canvas, Size size) {
    // 🎯 TRANSFORMACIÓN CONSISTENTE: Usar misma lógica que skeleton
    final displayWidth = size.width;
    final displayHeight = size.height;

    // Usar helper público para transformar coordenadas (consistente con aspect ratio)
    Offset transformPoint(PoseKeypoint point) =>
        DrawingUtils.transformCoordinate(
          point, 
          displayWidth, 
          displayHeight,
          cameraAspectRatio: cameraAspectRatio,
          screenAspectRatio: screenAspectRatio,
        );

    // Ángulo de codo izquierdo
    final leftElbow = pose.getKeypoint('left_elbow');
    if (leftElbow != null && leftElbow.isValid) {
      final angle = angles['left_elbow'];
      if (angle != null) {
        DrawingUtils.drawAngleIndicator(
          canvas,
          size,
          transformPoint(leftElbow), // ✅ TRANSFORMADO
          angle,
          'L',
        );
      }
    }

    // Ángulo de codo derecho
    final rightElbow = pose.getKeypoint('right_elbow');
    if (rightElbow != null && rightElbow.isValid) {
      final angle = angles['right_elbow'];
      if (angle != null) {
        DrawingUtils.drawAngleIndicator(
          canvas,
          size,
          transformPoint(rightElbow), // ✅ TRANSFORMADO
          angle,
          'R',
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PoseOverlayPainter oldDelegate) {
    return pose != oldDelegate.pose ||
        angles != oldDelegate.angles ||
        formQuality != oldDelegate.formQuality ||
        showAngles != oldDelegate.showAngles ||
        showQualityBar != oldDelegate.showQualityBar ||
        cameraAspectRatio != oldDelegate.cameraAspectRatio ||
        screenAspectRatio != oldDelegate.screenAspectRatio;
  }
}

