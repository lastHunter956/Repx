import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../models/pose_keypoint.dart';

/// Estados de fase de un abdominal
enum AbdominalPhase {
  /// Posición abajo (espalda en el suelo)
  down,

  /// Posición arriba (tronco levantado)
  up,

  /// En transición entre posiciones
  transition,
}

/// Contador de abdominales con validación de forma
/// 
/// Detecta abdominales analizando el ángulo del tronco
/// (hombro-cadera-rodilla) y el movimiento vertical de los hombros.
class AbdominalCounter extends ChangeNotifier {
  // === Estado del contador ===
  int _count = 0;
  int get count => _count;

  AbdominalPhase _currentPhase = AbdominalPhase.down;
  AbdominalPhase get currentPhase => _currentPhase;

  double _formQuality = 0.0;
  double get formQuality => _formQuality;

  bool _isActive = false;
  bool get isActive => _isActive;

  // === Historial de calidad para promedios ===
  final List<double> _qualityHistory = [];
  static const int _qualityHistorySize = 30;

  // === Umbrales de detección ===
  /// Ángulo máximo del tronco para posición "arriba" (grados)
  static const double _upAngleThreshold = 120.0;

  /// Ángulo mínimo del tronco para posición "abajo" (grados)
  static const double _downAngleThreshold = 160.0;

  /// Distancia vertical mínima del hombro para detectar movimiento
  static const double _minShoulderMovement = 0.05;

  /// Frames mínimos en cada posición para validar rep
  static const int _minFramesInPosition = 3;

  // === Tracking de posición ===
  int _framesInUp = 0;
  int _framesInDown = 0;
  bool _wasUp = false;

  // === Tracking de ángulos y posiciones ===
  double _trunkAngle = 180.0;
  double _shoulderY = 0.0;
  double _baselineShoulderY = 0.0;
  bool _hasBaseline = false;

  double get trunkAngle => _trunkAngle;

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
    _currentPhase = AbdominalPhase.down;
    _formQuality = 0.0;
    _qualityHistory.clear();
    _framesInUp = 0;
    _framesInDown = 0;
    _wasUp = false;
    _trunkAngle = 180.0;
    _shoulderY = 0.0;
    _baselineShoulderY = 0.0;
    _hasBaseline = false;
    notifyListeners();
  }

  /// Procesa una pose detectada
  void processPose(PoseDetection pose) {
    if (!_isActive) return;

    // Obtener keypoints necesarios
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightShoulder = pose.getKeypoint('right_shoulder');
    final leftHip = pose.getKeypoint('left_hip');
    final rightHip = pose.getKeypoint('right_hip');
    final leftKnee = pose.getKeypoint('left_knee');
    final rightKnee = pose.getKeypoint('right_knee');

    // Verificar keypoints válidos
    if (!_areKeypointsValid([
      leftShoulder, rightShoulder,
      leftHip, rightHip,
      leftKnee, rightKnee,
    ])) {
      return;
    }

    // Calcular centro de hombros
    final shoulderCenterY = (leftShoulder!.y + rightShoulder!.y) / 2;
    _shoulderY = shoulderCenterY;

    // Establecer baseline de posición inicial
    if (!_hasBaseline) {
      _baselineShoulderY = shoulderCenterY;
      _hasBaseline = true;
    }

    // Calcular ángulo del tronco (promedio izquierda/derecha)
    final leftTrunkAngle = _calculateAngle(leftShoulder, leftHip!, leftKnee!);
    final rightTrunkAngle = _calculateAngle(rightShoulder, rightHip!, rightKnee!);
    _trunkAngle = (leftTrunkAngle + rightTrunkAngle) / 2;

    // Calcular movimiento vertical de hombros
    final shoulderMovement = _baselineShoulderY - shoulderCenterY;

    // Determinar fase actual
    final previousPhase = _currentPhase;

    if (_trunkAngle <= _upAngleThreshold && shoulderMovement >= _minShoulderMovement) {
      _currentPhase = AbdominalPhase.up;
      _framesInUp++;
      _framesInDown = 0;
    } else if (_trunkAngle >= _downAngleThreshold || shoulderMovement < _minShoulderMovement / 2) {
      _currentPhase = AbdominalPhase.down;
      _framesInDown++;
      _framesInUp = 0;
    } else {
      _currentPhase = AbdominalPhase.transition;
    }

    // Detectar repetición completada (up → down)
    if (_wasUp && 
        _currentPhase == AbdominalPhase.down && 
        _framesInDown >= _minFramesInPosition) {
      _count++;
      _wasUp = false;

      // Calcular calidad de la repetición
      final quality = _calculateRepQuality(pose);
      _addQualityToHistory(quality);

      // Actualizar baseline
      _baselineShoulderY = shoulderCenterY;

      if (kDebugMode) {
        print('🏃 Abdominal #$_count! Calidad: ${(quality * 100).toStringAsFixed(0)}%');
      }
    }

    // Marcar que estuvo arriba
    if (_currentPhase == AbdominalPhase.up && _framesInUp >= _minFramesInPosition) {
      _wasUp = true;
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

    // Factor 1: Altura del crunch (40%)
    final heightScore = _calculateHeightScore();
    quality *= 0.4 + (heightScore * 0.6);

    // Factor 2: Simetría de movimiento (30%)
    final symmetryScore = _calculateSymmetryScore(pose);
    quality *= 0.4 + (symmetryScore * 0.6);

    // Factor 3: Control del movimiento (30%)
    final controlScore = _calculateControlScore();
    quality *= 0.4 + (controlScore * 0.6);

    return quality.clamp(0.0, 1.0);
  }

  /// Calcula puntuación de altura del crunch
  double _calculateHeightScore() {
    // Mejor crunch = menor ángulo del tronco
    if (_trunkAngle <= 100) return 1.0; // Excelente
    if (_trunkAngle <= 110) return 0.9;
    if (_trunkAngle <= 120) return 0.8;
    if (_trunkAngle <= 130) return 0.6;
    return 0.4;
  }

  /// Calcula puntuación de simetría
  double _calculateSymmetryScore(PoseDetection pose) {
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightShoulder = pose.getKeypoint('right_shoulder');

    if (leftShoulder == null || rightShoulder == null) return 0.5;

    // Verificar que ambos hombros suban igual
    final heightDiff = (leftShoulder.y - rightShoulder.y).abs();
    
    if (heightDiff <= 0.02) return 1.0;
    if (heightDiff <= 0.04) return 0.8;
    if (heightDiff <= 0.06) return 0.6;
    return 0.4;
  }

  /// Calcula puntuación de control
  double _calculateControlScore() {
    // Basado en frames estables en posición
    final stabilityScore = math.min(_framesInUp, 10) / 10.0;
    return stabilityScore;
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
      case AbdominalPhase.down:
        return 'ABAJO - Sube';
      case AbdominalPhase.up:
        return 'ARRIBA - Baja';
      case AbdominalPhase.transition:
        return 'Transición...';
    }
  }

  @override
  void dispose() {
    _isActive = false;
    super.dispose();
  }
}

