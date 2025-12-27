import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../models/pose_keypoint.dart';

/// Estados de fase de una sentadilla
enum SquatPhase {
  /// Posición arriba (piernas extendidas)
  up,

  /// Posición abajo (piernas flexionadas)
  down,

  /// En transición entre posiciones
  transition,
}

/// Contador de sentadillas con validación de forma
/// 
/// Detecta sentadillas analizando el ángulo de las rodillas
/// y la posición de las caderas respecto a las rodillas.
class SquatCounter extends ChangeNotifier {
  // === Estado del contador ===
  int _count = 0;
  int get count => _count;

  SquatPhase _currentPhase = SquatPhase.up;
  SquatPhase get currentPhase => _currentPhase;

  double _formQuality = 0.0;
  double get formQuality => _formQuality;

  bool _isActive = false;
  bool get isActive => _isActive;

  // === Historial de calidad para promedios ===
  final List<double> _qualityHistory = [];
  static const int _qualityHistorySize = 30;

  // === Umbrales de detección ===
  /// Ángulo mínimo de rodilla para posición "abajo" (grados)
  static const double _downAngleThreshold = 110.0;

  /// Ángulo máximo de rodilla para posición "arriba" (grados)
  static const double _upAngleThreshold = 160.0;

  /// Frames mínimos en cada posición para validar rep
  static const int _minFramesInPosition = 3;

  // === Tracking de posición ===
  int _framesInDown = 0;
  int _framesInUp = 0;
  bool _wasDown = false;

  // === Tracking de ángulos actuales ===
  double _leftKneeAngle = 180.0;
  double _rightKneeAngle = 180.0;

  double get leftKneeAngle => _leftKneeAngle;
  double get rightKneeAngle => _rightKneeAngle;
  double get averageKneeAngle => (_leftKneeAngle + _rightKneeAngle) / 2;

  /// Inicia el contador
  void start() {
    _isActive = true;
    reset();
    notifyListeners();
  }

  /// Detiene el contador
  void stop() {
    _isActive = false;
    notifyListeners();
  }

  /// Reinicia el contador
  void reset() {
    _count = 0;
    _currentPhase = SquatPhase.up;
    _formQuality = 0.0;
    _qualityHistory.clear();
    _framesInDown = 0;
    _framesInUp = 0;
    _wasDown = false;
    _leftKneeAngle = 180.0;
    _rightKneeAngle = 180.0;
    notifyListeners();
  }

  /// Procesa una pose detectada
  void processPose(PoseDetection pose) {
    if (!_isActive) return;

    // Obtener keypoints necesarios
    final leftHip = pose.getKeypoint('left_hip');
    final rightHip = pose.getKeypoint('right_hip');
    final leftKnee = pose.getKeypoint('left_knee');
    final rightKnee = pose.getKeypoint('right_knee');
    final leftAnkle = pose.getKeypoint('left_ankle');
    final rightAnkle = pose.getKeypoint('right_ankle');

    // Verificar keypoints válidos
    if (!_areKeypointsValid([leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle])) {
      return;
    }

    // Calcular ángulos de rodillas
    _leftKneeAngle = _calculateAngle(leftHip!, leftKnee!, leftAnkle!);
    _rightKneeAngle = _calculateAngle(rightHip!, rightKnee!, rightAnkle!);

    // Determinar fase actual
    final avgAngle = averageKneeAngle;
    final previousPhase = _currentPhase;

    if (avgAngle <= _downAngleThreshold) {
      _currentPhase = SquatPhase.down;
      _framesInDown++;
      _framesInUp = 0;
    } else if (avgAngle >= _upAngleThreshold) {
      _currentPhase = SquatPhase.up;
      _framesInUp++;
      _framesInDown = 0;
    } else {
      _currentPhase = SquatPhase.transition;
    }

    // Detectar repetición completada (down → up)
    if (_wasDown && 
        _currentPhase == SquatPhase.up && 
        _framesInUp >= _minFramesInPosition) {
      _count++;
      _wasDown = false;

      // Calcular calidad de la repetición
      final quality = _calculateRepQuality(pose);
      _addQualityToHistory(quality);

      if (kDebugMode) {
        print('🦵 Sentadilla #$_count! Calidad: ${(quality * 100).toStringAsFixed(0)}%');
      }
    }

    // Marcar que estuvo abajo
    if (_currentPhase == SquatPhase.down && _framesInDown >= _minFramesInPosition) {
      _wasDown = true;
    }

    // Actualizar calidad promedio
    _updateAverageQuality();

    if (previousPhase != _currentPhase) {
      notifyListeners();
    }
  }

  /// Verifica si los keypoints son válidos
  bool _areKeypointsValid(List<PoseKeypoint?> keypoints) {
    return keypoints.every((kp) => kp != null && kp.isValid);
  }

  /// Calcula el ángulo entre tres puntos (en grados)
  double _calculateAngle(PoseKeypoint a, PoseKeypoint b, PoseKeypoint c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) -
        math.atan2(a.y - b.y, a.x - b.x);
    var angle = radians * 180 / math.pi;
    angle = angle.abs();
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  /// Calcula la calidad de una repetición
  double _calculateRepQuality(PoseDetection pose) {
    double quality = 1.0;

    // Factor 1: Profundidad de la sentadilla (40%)
    final depthScore = _calculateDepthScore();
    quality *= 0.4 + (depthScore * 0.6);

    // Factor 2: Simetría de rodillas (30%)
    final symmetryScore = _calculateSymmetryScore();
    quality *= 0.4 + (symmetryScore * 0.6);

    // Factor 3: Posición de rodillas vs pies (30%)
    final alignmentScore = _calculateAlignmentScore(pose);
    quality *= 0.4 + (alignmentScore * 0.6);

    return quality.clamp(0.0, 1.0);
  }

  /// Calcula puntuación de profundidad
  double _calculateDepthScore() {
    // Mejor profundidad = menor ángulo
    final avgAngle = averageKneeAngle;
    if (avgAngle <= 90) return 1.0; // Excelente
    if (avgAngle <= 100) return 0.9;
    if (avgAngle <= 110) return 0.8;
    if (avgAngle <= 120) return 0.6;
    return 0.4;
  }

  /// Calcula puntuación de simetría
  double _calculateSymmetryScore() {
    final difference = (_leftKneeAngle - _rightKneeAngle).abs();
    if (difference <= 5) return 1.0;
    if (difference <= 10) return 0.9;
    if (difference <= 15) return 0.7;
    if (difference <= 20) return 0.5;
    return 0.3;
  }

  /// Calcula puntuación de alineación rodilla-pie
  double _calculateAlignmentScore(PoseDetection pose) {
    // Verificar que rodillas no pasen de los pies
    final leftKnee = pose.getKeypoint('left_knee');
    final rightKnee = pose.getKeypoint('right_knee');
    final leftAnkle = pose.getKeypoint('left_ankle');
    final rightAnkle = pose.getKeypoint('right_ankle');

    if (leftKnee == null || rightKnee == null || 
        leftAnkle == null || rightAnkle == null) {
      return 0.5;
    }

    // Si la rodilla está muy adelante del tobillo, penalizar
    final leftOvershoot = (leftKnee.x - leftAnkle.x).abs();
    final rightOvershoot = (rightKnee.x - rightAnkle.x).abs();
    final avgOvershoot = (leftOvershoot + rightOvershoot) / 2;

    if (avgOvershoot <= 0.05) return 1.0;
    if (avgOvershoot <= 0.1) return 0.8;
    if (avgOvershoot <= 0.15) return 0.6;
    return 0.4;
  }

  /// Agrega calidad al historial
  void _addQualityToHistory(double quality) {
    _qualityHistory.add(quality);
    if (_qualityHistory.length > _qualityHistorySize) {
      _qualityHistory.removeAt(0);
    }
  }

  /// Actualiza calidad promedio
  void _updateAverageQuality() {
    if (_qualityHistory.isEmpty) {
      _formQuality = 0.0;
    } else {
      _formQuality = _qualityHistory.reduce((a, b) => a + b) / _qualityHistory.length;
    }
  }

  /// Obtiene mensaje de fase actual
  String getPhaseMessage() {
    switch (_currentPhase) {
      case SquatPhase.up:
        return 'ARRIBA - Baja';
      case SquatPhase.down:
        return 'ABAJO - Sube';
      case SquatPhase.transition:
        return 'Transición...';
    }
  }

  @override
  void dispose() {
    _isActive = false;
    super.dispose();
  }
}

