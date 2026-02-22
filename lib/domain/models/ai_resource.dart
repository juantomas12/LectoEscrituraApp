import 'ai_quiz_question.dart';

class AiResource {
  const AiResource({
    required this.id,
    required this.title,
    required this.objective,
    required this.instruction,
    required this.ageRange,
    required this.duration,
    required this.mode,
    required this.categoryLabel,
    required this.difficultyLabel,
    required this.activitySteps,
    required this.questions,
    required this.miniGames,
    required this.materials,
    required this.adaptations,
    required this.investigationTitle,
    required this.investigationText,
    required this.playableQuestions,
    required this.createdAt,
    required this.rawJson,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String objective;
  final String instruction;
  final String ageRange;
  final String duration;
  final String mode;
  final String categoryLabel;
  final String difficultyLabel;
  final List<String> activitySteps;
  final List<String> questions;
  final List<String> miniGames;
  final List<String> materials;
  final List<String> adaptations;
  final String investigationTitle;
  final String investigationText;
  final List<AiQuizQuestion> playableQuestions;
  final DateTime createdAt;
  final String rawJson;
  final bool isFavorite;

  AiResource copyWith({
    String? id,
    String? title,
    String? objective,
    String? instruction,
    String? ageRange,
    String? duration,
    String? mode,
    String? categoryLabel,
    String? difficultyLabel,
    List<String>? activitySteps,
    List<String>? questions,
    List<String>? miniGames,
    List<String>? materials,
    List<String>? adaptations,
    String? investigationTitle,
    String? investigationText,
    List<AiQuizQuestion>? playableQuestions,
    DateTime? createdAt,
    String? rawJson,
    bool? isFavorite,
  }) {
    return AiResource(
      id: id ?? this.id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      instruction: instruction ?? this.instruction,
      ageRange: ageRange ?? this.ageRange,
      duration: duration ?? this.duration,
      mode: mode ?? this.mode,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      difficultyLabel: difficultyLabel ?? this.difficultyLabel,
      activitySteps: activitySteps ?? this.activitySteps,
      questions: questions ?? this.questions,
      miniGames: miniGames ?? this.miniGames,
      materials: materials ?? this.materials,
      adaptations: adaptations ?? this.adaptations,
      investigationTitle: investigationTitle ?? this.investigationTitle,
      investigationText: investigationText ?? this.investigationText,
      playableQuestions: playableQuestions ?? this.playableQuestions,
      createdAt: createdAt ?? this.createdAt,
      rawJson: rawJson ?? this.rawJson,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'objective': objective,
      'instruction': instruction,
      'ageRange': ageRange,
      'duration': duration,
      'mode': mode,
      'categoryLabel': categoryLabel,
      'difficultyLabel': difficultyLabel,
      'activitySteps': activitySteps,
      'questions': questions,
      'miniGames': miniGames,
      'materials': materials,
      'adaptations': adaptations,
      'investigationTitle': investigationTitle,
      'investigationText': investigationText,
      'playableQuestions': playableQuestions
          .map((item) => item.toMap())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'rawJson': rawJson,
      'isFavorite': isFavorite,
    };
  }

  factory AiResource.fromMap(Map<dynamic, dynamic> map) {
    List<String> asStringList(dynamic value) {
      if (value is! List) {
        return const [];
      }
      return value.map((item) => item.toString()).toList();
    }

    List<AiQuizQuestion> asQuizList(dynamic value) {
      if (value is! List) {
        return const [];
      }
      return value
          .whereType<Map>()
          .map((item) => AiQuizQuestion.fromMap(item))
          .where(
            (item) => item.prompt.trim().isNotEmpty && item.options.length >= 2,
          )
          .toList();
    }

    return AiResource(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      objective: (map['objective'] ?? '').toString(),
      instruction: (map['instruction'] ?? '').toString(),
      ageRange: (map['ageRange'] ?? '').toString(),
      duration: (map['duration'] ?? '').toString(),
      mode: (map['mode'] ?? '').toString(),
      categoryLabel: (map['categoryLabel'] ?? '').toString(),
      difficultyLabel: (map['difficultyLabel'] ?? '').toString(),
      activitySteps: asStringList(map['activitySteps']),
      questions: asStringList(map['questions']),
      miniGames: asStringList(map['miniGames']),
      materials: asStringList(map['materials']),
      adaptations: asStringList(map['adaptations']),
      investigationTitle: (map['investigationTitle'] ?? '').toString(),
      investigationText: (map['investigationText'] ?? '').toString(),
      playableQuestions: asQuizList(map['playableQuestions']),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      rawJson: (map['rawJson'] ?? '').toString(),
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }
}
