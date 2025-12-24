import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:REPX/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/pushup_counter.dart';
import '../services/exercise_service.dart';
import '../services/settings_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../utils/app_colors.dart';

/// Pantalla principal de ejercicio con cámara y detección en tiempo real
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  ExerciseService? _exerciseService;
  bool _isInitializing = true;
  String _errorMessage = '';
  // UI styles (kept minimal - use local TextStyles in widgets)

  @override
  void initState() {
    super.initState();
    // 🔒 FORZAR LANDSCAPE SOLO EN ESTA PANTALLA
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      print('🔧 Inicializando servicios...');
      final counter = context.read<PushUpCounter>();
      _exerciseService = ExerciseService(counter: counter);

      final success = await _exerciseService!.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          if (!success) {
            print('❌ Fallo al inicializar cámara');
            _errorMessage = 'No se pudo inicializar la cámara';
          } else {
            print('✅ Servicios inicializados correctamente');

            // Iniciar sesión y procesamiento automáticamente
            print('🎬 Iniciando sesión automáticamente...');
            counter.startSession();

            print('📹 Iniciando procesamiento de video...');
            _exerciseService!.startProcessing();

            print('✅ Todo listo para contar flexiones');
          }
        });
      }
    } catch (e) {
      print('❌ Error en _initializeServices: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    // 📱 RESTAURAR PORTRAIT al salir de esta pantalla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _exerciseService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? _buildLoadingView()
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _buildExerciseView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primaryCyan,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.initializingAI,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.preparingPoseDetection,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red.shade900, Colors.black],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade300,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(AppLocalizations.of(context)!.goBack),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseView() {
    return Consumer<PushUpCounter>(
      builder: (context, counter, child) {
        // final screenWidth = MediaQuery.of(context).size.width; // reservado si se necesita responsive más adelante
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.deepPurple.shade900.withOpacity(0.32),
                Colors.black,
              ],
            ),
          ),
          // Mantener layout original: Cámara a la izquierda, Stats a la derecha
          child: Row(
            children: [
              // 📷 VISTA DE CÁMARA (70% del ancho) - mantener padding y tamaño originales
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      // Cámara con skeleton (preservar exacto ClipRRect original)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Consumer<SettingsService>(
                          builder: (context, settings, _) {
                            // Calcular aspect ratio de la cámara
                            final controller = _exerciseService?.cameraService.controller;
                            final cameraAspectRatio = controller != null && 
                                controller.value.isInitialized &&
                                controller.value.previewSize != null
                                ? controller.value.previewSize!.height / controller.value.previewSize!.width
                                : null;
                            
                            return CameraPreviewWidget(
                              controller: controller,
                              currentPose: counter.currentPose,
                              angles: counter.angles,
                              formQuality: counter.formQuality,
                              showSkeleton: settings.showSkeleton,
                              showAngles: settings.showAngles,
                              showQualityBar: settings.showQualityBar,
                              cameraAspectRatio: cameraAspectRatio,
                            );
                          },
                        ),
                      ),

                      // Botón volver flotante (esquina superior izquierda) - mantener posición
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildBackButton(counter),
                      ),
                    ],
                  ),
                ),
              ),

              // PANEL DE ESTADÍSTICAS (30% del ancho) - efecto glass y padding refinado
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.white.withOpacity(0.03),
                        child: _buildStatsPanel(counter),
                      ),
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

  // 🔙 Botón volver flotante
  Widget _buildBackButton(PushUpCounter counter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: IconButton(
        onPressed: () => _showExitDialog(counter),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        iconSize: 20,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        splashRadius: 24,
      ),
    );
  }

  // 📊 Panel de estadísticas lateral derecho (LANDSCAPE)
  Widget _buildStatsPanel(PushUpCounter counter) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Column(
        children: [
          // 🏆 CONTADOR PRINCIPAL GIGANTE (diseño pulido)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.16),
                    AppColors.primaryPurple.withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.04),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Contador grande con shader y pequeña etiqueta
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryCyan,
                              AppColors.successGreen
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '${counter.count}',
                            style: TextStyle(
                              fontSize: 96,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -3,
                              shadows: [
                                Shadow(
                                  color:
                                      AppColors.primaryCyan.withOpacity(0.25),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppLocalizations.of(context)!.pushups.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Estadísticas reordenadas: mayor énfasis en TIEMPO, eliminar KCAL
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Tarjeta grande de TIEMPO (más prominente)
                Expanded(
                  flex: 4,
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryCyan.withOpacity(0.12),
                          AppColors.primaryPurple.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.04),
                        width: 1.0,
                      ),
                    ),
                    // Usar LayoutBuilder para calcular tamaños y centrar verticalmente
                    child: LayoutBuilder(builder: (context, constraints) {
                      final base = constraints.maxHeight.clamp(32.0, 220.0);
                      // Aumentar tamaño del cronómetro: multiplicador mayor y clamp máximo más alto
                      final fontSize = (base * 0.72).clamp(28.0, 110.0);
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatDuration(
                                  counter.currentSession?.sessionDuration ??
                                      Duration.zero,
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 4),

                // Fila: Calidad y Malas (ocupando una fila) - aumentar ligeramente su espacio (simulando 1.5)
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          value: '${counter.formQuality.toInt()}%',
                          label: AppLocalizations.of(context)!.formQuality,
                          color: _getQualityColor(counter.formQuality),
                          large: true,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildStatCard(
                          value: '${counter.invalidCount}',
                          label: AppLocalizations.of(context)!.badReps,
                          color: AppColors.warningYellow,
                          large: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Fase actual (aumentar ligeramente su contenedor para evitar recorte)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildPhaseIndicator(counter),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // � Card de estadística individual
  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    bool large = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.10), width: 1.0),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        // Responsive sizing: base font sizes on the available height
        final base = (constraints.maxHeight).clamp(20.0, 160.0);
        double valueFontSize;
        double labelFontSize;

        if (large) {
          valueFontSize = (base * 0.75).clamp(14.0, 96.0);
          labelFontSize = (base * 0.22).clamp(12.0, 22.0);
        } else {
          valueFontSize = (base * 0.6).clamp(12.0, 64.0);
          labelFontSize = (base * 0.20).clamp(11.0, 20.0);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // � Indicador de fase actual (UP/DOWN/TRANSITION)
  Widget _buildPhaseIndicator(PushUpCounter counter) {
    final phase = counter.currentPhase;
    Color phaseColor;
    String phaseText;

    switch (phase) {
      case PushUpPhase.up:
        phaseColor = AppColors.successGreen;
        phaseText = 'ARRIBA';
        break;
      case PushUpPhase.down:
        phaseColor = AppColors.primaryCyan;
        phaseText = 'ABAJO';
        break;
      case PushUpPhase.transition:
        phaseColor = AppColors.warningYellow;
        phaseText = 'MOVIÉNDOTE';
        break;
    }

    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight.clamp(28.0, 120.0);
      final fontSize = (h * 0.45).clamp(14.0, 28.0);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              phaseColor.withOpacity(0.3),
              phaseColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: phaseColor.withOpacity(0.6),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: phaseColor.withOpacity(0.4),
              blurRadius: 15,
            ),
          ],
        ),
        child: Center(
          child: Text(
            phaseText,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              shadows: [
                Shadow(
                  color: phaseColor,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Color _getQualityColor(double quality) {
    if (quality >= 80) return AppColors.successGreen;
    if (quality >= 60) return AppColors.primaryCyan;
    if (quality >= 40) return AppColors.warningYellow;
    return AppColors.errorPink;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showExitDialog(PushUpCounter counter) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.finishSession,
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.finishWorkoutQuestion,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${counter.count} ${AppLocalizations.of(context)!.pushups.toLowerCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.durationLabel}: ${_formatDuration(counter.currentSession?.duration ?? Duration.zero)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.continueButton,
                style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              // Descartar sin guardar
              Navigator.pop(context, null);
            },
            child: Text(AppLocalizations.of(context)!.discard,
                style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.finish),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      // Guardar y finalizar
      counter.endSession();
      if (mounted) Navigator.pop(context);
    } else if (shouldExit == null) {
      // Descartar sin guardar
      counter.resetCount();
      if (mounted) Navigator.pop(context);
    }
    // Si es false, no hace nada (continuar entrenando)
  }
}

