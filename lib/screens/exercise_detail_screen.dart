import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/muscle_wiki_service.dart';
import '../models/muscle_wiki_exercise.dart';
import '../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final MuscleWikiExercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLoadingDetails = true;
  late MuscleWikiExercise _exercise;
  final MuscleWikiService _service = MuscleWikiService();

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    _loadExerciseDetails();
  }

  Future<void> _loadExerciseDetails() async {
    try {
      final languageCode = Provider.of<LocaleProvider>(context, listen: false)
          .locale
          .languageCode;
      // Always fetch details to get the video URL and proper steps
      final details = await _service.getExerciseDetails(
        _exercise.id,
        languageCode: languageCode,
      );
      if (mounted) {
        setState(() {
          _exercise = details;
          _isLoadingDetails = false;
        });
        _initializeVideo();
      }
    } catch (e) {
      debugPrint('Error loading details: $e');
      if (mounted) {
        setState(() => _isLoadingDetails = false);
        // Try initializing video even if fetch fails (in case we had a valid URL somehow)
        _initializeVideo();
      }
    }
  }

  void _initializeVideo() {
    if (_exercise.videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(_exercise.videoUrl),
        httpHeaders: MuscleWikiService.apiHeaders,
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _controller.setLooping(true);
              _controller.setVolume(0.0);
              _controller.play();
            });
          }
        }).catchError((error) {
          debugPrint('Error initializing video: $error');
        });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(_exercise.name, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoadingDetails
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video Player
                  Container(
                    height: 250,
                    color: Colors.black,
                    child: _isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : _exercise.videoUrl.isEmpty
                            ? Center(
                                child: Icon(Icons.videocam_off,
                                    color: Colors.white54, size: 50))
                            : Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primaryCyan)),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags
                        Row(
                          children: [
                            _buildTag(_exercise.target, AppColors.primaryCyan),
                            const SizedBox(width: 8),
                            _buildTag(_exercise.difficulty,
                                _getDifficultyColor(_exercise.difficulty)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Instructions
                        if (_exercise.steps.isNotEmpty) ...[
                          Text("Instrucciones",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 16),
                          ..._exercise.steps.map((step) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 20,
                                        color: AppColors.primaryPurple),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: Text(step,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                fontSize: 14,
                                                height: 1.4))),
                                  ],
                                ),
                              )),
                        ] else if (_exercise.description.isNotEmpty) ...[
                          Text("Descripción",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(_exercise.description,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  height: 1.4)),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    if (difficulty.toLowerCase().contains('begin')) return Colors.greenAccent;
    if (difficulty.toLowerCase().contains('inter')) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
