import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/app_colors.dart';
import 'package:REPX/l10n/app_localizations.dart';

/// Pantalla de Chatbot - Asistente virtual de entrenamiento conectado a n8n
/// Soporta envío de imágenes para análisis de comida y equipamiento de gym
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  bool _isUploading = false;

  // Configuración de webhooks n8n (PRODUCCIÓN)
  static const String _chatWebhookUrl =
      'https://n8n-practica.jesus-martinez.me/webhook/entrenador';
  static const String _imageWebhookUrl =
      'https://n8n-practica.jesus-martinez.me/webhook/fitness-backend';
  
  late String _sessionId;
  static const String _sessionIdKey = 'fitness_chat_session_id';
  static const String _messagesKey = 'fitness_chat_messages';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  /// Obtiene el locale actual de la app ('es' o 'en')
  String get _currentLocale {
    try {
      final l10n = AppLocalizations.of(context);
      return l10n?.localeName ?? 'es';
    } catch (_) {
      return 'es';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSession();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// Inicializa o recupera el sessionId persistente y carga mensajes guardados
  Future<void> _initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedSessionId = prefs.getString(_sessionIdKey);
    
    if (savedSessionId == null) {
      savedSessionId = const Uuid().v4().replaceAll('-', '');
      await prefs.setString(_sessionIdKey, savedSessionId);
    }
    
    setState(() {
      _sessionId = savedSessionId!;
    });
    
    // Cargar mensajes guardados
    await _loadMessages();
  }
  
  /// Carga los mensajes guardados desde SharedPreferences
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString(_messagesKey);
    
    bool hasMessages = false;
    
    if (messagesJson != null && messagesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        final loadedMessages = decoded.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
        
        if (mounted && loadedMessages.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(loadedMessages);
          });
          hasMessages = true;
          _scrollToBottom();
        }
      } catch (e) {
        // Si hay error al decodificar, ignorar los mensajes guardados
      }
    }
    
    // Solo mostrar mensaje de bienvenida si no hay mensajes guardados
    if (!hasMessages && mounted) {
      _showWelcomeMessage();
    }
  }
  
  /// Muestra el mensaje de bienvenida del bot
  void _showWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final locale = l10n.localeName;

      final welcomeMessage = locale == 'es'
          ? '¡Hola! 👋 Soy tu entrenador personal con IA.\n\n'
              'Puedo ayudarte con:\n'
              '• Crear rutinas personalizadas\n'
              '• Evaluar tu nivel de entrenamiento\n'
              '• Técnicas de ejercicios\n'
              '• Consejos de nutrición y recuperación\n\n'
              '📸 También puedes enviarme fotos de:\n'
              '• **Comida** - Te daré el análisis nutricional\n'
              '• **Máquinas de gym** - Te explicaré cómo usarlas\n\n'
              '¡Pregúntame lo que quieras!'
          : 'Hello! 👋 I\'m your AI personal trainer.\n\n'
              'I can help you with:\n'
              '• Creating personalized routines\n'
              '• Assessing your training level\n'
              '• Exercise techniques\n'
              '• Nutrition and recovery tips\n\n'
              '📸 You can also send me photos of:\n'
              '• **Food** - I\'ll give you nutritional analysis\n'
              '• **Gym machines** - I\'ll explain how to use them\n\n'
              'Ask me anything!';

      _addBotMessage(welcomeMessage);
    });
  }
  
  /// Guarda los mensajes en SharedPreferences
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(_messagesKey, messagesJson);
  }

  /// Limpia el historial y genera nuevo sessionId
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final newSessionId = const Uuid().v4().replaceAll('-', '');
    await prefs.setString(_sessionIdKey, newSessionId);
    await prefs.remove(_messagesKey); // Limpiar mensajes guardados
    
    setState(() {
      _sessionId = newSessionId;
      _messages.clear();
    });

    // Mostrar mensaje de confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Historial limpiado'),
          backgroundColor: AppColors.successGreen.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      // Mostrar mensaje de bienvenida para iniciar nueva conversación
      _showWelcomeMessage();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {FitnessAnalysis? analysis}) {
    setState(() {
      _isTyping = true;
    });

    // Simular tiempo de escritura
    Future.delayed(
        Duration(milliseconds: 800 + (text.length * 10).clamp(0, 1500)), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: text,
          isUser: false,
          analysis: analysis,
        ));
      });
      _saveMessages(); // Persistir mensajes
      _scrollToBottom();
    });
  }

  void _handleSubmit(String text) {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
    });
    _saveMessages(); // Persistir mensajes
    _scrollToBottom();

    // Enviar mensaje de texto al backend
    _sendMessageToN8N(text);
  }

  /// Envía el mensaje de texto al webhook de n8n
  Future<void> _sendMessageToN8N(String message) async {
    setState(() {
      _isTyping = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_chatWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'sessionId': _sessionId,
          'Language': _currentLocale,
        },
        body: jsonEncode({
          'sessionId': _sessionId,
          'action': 'sendMessage',
          'chatInput': message,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty) {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              text: '⚠️ El servidor respondió pero sin contenido.',
              isUser: false,
            ));
          });
          return;
        }

        dynamic data;
        try {
          data = jsonDecode(responseBody);
        } catch (jsonError) {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(text: responseBody, isUser: false));
          });
          return;
        }

        String botMessage;
        if (data is List && data.isNotEmpty) {
          // La API puede devolver type: "text_only" con user_answer
          final item = data[0];
          botMessage = item['user_answer'] ?? item['output'] ?? item['message'] ?? 'Sin respuesta';
        } else if (data is Map) {
          botMessage = data['user_answer'] ?? data['output'] ?? data['message'] ?? 'Sin respuesta';
        } else {
          botMessage = 'Formato de respuesta no reconocido';
        }

        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: botMessage, isUser: false));
        });
        _saveMessages(); // Persistir mensajes
      } else {
        _handleError('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('Error de conexión: ${e.toString()}');
    }

    _scrollToBottom();
  }

  /// Envía imagen al webhook de fitness-backend para análisis
  /// La API espera la imagen como binario directo en el body con Content-Type: image/jpeg
  Future<void> _sendImageToBackend(Uint8List imageBytes, String? caption) async {
    setState(() {
      _isTyping = true;
      _isUploading = true;
    });

    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        // Enviar imagen como binario directo (como Postman)
        final response = await http.post(
          Uri.parse(_imageWebhookUrl),
          headers: {
            'Content-Type': 'image/jpeg',
            'sessionId': _sessionId,
            'Language': _currentLocale,
          },
          body: imageBytes, // Enviar bytes directamente en el body
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        if (response.statusCode == 200) {
          final responseBody = response.body.trim();
          
          if (responseBody.isEmpty) {
            _handleError('El servidor no devolvió análisis');
            return;
          }

          try {
            final data = jsonDecode(responseBody);
            _processAnalysisResponse(data);
          } catch (e) {
            // Si no es JSON, mostrar como texto
            setState(() {
              _isTyping = false;
              _isUploading = false;
              _messages.add(ChatMessage(text: responseBody, isUser: false));
            });
          }
          return; // Éxito, salir del loop
        } else {
          retries++;
          if (retries >= maxRetries) {
            _handleError('Error del servidor después de $maxRetries intentos (${response.statusCode})');
          }
        }
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          _handleError('Error de conexión: ${e.toString()}');
        }
        await Future.delayed(Duration(seconds: retries)); // Backoff exponencial
      }
    }
  }

  /// Procesa la respuesta de análisis del backend
  void _processAnalysisResponse(dynamic data) {
    setState(() {
      _isTyping = false;
      _isUploading = false;
    });

    // Si es una lista, tomar el primer elemento
    Map<String, dynamic> responseData;
    if (data is List && data.isNotEmpty) {
      responseData = data[0] as Map<String, dynamic>;
    } else if (data is Map<String, dynamic>) {
      responseData = data;
    } else {
      setState(() {
        _messages.add(ChatMessage(text: data.toString(), isUser: false));
      });
      _scrollToBottom();
      return;
    }

    String? type = responseData['type'] as String?;
    
    if (type == 'food_analysis' || responseData.containsKey('total_macros') || responseData.containsKey('items')) {
      // Análisis de comida
      // La API usa 'total_macros' y 'items'
      final macrosData = responseData['total_macros'] ?? responseData['macros'];
      final itemsData = responseData['items'] ?? responseData['foods'];
      
      final analysis = FitnessAnalysis(
        type: AnalysisType.food,
        title: responseData['title'] ?? 'Análisis Nutricional',
        summary: responseData['message'] ?? responseData['summary'] ?? '',
        macros: macrosData != null ? MacroNutrients.fromJson(macrosData as Map<String, dynamic>) : null,
        items: (itemsData as List?)?.map((f) => FoodItem.fromJson(f as Map<String, dynamic>)).toList(),
      );
      
      setState(() {
        _messages.add(ChatMessage(
          text: analysis.summary?.isNotEmpty == true ? analysis.summary! : 'Aquí tienes el análisis nutricional:',
          isUser: false,
          analysis: analysis,
        ));
      });
      _saveMessages();
    } else if (type == 'gym_equipment' || responseData.containsKey('machine_name') || responseData.containsKey('exercises')) {
      // Análisis de equipamiento de gym
      final targetMuscles = (responseData['target_muscles'] as List?)?.map((m) => m.toString()).toList();
      
      final analysis = FitnessAnalysis(
        type: AnalysisType.gym,
        title: responseData['machine_name'] ?? responseData['equipment'] ?? responseData['title'] ?? 'Equipamiento de Gym',
        summary: responseData['message'] ?? responseData['summary'] ?? '',
        targetMuscles: targetMuscles,
        exercises: (responseData['exercises'] as List?)?.map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
      
      setState(() {
        _messages.add(ChatMessage(
          text: analysis.summary?.isNotEmpty == true ? analysis.summary! : 'Aquí tienes los ejercicios:',
          isUser: false,
          analysis: analysis,
        ));
      });
      _saveMessages();
    } else if (type == 'text_only' || responseData.containsKey('user_answer')) {
      // Respuesta de texto del chatbot
      String message = responseData['user_answer'] ?? responseData['message'] ?? responseData['output'] ?? '';
      if (message.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(text: message, isUser: false));
        });
        _saveMessages();
      }
    } else {
      // Respuesta de texto normal (fallback)
      String fallbackMessage = responseData['output'] ?? responseData['message'] ?? responseData['text'] ?? jsonEncode(responseData);
      setState(() {
        _messages.add(ChatMessage(text: fallbackMessage, isUser: false));
      });
      _saveMessages();
    }
    _scrollToBottom();
  }

  void _handleError(String errorMessage) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isTyping = false;
      _isUploading = false;
      _messages.add(ChatMessage(
        text: '⚠️ ${l10n.connectionError}\n\n$errorMessage',
        isUser: false,
      ));
    });
    _saveMessages();
  }

  /// Muestra bottom sheet para seleccionar cámara o galería
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '📸 Enviar imagen',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Foto de comida o máquina de gym',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOptionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galería',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryCyan.withOpacity(0.15),
              AppColors.primaryPurple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primaryCyan,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selecciona imagen desde cámara o galería y la envía automáticamente
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85, // Compresión automática
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        
        // Enviar imagen inmediatamente sin preview
        setState(() {
          _messages.add(ChatMessage(
            text: '📷 Imagen enviada',
            isUser: true,
            imageBytes: bytes,
          ));
        });
        _saveMessages(); // Persistir mensaje de imagen
        _scrollToBottom();
        
        // Enviar al backend
        _sendImageToBackend(bytes, null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.errorPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.8,
            colors: [
              AppColors.primaryCyan.withOpacity(0.06),
              AppColors.darkBg,
              AppColors.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessageList()),
              if (_isTyping) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryCyan.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryCyan.withOpacity(0.8),
                        AppColors.primaryPurple.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FitBot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isUploading ? AppColors.warningYellow : AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isUploading ? 'Procesando imagen...' : 'Online • Asistente IA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botón para limpiar historial
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: Colors.white.withOpacity(0.6),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    '¿Limpiar historial?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'Se borrará toda la conversación y se iniciará una nueva sesión.',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Limpiar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isTyping) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.primaryCyan.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Iniciando conversación...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.7),
                    AppColors.primaryPurple.withOpacity(0.5),
                  ],
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Mostrar imagen si existe
                if (message.imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      message.imageBytes!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Burbuja de texto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primaryCyan.withOpacity(0.2)
                        : AppColors.cardBg.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.primaryCyan.withOpacity(0.3)
                          : Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      h1: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      h2: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      h3: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      em: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 14,
                      ),
                      listIndent: 16.0,
                      blockSpacing: 8.0,
                      a: TextStyle(
                        color: AppColors.primaryCyan,
                        decoration: TextDecoration.underline,
                      ),
                      code: TextStyle(
                        color: AppColors.primaryCyan,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    selectable: true,
                  ),
                ),
                // Mostrar card de análisis si existe
                if (message.analysis != null) ...[
                  const SizedBox(height: 12),
                  _buildAnalysisCard(message.analysis!),
                ],
                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye card expandible para análisis
  Widget _buildAnalysisCard(FitnessAnalysis analysis) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: analysis.type == AnalysisType.food
              ? [
                  AppColors.successGreen.withOpacity(0.15),
                  AppColors.primaryCyan.withOpacity(0.1),
                ]
              : [
                  AppColors.primaryPurple.withOpacity(0.15),
                  AppColors.accentMagenta.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: analysis.type == AnalysisType.food
              ? AppColors.successGreen.withOpacity(0.3)
              : AppColors.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Icon(
                analysis.type == AnalysisType.food
                    ? Icons.restaurant_rounded
                    : Icons.fitness_center_rounded,
                color: analysis.type == AnalysisType.food
                    ? AppColors.successGreen
                    : AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                analysis.title ?? 'Análisis',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          iconColor: Colors.white.withOpacity(0.5),
          collapsedIconColor: Colors.white.withOpacity(0.5),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: analysis.type == AnalysisType.food
                  ? _buildFoodAnalysisContent(analysis)
                  : _buildGymAnalysisContent(analysis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodAnalysisContent(FitnessAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Macros totales
        if (analysis.macros != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.successGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize_rounded,
                      size: 14,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Total Nutricional',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroItem('Calorías', '${analysis.macros!.calories}', 'kcal'),
                    _buildMacroItem('Proteína', analysis.macros!.protein.toStringAsFixed(0), 'g'),
                    _buildMacroItem('Carbos', analysis.macros!.carbs.toStringAsFixed(0), 'g'),
                    _buildMacroItem('Grasa', analysis.macros!.fat.toStringAsFixed(0), 'g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Lista de alimentos
        if (analysis.items != null && analysis.items!.isNotEmpty) ...[
          Text(
            'Alimentos detectados:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...analysis.items!.map((food) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y peso
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        food.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (food.weightG != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${food.weightG}g',
                          style: TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                // Macros del alimento
                if (food.calories != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildSmallMacro('${food.calories}', 'kcal'),
                        if (food.protein != null) _buildSmallMacro('${food.protein!.toStringAsFixed(0)}g', 'prot'),
                        if (food.carbs != null) _buildSmallMacro('${food.carbs!.toStringAsFixed(0)}g', 'carbs'),
                        if (food.fat != null) _buildSmallMacro('${food.fat!.toStringAsFixed(0)}g', 'grasa'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildSmallMacro(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildGymAnalysisContent(FitnessAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mostrar músculos objetivo
        if (analysis.targetMuscles != null && analysis.targetMuscles!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 14,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Músculos trabajados:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: analysis.targetMuscles!.map((muscle) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      muscle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Lista de ejercicios
        if (analysis.exercises != null && analysis.exercises!.isNotEmpty)
          ...analysis.exercises!.asMap().entries.map((entry) {
            final exercise = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (exercise.reps != null || exercise.sets != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${exercise.sets ?? 3} series × ${exercise.reps ?? 12} reps',
                      style: TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  // Mostrar tips (instrucciones)
                  if (exercise.tip != null && exercise.tip!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warningYellow.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16,
                            color: AppColors.warningYellow,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exercise.tip!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryCyan.withOpacity(0.7),
                  AppColors.primaryPurple.withOpacity(0.5),
                ],
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analizando imagen...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ] else
                  ...List.generate(3, (index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600 + (index * 200)),
                      builder: (context, value, child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan
                                .withOpacity(0.3 + (value * 0.5)),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppColors.primaryCyan.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón de cámara
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardBg.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primaryCyan,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkBg.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _handleSubmit,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleSubmit(_messageController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryCyan, AppColors.primaryPurple.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ============================================================================
// MODELOS DE DATOS
// ============================================================================

/// Modelo de mensaje de chat con soporte para imágenes
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  final FitnessAnalysis? analysis;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.imageBytes,
    this.analysis,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Convierte el mensaje a JSON para persistencia
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      // No persistimos imageBytes para evitar archivos muy grandes
      // No persistimos analysis ya que es complejo y temporal
    };
  }
  
  /// Crea un ChatMessage desde JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Tipos de análisis soportados
enum AnalysisType { food, gym }

/// Análisis de fitness (comida o equipamiento)
class FitnessAnalysis {
  final AnalysisType type;
  final String? title;
  final String? summary;
  final MacroNutrients? macros;
  final List<FoodItem>? items;
  final List<ExerciseItem>? exercises;
  final List<String>? targetMuscles;

  FitnessAnalysis({
    required this.type,
    this.title,
    this.summary,
    this.macros,
    this.items,
    this.exercises,
    this.targetMuscles,
  });
}

/// Macronutrientes
class MacroNutrients {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  MacroNutrients({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MacroNutrients.fromJson(Map<String, dynamic> json) {
    return MacroNutrients(
      // Soporta múltiples formatos: kcal, calories, calorias
      calories: (json['kcal'] ?? json['calories'] ?? json['calorias'] ?? 0).toInt(),
      // Soporta: protein_g, protein, proteina
      protein: (json['protein_g'] ?? json['protein'] ?? json['proteina'] ?? 0).toDouble(),
      // Soporta: carbs_g, carbs, carbohidratos
      carbs: (json['carbs_g'] ?? json['carbs'] ?? json['carbohidratos'] ?? 0).toDouble(),
      // Soporta: fat_g, fat, grasa
      fat: (json['fat_g'] ?? json['fat'] ?? json['grasa'] ?? 0).toDouble(),
    );
  }
}

/// Item de comida
class FoodItem {
  final String name;
  final int? weightG;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  FoodItem({
    required this.name,
    this.weightG,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // La API puede enviar macros anidados o directos
    final macros = json['macros'] as Map<String, dynamic>?;
    
    return FoodItem(
      name: json['name'] ?? json['nombre'] ?? 'Alimento',
      weightG: (json['weight_g'])?.toInt(),
      // Si hay macros anidados, usarlos; si no, buscar en el nivel principal
      calories: (macros?['kcal'] ?? json['calories'] ?? json['kcal'] ?? json['calorias'])?.toInt(),
      protein: (macros?['protein_g'] ?? json['protein_g'] ?? json['protein'] ?? json['proteina'])?.toDouble(),
      carbs: (macros?['carbs_g'] ?? json['carbs_g'] ?? json['carbs'] ?? json['carbohidratos'])?.toDouble(),
      fat: (macros?['fat_g'] ?? json['fat_g'] ?? json['fat'] ?? json['grasa'])?.toDouble(),
    );
  }
}

/// Item de ejercicio
class ExerciseItem {
  final String name;
  final int? sets;
  final int? reps;
  final String? tip;
  final String? muscleGroup;

  ExerciseItem({
    required this.name,
    this.sets,
    this.reps,
    this.tip,
    this.muscleGroup,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      name: json['name'] ?? json['nombre'] ?? 'Ejercicio',
      sets: (json['sets'] ?? json['series'])?.toInt(),
      reps: (json['reps'] ?? json['repeticiones'])?.toInt(),
      tip: json['tips'] ?? json['tip'] ?? json['consejo'],  // API usa 'tips' (plural)
      muscleGroup: json['muscleGroup'] ?? json['grupoMuscular'],
    );
  }
}
