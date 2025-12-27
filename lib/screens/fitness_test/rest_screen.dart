import 'package:flutter/material.dart';
import 'package:REPX/l10n/app_localizations.dart';
import '../../utils/app_colors.dart';

/// Pantalla de receso/descanso entre ejercicios
class RestScreen extends StatelessWidget {
  /// Tiempo restante en segundos
  final int remainingSeconds;

  /// Próximo ejercicio
  final String? nextExerciseName;

  /// Callback para saltar el receso
  final VoidCallback? onSkip;

  /// ¿Es el segundo receso?
  final bool isSecondRest;

  const RestScreen({
    super.key,
    required this.remainingSeconds,
    this.nextExerciseName,
    this.onSkip,
    this.isSecondRest = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.successGreen.withOpacity(0.1),
                AppColors.darkBg,
                AppColors.darkBg,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título
              Text(
                l10n.restAndStretch,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              // Timer circular grande
              _buildCircularTimer(),
              const SizedBox(height: 40),

              // Mensaje motivacional
              _buildMotivationalMessage(l10n),
              const SizedBox(height: 24),

              // Próximo ejercicio
              if (nextExerciseName != null) _buildNextExerciseInfo(l10n),
              const SizedBox(height: 40),

              // Botón saltar
              if (onSkip != null) _buildSkipButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer() {
    final progress = remainingSeconds / 30; // 30 segundos total

    return Stack(
      alignment: Alignment.center,
      children: [
        // Círculo de progreso
        SizedBox(
          width: 180,
          height: 180,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: AppColors.cardBg,
            valueColor: AlwaysStoppedAnimation<Color>(
              remainingSeconds <= 5 
                  ? AppColors.warningYellow 
                  : AppColors.successGreen,
            ),
          ),
        ),
        // Timer text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              color: AppColors.successGreen,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '00:${remainingSeconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: remainingSeconds <= 5 
                    ? AppColors.warningYellow 
                    : Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage(AppLocalizations l10n) {
    final message = isSecondRest
        ? '🧘 ${l10n.restStretchLegs}'
        : '🧘 ${l10n.restStretchArms}';

    final subMessage = isSecondRest
        ? l10n.preparingLastExercise
        : l10n.preparingNextExercise;

    return Column(
      children: [
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subMessage,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNextExerciseInfo(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_forward,
            color: AppColors.primaryCyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            l10n.nextExercise,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            nextExerciseName!,
            style: TextStyle(
              color: AppColors.primaryCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: onSkip,
      icon: const Icon(
        Icons.skip_next,
        color: Colors.white54,
      ),
      label: Text(
        l10n.skipRest,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
