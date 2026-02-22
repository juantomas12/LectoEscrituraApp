class AiQuizQuestion {
  const AiQuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.feedback,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String feedback;

  Map<String, dynamic> toMap() {
    return {
      'prompt': prompt,
      'options': options,
      'correctIndex': correctIndex,
      'correct_index': correctIndex,
      'feedback': feedback,
    };
  }

  factory AiQuizQuestion.fromMap(Map<dynamic, dynamic> map) {
    final rawOptions = map['options'];
    final options = rawOptions is List
        ? rawOptions.map((item) => item.toString()).toList()
        : const <String>[];

    final correctRaw = map['correctIndex'] ?? map['correct_index'] ?? 0;
    final correct = correctRaw is int
        ? correctRaw
        : int.tryParse(correctRaw.toString()) ?? 0;

    return AiQuizQuestion(
      prompt: (map['prompt'] ?? '').toString(),
      options: options,
      correctIndex: correct.clamp(0, options.isEmpty ? 0 : options.length - 1),
      feedback: (map['feedback'] ?? '').toString(),
    );
  }
}
