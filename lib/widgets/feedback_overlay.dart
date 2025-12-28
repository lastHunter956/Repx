import 'package:flutter/material.dart';
import '../utils/drawing_utils.dart';

/// Widget para mostrar feedback visual en tiempo real
class FeedbackOverlay extends StatelessWidget {
  final String message;
  final bool isPositive;
  final List<String> errors;

  const FeedbackOverlay({
    super.key,
    required this.message,
    this.isPositive = false,
    this.errors = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _getGlowColor(), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mensaje principal
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIcon(), color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          // Errores adicionales si existen
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      error,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (message.contains('¡Perfecto') || message.contains('¡Bien')) {
      return DrawingUtils.correctColor.withValues(alpha: 0.9);
    } else if (errors.isNotEmpty) {
      return DrawingUtils.errorColor.withValues(alpha: 0.9);
    } else {
      return DrawingUtils.accentColor.withValues(alpha: 0.9);
    }
  }

  Color _getGlowColor() {
    if (message.contains('¡Perfecto') || message.contains('¡Bien')) {
      return DrawingUtils.correctColor.withValues(alpha: 0.5);
    } else if (errors.isNotEmpty) {
      return DrawingUtils.errorColor.withValues(alpha: 0.5);
    } else {
      return DrawingUtils.accentColor.withValues(alpha: 0.5);
    }
  }

  IconData _getIcon() {
    if (message.contains('¡Perfecto') || message.contains('¡Bien')) {
      return Icons.check_circle;
    } else if (errors.isNotEmpty) {
      return Icons.error_outline;
    } else {
      return Icons.info_outline;
    }
  }
}
