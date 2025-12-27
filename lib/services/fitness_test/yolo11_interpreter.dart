import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../../models/pose_keypoint.dart';

/// Intérprete YOLO11-Pose para TensorFlow Lite
/// 
/// Este intérprete carga el modelo YOLO11-Pose y procesa imágenes
/// de la cámara para detectar keypoints de pose humana.
/// 
/// Especificaciones del modelo:
/// - Entrada: [1, 640, 640, 3] RGB float32 normalizado [0,1]
/// - Salida: [1, num_detections, 56] con bbox + keypoints
class Yolo11Interpreter {
  /// ¿Está el intérprete inicializado?
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Ruta del modelo TFLite
  static const String _modelPath = 'assets/models/yolo11m-pose.tflite';

  /// Tamaño de entrada del modelo
  static const int inputSize = 640;

  /// Umbral de confianza para detecciones
  double confidenceThreshold = 0.25;

  /// Umbral de confianza para keypoints
  double keypointConfidenceThreshold = 0.3;

  /// Nombres de los 17 keypoints COCO
  static const List<String> keypointNames = [
    'nose',
    'left_eye',
    'right_eye',
    'left_ear',
    'right_ear',
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

  /// Inicializa el intérprete YOLO11
  /// 
  /// Carga el modelo TFLite desde assets y prepara los tensores
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verificar que el modelo existe
      final modelData = await rootBundle.load(_modelPath);
      if (modelData.lengthInBytes == 0) {
        throw Exception('Modelo YOLO11 vacío o no encontrado');
      }

      if (kDebugMode) {
        print('✅ YOLO11: Modelo cargado (${modelData.lengthInBytes ~/ 1024} KB)');
      }

      // TODO: Integrar tflite_flutter cuando se agregue la dependencia
      // Por ahora usamos un wrapper que simula la carga del modelo
      // y delegamos a MediaPipe para la detección real
      
      _isInitialized = true;

      if (kDebugMode) {
        print('✅ YOLO11: Intérprete inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ YOLO11: Error inicializando intérprete: $e');
      }
      rethrow;
    }
  }

  /// Detecta pose en una imagen de la cámara
  /// 
  /// [cameraImage] - Frame de la cámara
  /// [sensorOrientation] - Orientación del sensor de la cámara
  /// 
  /// Retorna: PoseDetection con los keypoints detectados
  Future<PoseDetection?> detectPose(
    CameraImage cameraImage,
    int sensorOrientation,
  ) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('⚠️ YOLO11: Intérprete no inicializado');
      }
      return null;
    }

    try {
      // Preprocesar imagen
      final inputTensor = await _preprocessImage(cameraImage, sensorOrientation);
      if (inputTensor == null) return null;

      // TODO: Ejecutar inferencia real con tflite_flutter
      // Por ahora retornamos null y el sistema usará el fallback
      
      // Postprocesar salida
      // final keypoints = _postprocessOutput(outputTensor);

      return null; // Placeholder hasta integrar tflite_flutter
    } catch (e) {
      if (kDebugMode) {
        print('❌ YOLO11: Error en detección: $e');
      }
      return null;
    }
  }

  /// Preprocesa la imagen de la cámara para el modelo
  Future<Float32List?> _preprocessImage(
    CameraImage image,
    int sensorOrientation,
  ) async {
    try {
      // Convertir CameraImage a bytes RGB
      final int width = image.width;
      final int height = image.height;

      // Crear buffer de salida [1, 640, 640, 3]
      final inputBuffer = Float32List(1 * inputSize * inputSize * 3);

      // Obtener planos de la imagen
      if (image.planes.isEmpty) return null;

      // Procesar según formato (YUV420 o BGRA8888)
      if (image.format.group == ImageFormatGroup.yuv420) {
        await _processYUV420(image, inputBuffer, width, height);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        await _processBGRA8888(image, inputBuffer, width, height);
      } else {
        if (kDebugMode) {
          print('⚠️ YOLO11: Formato de imagen no soportado: ${image.format.group}');
        }
        return null;
      }

      return inputBuffer;
    } catch (e) {
      if (kDebugMode) {
        print('❌ YOLO11: Error preprocesando imagen: $e');
      }
      return null;
    }
  }

  /// Procesa imagen YUV420 a tensor RGB normalizado
  Future<void> _processYUV420(
    CameraImage image,
    Float32List buffer,
    int width,
    int height,
  ) async {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    // Escalar a 640x640
    final double scaleX = width / inputSize;
    final double scaleY = height / inputSize;

    int bufferIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final int srcX = (x * scaleX).floor().clamp(0, width - 1);
        final int srcY = (y * scaleY).floor().clamp(0, height - 1);

        final int yIndex = srcY * yRowStride + srcX;
        final int uvIndex = (srcY ~/ 2) * uvRowStride + (srcX ~/ 2) * uvPixelStride;

        final int yValue = yBytes[yIndex];
        final int uValue = uBytes[uvIndex];
        final int vValue = vBytes[uvIndex];

        // YUV a RGB
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        // Normalizar a [0, 1]
        buffer[bufferIndex++] = r / 255.0;
        buffer[bufferIndex++] = g / 255.0;
        buffer[bufferIndex++] = b / 255.0;
      }
    }
  }

  /// Procesa imagen BGRA8888 a tensor RGB normalizado
  Future<void> _processBGRA8888(
    CameraImage image,
    Float32List buffer,
    int width,
    int height,
  ) async {
    final bytes = image.planes[0].bytes;
    final int rowStride = image.planes[0].bytesPerRow;

    final double scaleX = width / inputSize;
    final double scaleY = height / inputSize;

    int bufferIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final int srcX = (x * scaleX).floor().clamp(0, width - 1);
        final int srcY = (y * scaleY).floor().clamp(0, height - 1);

        final int pixelIndex = srcY * rowStride + srcX * 4;

        // BGRA a RGB normalizado
        buffer[bufferIndex++] = bytes[pixelIndex + 2] / 255.0; // R
        buffer[bufferIndex++] = bytes[pixelIndex + 1] / 255.0; // G
        buffer[bufferIndex++] = bytes[pixelIndex] / 255.0; // B
      }
    }
  }

  /// Postprocesa la salida del modelo YOLO11
  /// 
  /// Formato de salida: [1, num_detections, 56]
  /// - 4 valores bbox (x, y, w, h)
  /// - 1 valor confidence
  /// - 1 valor class
  /// - 51 valores keypoints (17 * 3: x, y, conf)
  List<PoseKeypoint> _postprocessOutput(List<double> output, int numDetections) {
    final List<PoseKeypoint> keypoints = [];

    // Encontrar la detección con mayor confianza
    double maxConfidence = 0;
    int bestDetectionIndex = -1;

    for (int i = 0; i < numDetections; i++) {
      final offset = i * 56;
      final confidence = output[offset + 4];

      if (confidence > maxConfidence && confidence > confidenceThreshold) {
        maxConfidence = confidence;
        bestDetectionIndex = i;
      }
    }

    if (bestDetectionIndex == -1) return keypoints;

    // Extraer keypoints de la mejor detección
    final detectionOffset = bestDetectionIndex * 56;
    final keypointsOffset = detectionOffset + 6; // Después de bbox + conf + class

    for (int i = 0; i < 17; i++) {
      final kpOffset = keypointsOffset + i * 3;
      final x = output[kpOffset];
      final y = output[kpOffset + 1];
      final conf = output[kpOffset + 2];

      keypoints.add(PoseKeypoint(
        name: keypointNames[i],
        x: x,
        y: y,
        confidence: conf,
      ));
    }

    return keypoints;
  }

  /// Libera recursos del intérprete
  void dispose() {
    _isInitialized = false;
    if (kDebugMode) {
      print('🔄 YOLO11: Intérprete liberado');
    }
  }
}

