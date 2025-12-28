import 'package:flutter/material.dart';
import 'package:REPX/l10n/app_localizations.dart';
import 'package:camera/camera.dart';
import '../utils/app_colors.dart';
import '../models/workout_config.dart';
import 'pullup_exercise_screen.dart';

/// Pantalla de calibración de barra para Pull-Ups
/// Permite al usuario alinear una línea horizontal con su barra real
/// y configurar su entrenamiento (series, repeticiones, descanso)
class PullUpCalibrationScreen extends StatefulWidget {
  const PullUpCalibrationScreen({super.key});

  @override
  State<PullUpCalibrationScreen> createState() =>
      _PullUpCalibrationScreenState();
}

enum CalibrationStep { setup, calibration, ready }

class _PullUpCalibrationScreenState extends State<PullUpCalibrationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  double _barPosition = 0.3; // Posición de la barra (0.0 = top, 1.0 = bottom)
  bool _isCalibrated = false;
  CalibrationStep _currentStep = CalibrationStep.setup;

  // Configuración de entrenamiento
  WorkoutConfig _workoutConfig = WorkoutConfig.defaultConfig;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('❌ No hay cámaras disponibles');
        return;
      }

      // Usar cámara frontal
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Error inicializando cámara: $e');
    }
  }

  @override
  void dispose() {
    try {
      _cameraController?.dispose();
    } catch (e) {
      print('⚠️ Error al disponer cámara de calibración: $e');
    }
    super.dispose();
  }

  void _updateBarPosition(double delta) {
    setState(() {
      _barPosition = (_barPosition + delta).clamp(0.1, 0.9);
    });
  }

  void _confirmCalibration() {
    setState(() {
      _isCalibrated = true;
      _currentStep = CalibrationStep.ready;
    });
  }

  void _startCalibration() {
    setState(() {
      _currentStep = CalibrationStep.calibration;
    });
  }

  void _updateWorkoutConfig(WorkoutConfig newConfig) {
    setState(() {
      _workoutConfig = newConfig;
    });
  }

  Future<void> _startExercise() async {
    // Detener y liberar la cámara ANTES de navegar
    print('📹 Liberando cámara de calibración...');
    await _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;

    // Pequeño delay para asegurar liberación completa
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    print('🚀 Navegando a ejercicio Pull-Up con config: $_workoutConfig');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PullUpExerciseScreen(
          barHeight: _barPosition,
          workoutConfig: _workoutConfig,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _currentStep == CalibrationStep.setup
          ? _buildSetupScreen()
          : _buildCalibrationScreen(),
    );
  }

  Widget _buildSetupScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, const Color(0xFF1a1a2e), Colors.black],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.pullups,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.configureWorkout,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Configuración de entrenamiento
                _buildConfigItem(
                  title: AppLocalizations.of(context)!.repsPerSet,
                  subtitle: AppLocalizations.of(context)!.repsPerSetDesc,
                  value: _workoutConfig.repsPerSet,
                  unit: AppLocalizations.of(context)!.repsUnit,
                  icon: Icons.repeat_rounded,
                  onChanged: (value) => _updateWorkoutConfig(
                    _workoutConfig.copyWith(repsPerSet: value),
                  ),
                  min: 1,
                  max: 50,
                ),

                const SizedBox(height: 20),

                _buildConfigItem(
                  title: AppLocalizations.of(context)!.numberOfSets,
                  subtitle: AppLocalizations.of(context)!.numberOfSetsDesc,
                  value: _workoutConfig.totalSets,
                  unit: AppLocalizations.of(context)!.seriesUnit,
                  icon: Icons.layers_rounded,
                  onChanged: (value) => _updateWorkoutConfig(
                    _workoutConfig.copyWith(totalSets: value),
                  ),
                  min: 1,
                  max: 10,
                ),

                const SizedBox(height: 20),

                _buildConfigItem(
                  title: AppLocalizations.of(context)!.restBetweenSets,
                  subtitle: AppLocalizations.of(context)!.restBetweenSetsDesc,
                  value: _workoutConfig.restTimeSeconds,
                  unit: AppLocalizations.of(context)!.secondsUnit,
                  icon: Icons.timer_rounded,
                  onChanged: (value) => _updateWorkoutConfig(
                    _workoutConfig.copyWith(restTimeSeconds: value),
                  ),
                  min: 15,
                  max: 300,
                  step: 15,
                ),

                const SizedBox(height: 32),

                // Resumen del entrenamiento
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryCyan.withOpacity(0.2),
                        AppColors.primaryCyan.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.workoutSummary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            AppLocalizations.of(context)!.total,
                            '${_workoutConfig.repsPerSet * _workoutConfig.totalSets}',
                            'pull-ups',
                            Icons.fitness_center,
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          _buildSummaryItem(
                            AppLocalizations.of(context)!.time,
                            '~${_calculateEstimatedTime()}',
                            AppLocalizations.of(context)!.minutes,
                            Icons.schedule,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Botón continuar
                GestureDetector(
                  onTap: _startCalibration,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryCyan,
                          const Color(0xFF00d4ff),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.continueToCalibration,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalibrationScreen() {
    return Stack(
      children: [
        // Camera Preview
        if (_isCameraInitialized && _cameraController != null)
          Positioned.fill(child: CameraPreview(_cameraController!))
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Overlay con línea de calibración
        if (_currentStep == CalibrationStep.calibration)
          Positioned.fill(
            child: CustomPaint(
              painter: _BarCalibrationPainter(
                barPosition: _barPosition,
                isCalibrated: _isCalibrated,
              ),
            ),
          ),

        // Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                    onPressed: () => setState(() {
                      _currentStep = CalibrationStep.setup;
                      _isCalibrated = false;
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.calibrateBar,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isCalibrated
                              ? AppLocalizations.of(context)!.systemReady
                              : AppLocalizations.of(context)!.alignLine,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Controles de calibración
        if (!_isCalibrated && _currentStep == CalibrationStep.calibration)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Controles de ajuste
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          icon: Icons.keyboard_arrow_up_rounded,
                          onPressed: () => _updateBarPosition(-0.03),
                          label: AppLocalizations.of(context)!.adjustUp,
                        ),
                        const SizedBox(width: 60),
                        _buildControlButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onPressed: () => _updateBarPosition(0.03),
                          label: AppLocalizations.of(context)!.adjustDown,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botón confirmar
                    GestureDetector(
                      onTap: _confirmCalibration,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryCyan,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.confirmPosition,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Botón comenzar (aparece después de calibrar)
        if (_isCalibrated && _currentStep == CalibrationStep.ready)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Resumen del entrenamiento
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Series',
                            '${_workoutConfig.totalSets}',
                          ),
                          _buildStatItem(
                            'Reps/Serie',
                            '${_workoutConfig.repsPerSet}',
                          ),
                          _buildStatItem(
                            'Descanso',
                            '${_workoutConfig.restTimeSeconds}s',
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: _startExercise,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.successGreen,
                              AppColors.successGreen.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.successGreen.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.startTraining,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isCalibrated = false;
                          _currentStep = CalibrationStep.calibration;
                        });
                      },
                      child: Text(
                        AppLocalizations.of(context)!.recalibrateBar,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfigItem({
    required String title,
    required String subtitle,
    required int value,
    required String unit,
    required IconData icon,
    required Function(int) onChanged,
    required int min,
    required int max,
    int step = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryCyan.withOpacity(0.3),
                      AppColors.primaryCyan.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryCyan, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged((value - step).clamp(min, max)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryCyan.withOpacity(0.3),
                        AppColors.primaryCyan.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.remove_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$value $unit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged((value + step).clamp(min, max)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryCyan.withOpacity(0.3),
                        AppColors.primaryCyan.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryCyan, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryCyan.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(icon, color: AppColors.primaryCyan, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.primaryCyan,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  int _calculateEstimatedTime() {
    // Tiempo estimado: 2 segundos por rep + descanso entre series
    final repTime = _workoutConfig.repsPerSet * _workoutConfig.totalSets * 2;
    final restTime =
        (_workoutConfig.totalSets - 1) * _workoutConfig.restTimeSeconds;
    return ((repTime + restTime) / 60).ceil();
  }
}

/// Painter para dibujar la línea de calibración de la barra
class _BarCalibrationPainter extends CustomPainter {
  final double barPosition;
  final bool isCalibrated;

  _BarCalibrationPainter({
    required this.barPosition,
    required this.isCalibrated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barY = size.height * barPosition;

    // Línea principal de la barra
    final barPaint = Paint()
      ..color = isCalibrated ? AppColors.successGreen : AppColors.primaryCyan
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Línea horizontal
    canvas.drawLine(Offset(0, barY), Offset(size.width, barY), barPaint);

    // Indicadores en los extremos
    final indicatorPaint = Paint()
      ..color = isCalibrated ? AppColors.successGreen : AppColors.primaryCyan
      ..style = PaintingStyle.fill;

    // Triángulos en los extremos
    final triangleSize = 20.0;

    // Triángulo izquierdo
    final leftPath = Path()
      ..moveTo(0, barY)
      ..lineTo(triangleSize, barY - triangleSize / 2)
      ..lineTo(triangleSize, barY + triangleSize / 2)
      ..close();
    canvas.drawPath(leftPath, indicatorPaint);

    // Triángulo derecho
    final rightPath = Path()
      ..moveTo(size.width, barY)
      ..lineTo(size.width - triangleSize, barY - triangleSize / 2)
      ..lineTo(size.width - triangleSize, barY + triangleSize / 2)
      ..close();
    canvas.drawPath(rightPath, indicatorPaint);

    // Texto con altura
    final textPainter = TextPainter(
      text: TextSpan(
        text: isCalibrated ? '✓ CALIBRADO' : 'AJUSTAR BARRA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          backgroundColor:
              (isCalibrated ? AppColors.successGreen : AppColors.primaryCyan)
                  .withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, barY - 40),
    );
  }

  @override
  bool shouldRepaint(_BarCalibrationPainter oldDelegate) {
    return oldDelegate.barPosition != barPosition ||
        oldDelegate.isCalibrated != isCalibrated;
  }
}
