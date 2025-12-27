import 'package:flutter/foundation.dart';
import '../models/pose_keypoint.dart';
import '../utils/angle_calculator.dart';
import '../utils/pose_validator.dart';

/// Resultado del análisis de pose
class PoseAnalysisResult {
  final Map<String, double> angles; // Ángulos calculados
  final PoseValidationResult validation; // Validación de la pose
  final bool isUpPosition; // Si está en posición arriba
  final bool isDownPosition; // Si está en posición abajo
  final String feedback; // Mensaje de feedback

  PoseAnalysisResult({
    required this.angles,
    required this.validation,
    required this.isUpPosition,
    required this.isDownPosition,
    required this.feedback,
  });

  @override
  String toString() {
    return 'PoseAnalysis(up: $isUpPosition, down: $isDownPosition, quality: ${validation.formQuality.toStringAsFixed(1)}%)';
  }
}

/// Servicio para analizar poses detectadas
class PoseAnalyzer {
  // Historial de poses para suavizado temporal
  final List<PoseDetection> _poseHistory = [];
  // Mantener pocas poses para suavizado y evitar trabajo excesivo
  static const int maxHistorySize = 5;

  /// Analiza una pose detectada
  ///
  /// Parámetros:
  /// - [pose]: Pose detectada por YOLO
  ///
  /// Retorna: Resultado del análisis con ángulos, validación y feedback
  Future<PoseAnalysisResult> analyzePose(PoseDetection pose) async {
    // Agregar a historial
    _poseHistory.add(pose);
    if (_poseHistory.length > maxHistorySize) {
      _poseHistory.removeAt(0);
    }

    // Calcular ángulos en un Isolate para evitar bloquear el hilo UI
    final angles = await compute(_computeAngles, pose.toJson());

    // Determinar posición (arriba o abajo)
    final isUp = _isUpPosition(angles);
    final isDown = _isDownPosition(angles);

    // DEBUG: Mostrar detección de fases solo en modo debug
    final avgElbow = angles['avg_elbow'];
    if (avgElbow != null) {
      // Use kDebugMode to avoid logging in release builds
      // Import deferred to avoid extra overhead in release
      // (we keep prints minimal)
      // ignore: avoid_print
      if (isUp) print('PoseAnalyzer: ARRIBA (${avgElbow.toStringAsFixed(1)}°)');
      // ignore: avoid_print
      if (isDown) {
        print('PoseAnalyzer: ABAJO (${avgElbow.toStringAsFixed(1)}°)');
      }
    }

    // Validar pose según posición
    PoseValidationResult validation;
    if (isUp) {
      validation = PoseValidator.validateUpPosition(pose);
    } else if (isDown) {
      validation = PoseValidator.validateDownPosition(pose);
    } else {
      // Posición de transición
      validation = PoseValidationResult(
        isValid: false,
        formQuality: 50.0,
        errors: ['En transición...'],
      );
    }

    // Generar feedback
    final feedback = PoseValidator.getFeedbackMessage(validation.errors);

    return PoseAnalysisResult(
      angles: angles,
      validation: validation,
      isUpPosition: isUp,
      isDownPosition: isDown,
      feedback: feedback,
    );
  }

  /// Calcula todos los ángulos relevantes de la pose
  Map<String, double> _calculateAngles(PoseDetection pose) {
    final angles = <String, double>{};

    // Evitar logs frecuentes en producción; dejar un log ligero para debug
    // ignore: avoid_print
    // print('PoseAnalyzer: _calculateAngles received ${pose.keypoints.length} keypoints');

    // Ángulos de codos
    final leftElbow = AngleCalculator.calculateElbowAngle(pose, 'left');
    final rightElbow = AngleCalculator.calculateElbowAngle(pose, 'right');

    if (leftElbow != null) angles['left_elbow'] = leftElbow;
    if (rightElbow != null) angles['right_elbow'] = rightElbow;

    // Promedio de codos
    final avgElbow = AngleCalculator.calculateAverageAngle(
      leftElbow,
      rightElbow,
    );
    if (avgElbow != null) {
      angles['avg_elbow'] = avgElbow;
    }

    // Ángulos de espalda
    final leftBack = AngleCalculator.calculateBackAngle(pose, 'left');
    final rightBack = AngleCalculator.calculateBackAngle(pose, 'right');

    if (leftBack != null) angles['left_back'] = leftBack;
    if (rightBack != null) angles['right_back'] = rightBack;

    // Promedio de espalda
    final avgBack = AngleCalculator.calculateAverageAngle(leftBack, rightBack);
    if (avgBack != null) angles['avg_back'] = avgBack;

    return angles;
  }

  /// Función ejecutada en un Isolate vía `compute`.
  /// Recibe la representación JSON de una `PoseDetection` y retorna
  /// un mapa con los ángulos calculados.
  Map<String, double> _computeAngles(Map<String, dynamic> poseJson) {
    final pose = PoseDetection.fromJson(poseJson);
    final angles = <String, double>{};

    final leftElbow = AngleCalculator.calculateElbowAngle(pose, 'left');
    final rightElbow = AngleCalculator.calculateElbowAngle(pose, 'right');

    if (leftElbow != null) angles['left_elbow'] = leftElbow;
    if (rightElbow != null) angles['right_elbow'] = rightElbow;

    final avgElbow = AngleCalculator.calculateAverageAngle(
      leftElbow,
      rightElbow,
    );
    if (avgElbow != null) angles['avg_elbow'] = avgElbow;

    final leftBack = AngleCalculator.calculateBackAngle(pose, 'left');
    final rightBack = AngleCalculator.calculateBackAngle(pose, 'right');

    if (leftBack != null) angles['left_back'] = leftBack;
    if (rightBack != null) angles['right_back'] = rightBack;

    final avgBack = AngleCalculator.calculateAverageAngle(leftBack, rightBack);
    if (avgBack != null) angles['avg_back'] = avgBack;

    return angles;
  }

  /// Determina si la pose está en posición "arriba" (brazos extendidos)
  bool _isUpPosition(Map<String, double> angles) {
    final avgElbow = angles['avg_elbow'];
    if (avgElbow == null) return false;

    // Brazos extendidos: ángulo >= 140° (AJUSTADO - más permisivo)
    // Rango real observado: 140-180° es brazo extendido
    return avgElbow >= 140.0;
  }

  /// Determina si la pose está en posición "abajo" (brazos flexionados)
  bool _isDownPosition(Map<String, double> angles) {
    final avgElbow = angles['avg_elbow'];
    if (avgElbow == null) return false;

    // Brazos flexionados: ángulo de codo <= maxElbowAngleDown (ahora 120°)
    return avgElbow <= PoseValidator.maxElbowAngleDown;
  }

  /// Obtiene el promedio de calidad de forma del historial reciente
  double getAverageFormQuality() {
    if (_poseHistory.isEmpty) return 0.0;

    double totalQuality = 0.0;
    int validCount = 0;

    // Evitar llamar a analyzePose para no reinsertar en el historial ni
    // realizar trabajo adicional; en su lugar calcular ángulos y validar
    // de forma ligera por pose.
    for (final pose in _poseHistory) {
      final angles = _calculateAngles(pose);
      final isUp = _isUpPosition(angles);
      final isDown = _isDownPosition(angles);

      PoseValidationResult validation;
      if (isUp) {
        validation = PoseValidator.validateUpPosition(pose);
      } else if (isDown) {
        validation = PoseValidator.validateDownPosition(pose);
      } else {
        validation = PoseValidationResult(
          isValid: false,
          formQuality: 50.0,
          errors: ['En transición...'],
        );
      }

      totalQuality += validation.formQuality;
      validCount++;
    }

    return validCount > 0 ? totalQuality / validCount : 0.0;
  }

  /// Verifica si la pose es estable (sin cambios bruscos)
  bool isPoseStable() {
    if (_poseHistory.length < 3) return false;

    // Comparar las últimas 3 poses
    final recent = _poseHistory.sublist(_poseHistory.length - 3);

    // Calcular variación de confianza
    double minConfidence = 1.0;
    double maxConfidence = 0.0;

    for (final pose in recent) {
      if (pose.overallConfidence < minConfidence) {
        minConfidence = pose.overallConfidence;
      }
      if (pose.overallConfidence > maxConfidence) {
        maxConfidence = pose.overallConfidence;
      }
    }

    // Considerar estable si la variación es pequeña
    return (maxConfidence - minConfidence) < 0.2;
  }

  /// Obtiene la pose promedio del historial (suavizado)
  PoseDetection? getSmoothedPose() {
    if (_poseHistory.isEmpty) return null;
    if (_poseHistory.length == 1) return _poseHistory.first;

    // Usar las últimas 3 poses para suavizado
    final recentPoses = _poseHistory.length >= 3
        ? _poseHistory.sublist(_poseHistory.length - 3)
        : _poseHistory;

    // Promediar keypoints
    final smoothedKeypoints = <PoseKeypoint>[];

    for (int i = 0; i < recentPoses.first.keypoints.length; i++) {
      double sumX = 0.0;
      double sumY = 0.0;
      double sumConf = 0.0;
      int count = 0;

      for (final pose in recentPoses) {
        if (i < pose.keypoints.length) {
          final kp = pose.keypoints[i];
          sumX += kp.x;
          sumY += kp.y;
          sumConf += kp.confidence;
          count++;
        }
      }

      if (count > 0) {
        smoothedKeypoints.add(
          PoseKeypoint(
            name: recentPoses.first.keypoints[i].name,
            x: sumX / count,
            y: sumY / count,
            confidence: sumConf / count,
          ),
        );
      }
    }

    // Calcular confianza promedio
    double avgConfidence = 0.0;
    for (final pose in recentPoses) {
      avgConfidence += pose.overallConfidence;
    }
    avgConfidence /= recentPoses.length;

    return PoseDetection(
      keypoints: smoothedKeypoints,
      overallConfidence: avgConfidence,
    );
  }

  /// Limpia el historial de poses
  void clearHistory() {
    _poseHistory.clear();
  }

  /// Obtiene estadísticas del historial
  Map<String, dynamic> getHistoryStats() {
    if (_poseHistory.isEmpty) {
      return {'count': 0, 'avgConfidence': 0.0, 'isStable': false};
    }

    double totalConf = 0.0;
    for (final pose in _poseHistory) {
      totalConf += pose.overallConfidence;
    }

    return {
      'count': _poseHistory.length,
      'avgConfidence': totalConf / _poseHistory.length,
      'isStable': isPoseStable(),
    };
  }
}

