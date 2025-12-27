class MuscleWikiExercise {
  final int id;
  final String name;
  final String target;
  final String category;
  final String difficulty;
  final String description; // Keeping this if available, otherwise empty
  final String videoUrl;
  final List<String> steps;

  MuscleWikiExercise({
    required this.id,
    required this.name,
    required this.target,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.videoUrl,
    required this.steps,
  });

  factory MuscleWikiExercise.fromJson(Map<String, dynamic> json) {
    // Helper to get target muscle
    String targetMuscle = '';
    if (json['primary_muscles'] != null &&
        (json['primary_muscles'] as List).isNotEmpty) {
      targetMuscle = json['primary_muscles'][0];
    } else {
      targetMuscle = json['target'] ?? '';
    }

    // Helper to get video URL
    String videoUrl = '';
    if (json['videos'] != null && (json['videos'] as List).isNotEmpty) {
      videoUrl = json['videos'][0]['url'] ?? '';
    } else if (json['videoURL'] != null &&
        (json['videoURL'] as List).isNotEmpty) {
      videoUrl = json['videoURL'][0];
    } else if (json['videoURL'] is String) {
      videoUrl = json['videoURL'];
    }

    return MuscleWikiExercise(
      id: json['id'] ?? 0,
      name: json['exercise_name'] ?? json['name'] ?? 'Unknown',
      target: targetMuscle,
      category: json['Category'] ?? json['category'] ?? '',
      difficulty: json['Difficulty'] ?? json['difficulty'] ?? '',
      description: json['description'] ?? '',
      videoUrl: videoUrl,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }
}
