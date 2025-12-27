import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/muscle_wiki_exercise.dart';

class MuscleWikiService {
  static const String _baseUrl = 'https://musclewiki-api.p.rapidapi.com';
  static const String _apiHost = 'musclewiki-api.p.rapidapi.com';
  static const String _apiKey =
      'c302cea32amsh007d0e1f07cefa4p11cfc0jsnfc61916b4174';

  static Map<String, String> get apiHeaders => {
        'x-rapidapi-key': _apiKey,
        'x-rapidapi-host': _apiHost,
      };

  Future<List<MuscleWikiExercise>> getExercises({
    String? muscle,
    String languageCode = 'en',
  }) async {
    final uri = Uri.parse('$_baseUrl/exercises');

    String? apiMuscle = muscle;
    if (muscle != null) {
      // Map display names to API specific names
      switch (muscle.toLowerCase()) {
        case 'abs':
        case 'abdominales':
          apiMuscle = 'Abdominals';
          break;
        case 'quadriceps':
        case 'cuádriceps':
          apiMuscle = 'Quads';
          break;
        // Add other specific mappings if needed,
        // but the filtered list in UI will drive this.
        // If we use English keys in UI logic, we just pass English keys here.
        default:
          apiMuscle = muscle;
      }
    }

    final urlWithParams = apiMuscle != null
        ? uri.replace(queryParameters: {'muscles': apiMuscle})
        : uri;

    final headers = {
      ...apiHeaders,
      'Accept-Language': languageCode,
    };

    try {
      final response = await http.get(
        urlWithParams,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null) {
          final List<dynamic> results = data['results'];
          return results
              .map((json) => MuscleWikiExercise.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching exercises: $e');
    }
  }

  Future<MuscleWikiExercise> getExerciseDetails(int id,
      {String languageCode = 'en'}) async {
    final uri = Uri.parse('$_baseUrl/exercises/$id');
    final headers = {
      ...apiHeaders,
      'Accept-Language': languageCode,
    };

    try {
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return MuscleWikiExercise.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to load exercise details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching exercise details: $e');
    }
  }
}
