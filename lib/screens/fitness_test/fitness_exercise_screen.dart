import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../utils/app_colors.dart';
import '../../models/fitness_test/fitness_test_state.dart';
import '../../models/pose_keypoint.dart';
import '../../services/fitness_test/fitness_test_controller.dart';
import '../../widgets/camera_preview_widget.dart';

/// Pantalla de ejercicio con cámara, timer y contador en tiempo real
class FitnessExerciseScreen extends StatefulWidget {
  /// Tipo de ejercicio a realizar
  final FitnessTestExerciseType exerciseType;

  /// Callback cuando termina el tiempo
  final VoidCallback onTimeUp;

  const FitnessExerciseScreen({
    super.key,
    required this.exerciseType,
    required this.onTimeUp,
  });

  @override
  State<FitnessExerciseScreen> createState() => _FitnessExerciseScreenState();
}

class _FitnessExerciseScreenState extends State<FitnessExerciseScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Landscape para pantalla de ejercicio
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Preferir cámara frontal
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Iniciar stream de imágenes
      _cameraController!.startImageStream(_processFrame);
    } catch (e) {
      debugPrint('❌ Error inicializando cámara: $e');
    }
  }

  void _processFrame(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    try {
      final controller = context.read<FitnessTestController>();
      final sensorOrientation = _cameraController?.description.sensorOrientation ?? 0;
      
      await controller.processFrame(image, sensorOrientation);
    } catch (e) {
      debugPrint('Error procesando frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    
    // Restaurar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Consumer<FitnessTestController>(
        builder: (context, controller, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview de fondo (SIN skeleton overlay)
              _buildCameraPreview(controller),

              // Overlay superior con timer y título
              _buildTopOverlay(controller),

              // Mini vista del skeleton (debajo del timer)
              _buildSkeletonMiniPreview(controller),

              // Panel de estadísticas
              _buildStatsPanel(controller),

              // Indicador de fase
              _buildPhaseIndicator(controller),

              // Mensaje motivacional (último ejercicio)
              if (widget.exerciseType == FitnessTestExerciseType.abdominal)
                _buildMotivationalBanner(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview(FitnessTestController controller) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: AppColors.darkBg,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    // Calcular aspect ratio de la cámara (después de rotar para landscape)
    // La cámara captura en portrait, así que el aspect ratio real es height/width
    final cameraValue = _cameraController!.value;
    final cameraAspectRatio = cameraValue.previewSize != null
        ? cameraValue.previewSize!.height / cameraValue.previewSize!.width
        : null;

    return CameraPreviewWidget(
      controller: _cameraController,
      currentPose: null, // No mostrar skeleton aquí
      angles: const {},
      formQuality: controller.counterEngine.currentQuality,
      showSkeleton: false, // Skeleton deshabilitado en la cámara
      showAngles: false,
      showQualityBar: false,
    );
  }

  /// Mini preview del skeleton en un contenedor fijo
  Widget _buildSkeletonMiniPreview(FitnessTestController controller) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 16,
      child: Center(
        child: Container(
          width: 90,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryCyan.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: controller.currentPose != null
                ? CustomPaint(
                    painter: _SkeletonMiniPainter(
                      pose: controller.currentPose!,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.accessibility_new,
                      color: AppColors.primaryCyan.withOpacity(0.4),
                      size: 32,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay(FitnessTestController controller) {
    final remainingSeconds = controller.state.remainingSeconds;
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: remainingSeconds <= 10 
                      ? AppColors.errorPink.withOpacity(0.3)
                      : AppColors.cardBg.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: remainingSeconds <= 10 
                        ? AppColors.errorPink
                        : AppColors.primaryCyan.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: remainingSeconds <= 10 
                          ? AppColors.errorPink 
                          : AppColors.primaryCyan,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeString,
                      style: TextStyle(
                        color: remainingSeconds <= 10 
                            ? AppColors.errorPink 
                            : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // Título del ejercicio
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.exerciseType.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.exerciseType.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPanel(FitnessTestController controller) {
    return Positioned(
      right: 20,
      top: 100,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Contador de reps
            Text(
              'REPETICIONES',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.counterEngine.currentCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Calidad
            Text(
              'CALIDAD',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(controller.counterEngine.currentQuality * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getQualityColor(controller.counterEngine.currentQuality),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(FitnessTestController controller) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility,
              color: AppColors.successGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'ESTADO: ${controller.counterEngine.phaseMessage}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalBanner() {
    return Positioned(
      left: 20,
      top: 100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warningYellow.withOpacity(0.9),
              AppColors.warningYellow.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💪', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '¡ÚLTIMO EJERCICIO - TÚ PUEDES!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(double quality) {
    if (quality >= 0.85) return AppColors.successGreen;
    if (quality >= 0.70) return AppColors.warningYellow;
    return AppColors.errorPink;
  }
}

/// Painter para el mini preview del skeleton
/// Dibuja el skeleton en un contenedor fijo sin depender de la cámara
class _SkeletonMiniPainter extends CustomPainter {
  final PoseDetection pose;

  _SkeletonMiniPainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryCyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Detectar si el cuerpo está horizontal (flexión) o vertical (de pie)
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightHip = pose.getKeypoint('right_hip');
    
    bool isHorizontal = false;
    if (leftShoulder != null && rightHip != null && 
        leftShoulder.isValid && rightHip.isValid) {
      final dx = (leftShoulder.y - rightHip.y).abs();
      final dy = (leftShoulder.x - rightHip.x).abs();
      isHorizontal = dx > dy * 1.5;
    }

    // Calcular bounds del skeleton para centrar
    double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    int validCount = 0;
    for (final kp in pose.keypoints) {
      if (kp.isValid && kp.confidence > 0.3) {
        double kpX, kpY;
        if (isHorizontal) {
          kpX = 1.0 - kp.x;
          kpY = kp.y;
        } else {
          kpX = kp.y;
          kpY = kp.x;
        }
        minX = minX < kpX ? minX : kpX;
        maxX = maxX > kpX ? maxX : kpX;
        minY = minY < kpY ? minY : kpY;
        maxY = maxY > kpY ? maxY : kpY;
        validCount++;
      }
    }

    if (validCount < 3) return; // No dibujar si hay muy pocos puntos

    // Calcular centro y escala para centrar el skeleton
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final rangeX = (maxX - minX).clamp(0.3, 1.0); // Mínimo 30% para evitar zoom excesivo
    final rangeY = (maxY - minY).clamp(0.3, 1.0);
    
    // Escala uniforme para mantener proporciones
    final scale = 0.85 / (rangeX > rangeY ? rangeX : rangeY);
    
    Offset transform(PoseKeypoint kp) {
      double rawX, rawY;
      
      if (isHorizontal) {
        rawX = 1.0 - kp.x;
        rawY = kp.y;
      } else {
        rawX = kp.y;
        rawY = kp.x;
      }
      
      // Centrar y escalar
      final x = ((rawX - centerX) * scale + 0.5) * size.width;
      final y = ((rawY - centerY) * scale + 0.5) * size.height;
      
      return Offset(
        x.clamp(0, size.width),
        y.clamp(0, size.height),
      );
    }

    // Conexiones del skeleton
    final connections = [
      ['left_shoulder', 'right_shoulder'],
      ['left_shoulder', 'left_elbow'],
      ['left_elbow', 'left_wrist'],
      ['right_shoulder', 'right_elbow'],
      ['right_elbow', 'right_wrist'],
      ['left_shoulder', 'left_hip'],
      ['right_shoulder', 'right_hip'],
      ['left_hip', 'right_hip'],
      ['left_hip', 'left_knee'],
      ['left_knee', 'left_ankle'],
      ['right_hip', 'right_knee'],
      ['right_knee', 'right_ankle'],
    ];

    // Dibujar conexiones
    for (final conn in connections) {
      final p1 = pose.getKeypoint(conn[0]);
      final p2 = pose.getKeypoint(conn[1]);
      if (p1 != null && p2 != null && p1.isValid && p2.isValid) {
        canvas.drawLine(transform(p1), transform(p2), paint);
      }
    }

    // Dibujar puntos de articulaciones
    final jointPaint = Paint()
      ..color = AppColors.successGreen
      ..style = PaintingStyle.fill;

    for (final kp in pose.keypoints) {
      if (kp.isValid && kp.confidence > 0.3) {
        final pos = transform(kp);
        canvas.drawCircle(pos, 3, jointPaint);
      }
    }

    // Dibujar cabeza
    final nose = pose.getKeypoint('nose');
    if (nose != null && nose.isValid) {
      final headPaint = Paint()
        ..color = AppColors.primaryCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(transform(nose), 8, headPaint);
    }
  }

  @override
  bool shouldRepaint(_SkeletonMiniPainter oldDelegate) {
    return pose != oldDelegate.pose;
  }
}
