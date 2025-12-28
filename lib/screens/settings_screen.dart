import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/drawing_utils.dart';
import '../services/settings_service.dart';
import '../services/locale_provider.dart';
import 'package:REPX/l10n/app_localizations.dart';

/// Pantalla de configuración - Diseño moderno con opciones funcionales
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) => _buildContent(context, settings),
    );
  }

  Widget _buildContent(BuildContext context, SettingsService settings) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, DrawingUtils.accentColor],
          ).createShader(bounds),
          child: Text(
            l10n.settings.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sección: Visualización
          _buildSectionHeader(l10n.visualization),
          _buildToggleSetting(
            l10n.showSkeleton,
            l10n.showSkeletonDesc,
            Icons.accessibility_new_rounded,
            settings.showSkeleton,
            (value) => settings.setShowSkeleton(value),
          ),
          _buildToggleSetting(
            l10n.showAngles,
            l10n.showAnglesDesc,
            Icons.architecture_rounded,
            settings.showAngles,
            (value) => settings.setShowAngles(value),
          ),
          _buildToggleSetting(
            l10n.showQualityBar,
            l10n.showQualityBarDesc,
            Icons.analytics_rounded,
            settings.showQualityBar,
            (value) => settings.setShowQualityBar(value),
          ),

          const SizedBox(height: 24),

          // Sección: Audio
          _buildSectionHeader(l10n.audio),
          _buildToggleSetting(
            l10n.sounds,
            l10n.soundsDesc,
            Icons.volume_up_rounded,
            settings.soundEnabled,
            (value) => settings.setSoundEnabled(value),
          ),

          const SizedBox(height: 24),

          // Sección: Idioma
          _buildSectionHeader(l10n.language),
          _buildLanguageSelector(context),

          const SizedBox(height: 24),

          // Sección: Sensibilidad
          _buildSectionHeader(l10n.sensitivity),
          _buildSliderSetting(
            l10n.angleThreshold,
            l10n.angleThresholdDesc,
            Icons.tune_rounded,
            settings.minAngleThreshold,
            60.0,
            120.0,
            (value) => settings.setMinAngleThreshold(value),
          ),

          const SizedBox(height: 24),

          // Info del sistema
          _buildInfoCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: DrawingUtils.accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DrawingUtils.accentColor.withOpacity(0.3),
                  DrawingUtils.secondaryColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: DrawingUtils.correctColor,
            activeTrackColor: DrawingUtils.correctColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                      DrawingUtils.accentColor.withOpacity(0.3),
                      DrawingUtils.secondaryColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DrawingUtils.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toInt()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: DrawingUtils.accentColor,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: DrawingUtils.accentColor,
              overlayColor: DrawingUtils.accentColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 5).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DrawingUtils.accentColor.withOpacity(0.3),
                  DrawingUtils.secondaryColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.languageDesc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DrawingUtils.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<Locale>(
              value: localeProvider.locale,
              dropdownColor: const Color(0xFF1A1E3D),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: [
                DropdownMenuItem(
                  value: const Locale('es'),
                  child: Text(l10n.spanish),
                ),
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(l10n.english),
                ),
              ],
              onChanged: (Locale? locale) {
                if (locale != null) {
                  localeProvider.setLocale(locale);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DrawingUtils.accentColor.withOpacity(0.1),
            DrawingUtils.secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DrawingUtils.accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: DrawingUtils.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.systemInfo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(l10n.version, '1.0.0'),
          _buildInfoRow(l10n.mlModel, 'MediaPipe Pose'),
          _buildInfoRow('Precisión', 'Modelo Accurate'),
          _buildInfoRow('FPS', '~30 cuadros/seg'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

