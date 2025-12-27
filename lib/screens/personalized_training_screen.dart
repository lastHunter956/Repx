import 'package:flutter/material.dart';
import '../services/muscle_wiki_service.dart';
import '../models/muscle_wiki_exercise.dart';
import '../utils/app_colors.dart';
import 'exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import 'package:REPX/l10n/app_localizations.dart';

class PersonalizedTrainingScreen extends StatefulWidget {
  const PersonalizedTrainingScreen({super.key});

  @override
  State<PersonalizedTrainingScreen> createState() =>
      _PersonalizedTrainingScreenState();
}

class _PersonalizedTrainingScreenState
    extends State<PersonalizedTrainingScreen> {
  final MuscleWikiService _service = MuscleWikiService();
  late Future<List<MuscleWikiExercise>> _exercisesFuture;
  String? _selectedMuscle;

  // List of common muscles for filtering (MuscleWiki uses specific names)
  final List<String> _muscles = [
    'Abs',
    'Biceps',
    'Calves',
    'Chest',
    'Forearms',
    'Glutes',
    'Hamstrings',
    'Lats',
    'Lower Back',
    'Quadriceps',
    'Traps',
    'Triceps',
    'Shoulders'
  ];

  final Map<String, String> _spanishMuscleNames = {
    'Abs': 'Abdominales',
    'Biceps': 'Bíceps',
    'Calves': 'Pantorrillas',
    'Chest': 'Pecho',
    'Forearms': 'Antebrazos',
    'Glutes': 'Glúteos',
    'Hamstrings': 'Isquiotibiales',
    'Lats': 'Dorsales',
    'Lower Back': 'Espalda Baja',
    'Quadriceps': 'Cuádriceps',
    'Traps': 'Trapecios',
    'Triceps': 'Tríceps',
    'Shoulders': 'Hombros',
  };

  String? _lastLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLang =
        Provider.of<LocaleProvider>(context).locale.languageCode;
    if (_lastLanguageCode != currentLang) {
      _lastLanguageCode = currentLang;
      // Update future without setState as build will follow
      _exercisesFuture = _service.getExercises(
          muscle: _selectedMuscle, languageCode: currentLang);
    }
  }

  void _filterByMuscle(String? muscle) {
    setState(() {
      _selectedMuscle = muscle;
      final languageCode = Provider.of<LocaleProvider>(context, listen: false)
          .locale
          .languageCode;
      _exercisesFuture =
          _service.getExercises(muscle: muscle, languageCode: languageCode);
    });
  }

  String _getMuscleDisplayName(String muscle) {
    final languageCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    if (languageCode == 'es') {
      return _spanishMuscleNames[muscle] ?? muscle;
    }
    return muscle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppColors.primaryCyan.withOpacity(0.08),
              AppColors.darkBg,
              AppColors.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white.withOpacity(0.8),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!
                            .personalizedTraining, // Localized
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 50,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: _muscles.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedMuscle == null;
                      final languageCode = Provider.of<LocaleProvider>(context)
                          .locale
                          .languageCode;
                      return _buildFilterChip(
                        languageCode == 'es' ? 'Todos' : 'All',
                        isSelected,
                        () => _filterByMuscle(null),
                      );
                    }
                    final muscle = _muscles[index - 1];
                    final isSelected = _selectedMuscle == muscle;
                    return _buildFilterChip(
                      _getMuscleDisplayName(muscle),
                      isSelected,
                      () => _filterByMuscle(muscle),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: FutureBuilder<List<MuscleWikiExercise>>(
                  future: _exercisesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryCyan,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      debugPrint('Error fetching exercises: ${snapshot.error}');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.amber, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading exercises',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _exercisesFuture = _service.getExercises(
                                        muscle: _selectedMuscle);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryCyan,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      debugPrint('No exercises data found');
                      return Center(
                        child: Text(
                          'No exercises found',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      );
                    }

                    final exercises = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        return _buildExerciseItem(exercises[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCyan.withOpacity(0.2)
              : AppColors.cardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryCyan
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryCyan : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(MuscleWikiExercise exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exercise),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
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
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(exercise.difficulty)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercise.difficulty,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDifficultyColor(exercise.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (exercise.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                exercise.description, // Simple description or steps
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category_outlined,
                    size: 14, color: AppColors.primaryCyan),
                const SizedBox(width: 4),
                Text(
                  exercise.category,
                  style: TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.accessibility_new_rounded,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  exercise.target,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    if (difficulty.toLowerCase().contains('begin')) return Colors.greenAccent;
    if (difficulty.toLowerCase().contains('inter')) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
