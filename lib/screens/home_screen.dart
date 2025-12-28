import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'exercise_selection_screen.dart';
import 'history_screen_new.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';
import 'fitness_test/fitness_test_navigator.dart';
import 'package:REPX/l10n/app_localizations.dart';

/// Pantalla de inicio - Diseño ULTRA-PREMIUM inmersivo con efectos avanzados
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Controladores de animación
  late AnimationController _orbController;
  late AnimationController _auroraController;
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late AnimationController _particlesController;

  // Animaciones
  late Animation<double> _orbScale;
  late Animation<double> _orbGlow;
  late Animation<double> _floatOffset;

  @override
  void initState() {
    super.initState();

    // Animación del orbe principal - pulso suave
    _orbController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _orbScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    _orbGlow = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    // Animación aurora de fondo
    _auroraController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Animación de entrada escalonada
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    // Animación flotante continua
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _floatOffset = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Animación de partículas
    _particlesController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _auroraController.dispose();
    _entranceController.dispose();
    _floatController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final padding = size.width * 0.06;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Capa 1: Aurora animada de fondo (optimizada)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _auroraController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: AuroraPainter(
                      animation: _auroraController.value,
                    ),
                    isComplex: true,
                    willChange: true,
                  );
                },
              ),
            ),
          ),

          // Capa 2: Partículas optimizadas con menos elementos
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _particlesController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: DepthParticlesPainter(
                      animation: _particlesController.value,
                    ),
                    isComplex: true,
                    willChange: true,
                  );
                },
              ),
            ),
          ),

          // Capa 3: Gradiente overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.8,
                colors: [
                  Colors.transparent,
                  AppColors.darkBg.withValues(alpha: 0.3),
                  AppColors.darkBg.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Capa 4: Contenido principal
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Column(
                        children: [
                          SizedBox(height: isSmallScreen ? 20 : 40),

                          // Hero Section con Orbe animado
                          _buildHeroSection(l10n, isSmallScreen),

                          SizedBox(height: isSmallScreen ? 30 : 50),

                          // Botón principal START
                          _buildAnimatedEntrance(
                            delay: 0.2,
                            child: _buildPremiumStartButton(context, l10n),
                          ),

                          SizedBox(height: isSmallScreen ? 24 : 40),

                          // Sección de acciones rápidas
                          _buildActionsSection(context, l10n, isSmallScreen),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Footer elegante
                          _buildAnimatedEntrance(
                            delay: 0.8,
                            child: _buildPremiumFooter(l10n),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Hero Section con orbe estático premium
  Widget _buildHeroSection(AppLocalizations l10n, bool isSmallScreen) {
    return _buildAnimatedEntrance(
      delay: 0.0,
      child: Column(
        children: [
          // Orbe 3D con brillo animado (sin movimiento flotante)
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              return _buildFloatingOrb(isSmallScreen);
            },
          ),

          SizedBox(height: isSmallScreen ? 30 : 45),

          // Título con efecto gradiente
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.white,
                AppColors.primaryCyan.withValues(alpha: 0.9),
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              'REPX',
              style: TextStyle(
                fontSize: isSmallScreen ? 42 : 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 12,
                height: 1.1,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Subtítulo elegante
          Text(
            'COUNTER',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.w300,
              color: AppColors.primaryCyan.withValues(alpha: 0.8),
              letterSpacing: 14,
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Badge AI-Powered
          _buildAIBadge(l10n),
        ],
      ),
    );
  }

  /// Orbe flotante con efecto 3D y múltiples capas de brillo
  Widget _buildFloatingOrb(bool isSmallScreen) {
    final orbSize = isSmallScreen ? 100.0 : 120.0;

    return Transform.scale(
      scale: _orbScale.value,
      child: Container(
        width: orbSize + 40,
        height: orbSize + 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Glow exterior amplio
            BoxShadow(
              color:
                  AppColors.primaryCyan.withValues(alpha: _orbGlow.value * 0.3),
              blurRadius: 60,
              spreadRadius: 20,
            ),
            // Glow medio
            BoxShadow(
              color: AppColors.primaryPurple
                  .withValues(alpha: _orbGlow.value * 0.2),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 0.8,
                colors: [
                  AppColors.primaryCyan.withValues(alpha: 0.4),
                  AppColors.primaryPurple.withValues(alpha: 0.3),
                  AppColors.cardBg.withValues(alpha: 0.8),
                ],
              ),
              border: Border.all(
                color: AppColors.primaryCyan.withValues(alpha: _orbGlow.value),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan
                      .withValues(alpha: _orbGlow.value * 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Image.asset(
                  'assets/icon/app_icon_foreground.png',
                  width: orbSize - 10,
                  height: orbSize - 10,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Badge "AI-Powered Training" con diseño premium
  Widget _buildAIBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.aiPoweredTraining,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Botón START profesional con estilo familiar
  Widget _buildPremiumStartButton(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExerciseSelectionScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primaryCyan.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: AppColors.primaryCyan,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              l10n.start.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de acciones rápidas con cards glassmorphism
  Widget _buildActionsSection(
      BuildContext context, AppLocalizations l10n, bool isSmallScreen) {
    return Column(
      children: [
        // Fitness Test Card - Destacado
        _buildAnimatedEntrance(
          delay: 0.4,
          child: _buildFitnessTestCard(context),
        ),

        SizedBox(height: isSmallScreen ? 10 : 14),

        // Row de History y Settings
        _buildAnimatedEntrance(
          delay: 0.5,
          child: Row(
            children: [
              Expanded(
                child: _buildGlassCard(
                  icon: Icons.history_rounded,
                  label: l10n.history,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HistoryScreenNew()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassCard(
                  icon: Icons.settings_rounded,
                  label: l10n.settings,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 10 : 14),

        // Personal Trainer Card
        _buildAnimatedEntrance(
          delay: 0.6,
          child: _buildTrainerCard(context, l10n),
        ),
      ],
    );
  }

  /// Card Fitness Test con diseño limpio
  Widget _buildFitnessTestCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FitnessTestNavigator()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: AppColors.primaryPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fitnessTestCard,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.fitnessTestDetails,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Glass Card genérico para History/Settings
  Widget _buildGlassCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _PremiumButton(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card Personal Trainer compacto
  Widget _buildTrainerCard(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ChatbotScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_rounded,
              color: AppColors.primaryCyan,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.personalTrainer,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Footer premium con indicador de estado
  Widget _buildPremiumFooter(AppLocalizations l10n) {
    return Column(
      children: [
        // Línea decorativa con gradiente
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primaryCyan.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Indicador de estado con animación
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successGreen.withOpacity(value * 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Text(
              l10n.systemReady,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.positionDeviceAndStart,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Wrapper para animación de entrada escalonada
  Widget _buildAnimatedEntrance({
    required double delay,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final progress =
            ((_entranceController.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(progress);

        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - curve)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Botón premium con efecto de presión y glassmorphism
class _PremiumButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final LinearGradient? gradient;
  final Color? borderColor;

  const _PremiumButton({
    required this.onTap,
    required this.child,
    this.gradient,
    this.borderColor,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(20),
              border: widget.borderColor != null
                  ? Border.all(
                      color: widget.borderColor!
                          .withValues(alpha: 0.5 + _glow.value * 0.3),
                      width: 1.5,
                    )
                  : null,
              boxShadow: widget.borderColor != null
                  ? [
                      BoxShadow(
                        color: widget.borderColor!
                            .withValues(alpha: 0.2 + _glow.value * 0.2),
                        blurRadius: 16 + _glow.value * 8,
                        spreadRadius: _glow.value * 2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Painter para efecto Aurora Borealis con olas
class AuroraPainter extends CustomPainter {
  final double animation;

  AuroraPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // Aurora 1 - Cyan con olas
    final path1 = Path();
    final wave1 = sin(animation * 2 * pi) * 40;
    path1.moveTo(0, size.height * 0.3 + wave1);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2 + wave1 * 1.3,
      size.width * 0.5,
      size.height * 0.35 + wave1,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5 + wave1 * 0.5,
      size.width,
      size.height * 0.25 + wave1,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryCyan.withValues(alpha: 0.08),
        AppColors.primaryCyan.withValues(alpha: 0.03),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path1, paint);

    // Aurora 2 - Purple con olas
    final path2 = Path();
    final wave2 = sin((animation + 0.3) * 2 * pi) * 35;
    path2.moveTo(size.width, size.height * 0.4 + wave2);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.3 + wave2 * 1.2,
      size.width * 0.4,
      size.height * 0.5 + wave2,
    );
    path2.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.6 + wave2 * 0.8,
      0,
      size.height * 0.35 + wave2,
    );
    path2.lineTo(0, 0);
    path2.lineTo(size.width, 0);
    path2.close();

    paint.shader = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        AppColors.primaryPurple.withValues(alpha: 0.06),
        AppColors.primaryPurple.withValues(alpha: 0.02),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(AuroraPainter oldDelegate) =>
      (animation - oldDelegate.animation).abs() > 0.01;
}

/// Painter para partículas con profundidad 3D (optimizado)
class DepthParticlesPainter extends CustomPainter {
  final double animation;

  // Pre-calcular partículas para mejor rendimiento
  static final List<_ParticleData> _particles = _generateParticles();

  static List<_ParticleData> _generateParticles() {
    final list = <_ParticleData>[];
    final random = Random(42);

    // Partículas lejanas (25)
    for (int i = 0; i < 25; i++) {
      list.add(_ParticleData(
        seedX: random.nextDouble(),
        seedY: random.nextDouble(),
        speed: 0.15 + random.nextDouble() * 0.15,
        size: 0.8 + random.nextDouble() * 1.2,
        opacity: 0.08 + random.nextDouble() * 0.1,
        isCyan: i % 3 == 0,
      ));
    }

    // Partículas medias (15)
    for (int i = 0; i < 15; i++) {
      list.add(_ParticleData(
        seedX: random.nextDouble(),
        seedY: random.nextDouble(),
        speed: 0.25 + random.nextDouble() * 0.2,
        size: 1.5 + random.nextDouble() * 2.0,
        opacity: 0.12 + random.nextDouble() * 0.15,
        isCyan: i % 2 == 0,
      ));
    }

    // Partículas cercanas (8)
    for (int i = 0; i < 8; i++) {
      list.add(_ParticleData(
        seedX: random.nextDouble(),
        seedY: random.nextDouble(),
        speed: 0.4 + random.nextDouble() * 0.3,
        size: 2.5 + random.nextDouble() * 2.5,
        opacity: 0.2 + random.nextDouble() * 0.2,
        isCyan: i % 2 == 0,
      ));
    }

    return list;
  }

  DepthParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in _particles) {
      final offset = (animation * particle.speed) % 1.0;
      final x = size.width * particle.seedX;
      final y =
          (size.height * particle.seedY + size.height * offset) % size.height;

      paint.color =
          (particle.isCyan ? AppColors.primaryCyan : AppColors.primaryPurple)
              .withValues(alpha: particle.opacity);

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(DepthParticlesPainter oldDelegate) => true;
}

/// Datos pre-calculados de partícula
class _ParticleData {
  final double seedX;
  final double seedY;
  final double speed;
  final double size;
  final double opacity;
  final bool isCyan;

  const _ParticleData({
    required this.seedX,
    required this.seedY,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.isCyan,
  });
}
