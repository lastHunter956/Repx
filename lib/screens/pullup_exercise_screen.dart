import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:REPX/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/pullup_counter.dart';
import '../services/exercise_service_pullup.dart';
import '../services/pullup_workout_storage.dart';
import '../widgets/camera_preview_widget_pullup.dart';
import '../widgets/premium_pullup_progress_bar.dart';
import '../utils/app_colors.dart';
import '../utils/pullup_validator.dart';
import '../models/workout_config.dart';
import '../models/pullup_workout.dart';

/// Pantalla de ejercicio de Pull-Ups con cámara y detección en tiempo real
/// Incluye sistema de series con temporizador de descanso
class PullUpExerciseScreen extends StatefulWidget {
  final double barHeight;
  final WorkoutConfig workoutConfig;

  const PullUpExerciseScreen({
    super.key,
    required this.barHeight,
    required this.workoutConfig,
  });

  @override
  State<PullUpExerciseScreen> createState() => _PullUpExerciseScreenState();
}

enum WorkoutState { active, resting, completed }

class _PullUpExerciseScreenState extends State<PullUpExerciseScreen>
    with TickerProviderStateMixin {
  ExerciseServicePullUp? _exerciseService;
  bool _isInitializing = true;
  String _errorMessage = '';
  PullUpCounter? _counter;

  // Control de series
  int _currentSet = 1;
  WorkoutState _workoutState = WorkoutState.active;
  Timer? _restTimer;
  int _restTimeRemaining = 0;

  // Lista de series completadas para el historial
  final List<int> _completedSets = [];
  DateTime? _workoutStartTime;

  @override
  void initState() {
    super.initState();
    // Pull-Ups se mantiene en PORTRAIT (vertical)
    // NO rotar la pantalla
    _workoutStartTime = DateTime.now();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      print('🔧 [PullUp] Inicializando servicios...');

      // Pequeño delay para asegurar que la cámara anterior se liberó
      await Future.delayed(const Duration(milliseconds: 200));

      // Crear contador
      _counter = PullUpCounter();
      _counter!.addListener(_onCounterChanged);
      print('✅ [PullUp] Counter creado');

      _exerciseService = ExerciseServicePullUp(counter: _counter!);
      print('✅ [PullUp] ExerciseService creado');

      final success = await _exerciseService!.initialize();
      print('📱 [PullUp] Initialize result: $success');

      if (mounted) {
        if (!success) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'No se pudo inicializar la cámara';
          });
          print('❌ [PullUp] Fallo en inicialización de servicios');
          return;
        }

        // Verificar que la cámara esté lista
        final controller = _exerciseService!.cameraController;
        print('📹 [PullUp] Controller obtenido: ${controller != null}');

        if (controller == null) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'CameraController es null';
          });
          print('❌ [PullUp] CameraController es null después de inicializar');
          return;
        }

        print('📹 [PullUp] Controller value: ${controller.value}');
        print('📹 [PullUp] IsInitialized: ${controller.value.isInitialized}');
        print(
            '📹 [PullUp] IsRecordingVideo: ${controller.value.isRecordingVideo}');
        print('📹 [PullUp] PreviewSize: ${controller.value.previewSize}');

        if (!controller.value.isInitialized) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'CameraController no está inicializado';
          });
          print('❌ [PullUp] CameraController no está inicializado');
          return;
        }

        print('✅ [PullUp] Cámara verificada y lista');
        print('✅ [PullUp] Iniciando sesión Pull-Up...');

        setState(() {
          _isInitializing = false;
        });

        // Iniciar sesión y procesamiento
        _counter!.startSession(barHeight: widget.barHeight);
        await _exerciseService!.startProcessing();

        print('✅ Procesamiento iniciado');
      }
    } catch (e) {
      print('❌ Error inicializando Pull-Up: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  void _onCounterChanged() {
    if (_counter == null) return;

    // Verificar si se completó la serie actual
    if (_counter!.count >= widget.workoutConfig.repsPerSet &&
        _workoutState == WorkoutState.active) {
      _onSetCompleted();
    }
  }

  void _onSetCompleted() {
    setState(() {
      _completedSets.add(_counter!.count);

      if (_currentSet < widget.workoutConfig.totalSets) {
        // Hay más series por hacer - iniciar descanso
        _workoutState = WorkoutState.resting;
        _currentSet++;
        _startRestTimer();
      } else {
        // Entrenamiento completado
        _workoutState = WorkoutState.completed;
        _onWorkoutCompleted();
      }
    });
  }

  void _startRestTimer() {
    _restTimeRemaining = widget.workoutConfig.restTimeSeconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restTimeRemaining--;
      });

      if (_restTimeRemaining <= 0) {
        _endRest();
      }
    });
  }

  void _endRest() {
    _restTimer?.cancel();
    setState(() {
      _workoutState = WorkoutState.active;
      _restTimeRemaining = 0;
    });

    // Resetear contador para la siguiente serie
    _counter?.reset();
  }

  void _skipRest() {
    _restTimer?.cancel();
    _endRest();
  }

  void _onWorkoutCompleted() {
    // Aquí se manejará el final del entrenamiento
    print('🎉 Entrenamiento completado!');
    // TODO: Mostrar pantalla de resumen y guardado
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _exerciseService?.dispose();
    _counter?.removeListener(_onCounterChanged);
    _counter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _counter,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _isInitializing
              ? _buildLoadingView()
              : _errorMessage.isNotEmpty
                  ? _buildErrorView()
                  : _buildExerciseView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Inicializando cámara...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.goBack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseView() {
    if (_workoutState == WorkoutState.resting) {
      return _buildRestScreen();
    } else if (_workoutState == WorkoutState.completed) {
      return _buildCompletedScreen();
    }

    return Stack(
      children: [
        // Camera Preview con detección (background)
        if (_exerciseService != null &&
            _exerciseService!.cameraController != null &&
            _exerciseService!.cameraController!.value.isInitialized)
          Positioned.fill(
            child: CameraPreviewWidgetPullUp(
              cameraController: _exerciseService!.cameraController!,
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Esperando cámara...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

        // Overlay oscuro sutil para mejorar legibilidad
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // UI Premium Minimalista con información de series
        _buildPremiumUI(),
      ],
    );
  }

  Widget _buildPremiumUI() {
    return Consumer<PullUpCounter>(
      builder: (context, counter, _) {
        // Obtener altura actual de cabeza
        double currentHeadHeight = widget.barHeight; // Default
        if (counter.currentPose != null) {
          final headHeight =
              PullUpValidator.getHeadHeight(counter.currentPose!);
          if (headHeight != null) {
            currentHeadHeight = headHeight;
          }
        }

        return Stack(
          children: [
            // Botón cerrar minimalista
            Positioned(
              top: 50,
              right: 24,
              child: _buildMinimalCloseButton(),
            ),

            // Contador principal (arriba centro)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: _buildMainCounter(counter),
            ),

            // Barra de progreso diagonal premium (centro)
            Center(
              child: PremiumPullUpProgressBar(
                counter: counter,
                currentHeadHeight: currentHeadHeight,
                barHeight: widget.barHeight,
              ),
            ),

            // Panel de estadísticas mínimas (abajo)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: _buildMinimalStats(counter),
            ),

            // Botón finalizar elegante
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: _buildElegantFinishButton(counter),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMinimalCloseButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
        onPressed: () => _showMinimalExitDialog(),
      ),
    );
  }

  Widget _buildMainCounter(PullUpCounter counter) {
    return Column(
      children: [
        // Información de serie
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${AppLocalizations.of(context)!.set} $_currentSet/${widget.workoutConfig.totalSets}',
            style: TextStyle(
              color: AppColors.primaryCyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Número principal
        Text(
          '${counter.count}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w100,
            height: 0.9,
            shadows: [
              Shadow(
                color: AppColors.primaryCyan.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),

        // Progreso de la serie actual
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${counter.count}',
              style: TextStyle(
                color: AppColors.primaryCyan,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              ' / ${widget.workoutConfig.repsPerSet}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Feedback premium único (solo cuando no hay repeticiones)
        if (counter.feedback.isNotEmpty && counter.count == 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.primaryCyan.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              counter.feedback,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMinimalStats(PullUpCounter counter) {
    final duration = counter.sessionDuration;
    final timeStr =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('TIEMPO', timeStr, Icons.timer_outlined),
              _buildStatItem(
                  'FORMA',
                  '${counter.formQuality.toStringAsFixed(0)}%',
                  Icons.grade_rounded),
              _buildStatItem(
                  'RITMO',
                  '${counter.averagePace.toStringAsFixed(1)}/min',
                  Icons.speed_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildElegantFinishButton(PullUpCounter counter) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan.withOpacity(0.8),
            AppColors.primaryCyan,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _finishSession(),
          child: Center(
            child: Text(
              counter.count > 0
                  ? AppLocalizations.of(context)!.finishSession
                  : AppLocalizations.of(context)!.finish,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMinimalExitDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.finishSessionQuestion,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'Se perderá el progreso actual',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              // Descartar sin guardar
              Navigator.pop(context);
              _counter?.reset();
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'DESCARTAR',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _counter?.endSession();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              'GUARDAR',
              style: TextStyle(color: AppColors.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishSession() async {
    print('🏁 [PullUp Screen] Finalizando sesión...');
    final session = await _counter?.endSession();
    print(
        '🏁 [PullUp Screen] endSession retornó: ${session != null ? "sesión válida" : "null"}');

    if (mounted && session != null) {
      print('🏁 [PullUp Screen] Mostrando diálogo de resumen...');
      // Navegar a pantalla de resumen (por ahora solo mostramos diálogo)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.successGreen, size: 28),
              const SizedBox(width: 12),
              const Text(
                '¡Sesión Guardada!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                  'Repeticiones', '${session.totalReps}', Icons.fitness_center),
              if (session.invalidReps > 0)
                _buildSummaryRow(
                    'Inválidas', '${session.invalidReps}', Icons.close_rounded),
              _buildSummaryRow(
                  'Calidad',
                  '${session.averageFormQuality.toStringAsFixed(0)}%',
                  Icons.grade_rounded),
              _buildSummaryRow(
                  'Duración',
                  '${session.duration.inMinutes}:${(session.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  Icons.timer_outlined),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a home
              },
              child: Text(
                'ACEPTAR',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildRestScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título
            Text(
              AppLocalizations.of(context)!.rest,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 24),

            // Información de series
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.set.toLowerCase().replaceFirst(AppLocalizations.of(context)!.set[0], AppLocalizations.of(context)!.set[0].toUpperCase())} $_currentSet de ${widget.workoutConfig.totalSets}',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.previousSet}: ${_completedSets.last} pull-ups',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Countdown timer
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryCyan,
                  width: 4,
                ),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_restTimeRemaining',
                      style: TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'segundos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Botón saltar descanso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: _skipRest,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                      AppLocalizations.of(context)!.skipRest,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Progreso general
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    'Progreso del entrenamiento',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentSet - 1) / widget.workoutConfig.totalSets,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_currentSet - 1)} de ${widget.workoutConfig.totalSets} ${AppLocalizations.of(context)!.setsCompleted}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    final totalReps = _completedSets.fold(0, (sum, reps) => sum + reps);
    final workoutDuration = DateTime.now().difference(_workoutStartTime!);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.green[900]!.withOpacity(0.3),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título de felicitaciones
              const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 80,
              ),

              const SizedBox(height: 24),

              const Text(
                '¡ENTRENAMIENTO\nCOMPLETADO!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 48),

              // Resumen estadísticas
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.successGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                        'Total Pull-Ups', '$totalReps', Icons.fitness_center),
                    const SizedBox(height: 16),
                    _buildStatRow('Series Completadas',
                        '${widget.workoutConfig.totalSets}', Icons.layers),
                    const SizedBox(height: 16),
                    _buildStatRow(
                        'Tiempo Total',
                        '${workoutDuration.inMinutes}:${(workoutDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                        Icons.timer),
                    const SizedBox(height: 16),
                    _buildStatRow(
                        'Promedio por Serie',
                        (totalReps / widget.workoutConfig.totalSets).toStringAsFixed(1),
                        Icons.trending_up),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Botón finalizar entrenamiento
              GestureDetector(
                onTap: _finishWorkout,
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'FINALIZAR ENTRENAMIENTO',
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

              const SizedBox(height: 16),

              // Botón repetir entrenamiento
              TextButton(
                onPressed: _restartWorkout,
                child: Text(
                  'Repetir entrenamiento',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.successGreen, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppColors.successGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _finishWorkout() async {
    if (_workoutStartTime == null) return;

    try {
      // Crear entrenamiento completo
      final workout = PullUpWorkout(
        startTime: _workoutStartTime!,
        endTime: DateTime.now(),
        config: widget.workoutConfig,
        title:
            'Entrenamiento Pull-Ups ${_workoutStartTime!.day}/${_workoutStartTime!.month}',
        sets: _completedSets.asMap().entries.map((entry) {
          final setNumber = entry.key + 1;
          final reps = entry.value;
          return PullUpSet(
            setNumber: setNumber,
            startTime: _workoutStartTime!
                .add(Duration(minutes: setNumber * 3)), // Estimado
            endTime: _workoutStartTime!
                .add(Duration(minutes: setNumber * 3 + 2)), // Estimado
            completedReps: reps,
            averageFormQuality: _counter?.averageFormQuality ?? 0.0,
          );
        }).toList(),
      );

      // Guardar en historial
      final storage = PullUpWorkoutStorage();
      final success = await storage.saveWorkout(workout);

      if (success) {
        print('✅ Entrenamiento guardado exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Entrenamiento guardado exitosamente',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ Error guardando entrenamiento');
      }
    } catch (e) {
      print('❌ Error creando entrenamiento: $e');
    }

    // Esperar un momento antes de navegar
    await Future.delayed(Duration(milliseconds: 500));
    Navigator.pop(context);
  }

  void _restartWorkout() {
    setState(() {
      _currentSet = 1;
      _workoutState = WorkoutState.active;
      _completedSets.clear();
      _workoutStartTime = DateTime.now();
    });
    _counter?.reset();
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryCyan, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primaryCyan,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

