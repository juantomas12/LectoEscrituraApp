class SessionBlock {
  const SessionBlock({
    required this.title,
    required this.durationMin,
    required this.lines,
    this.hasGame = false,
  });

  final String title;
  final int durationMin;
  final List<String> lines;
  final bool hasGame;

  SessionBlock copyWith({
    String? title,
    int? durationMin,
    List<String>? lines,
    bool? hasGame,
  }) {
    return SessionBlock(
      title: title ?? this.title,
      durationMin: durationMin ?? this.durationMin,
      lines: lines ?? this.lines,
      hasGame: hasGame ?? this.hasGame,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'durationMin': durationMin,
      'lines': lines,
      'hasGame': hasGame,
    };
  }

  factory SessionBlock.fromMap(Map<dynamic, dynamic> map) {
    final rawLines = map['lines'];
    final lines = rawLines is List
        ? rawLines.map((item) => item.toString()).toList()
        : const <String>[];
    return SessionBlock(
      title: (map['title'] ?? '').toString(),
      durationMin: (map['durationMin'] ?? 0) is int
          ? (map['durationMin'] as int)
          : int.tryParse((map['durationMin'] ?? '0').toString()) ?? 0,
      lines: lines,
      hasGame: map['hasGame'] as bool? ?? false,
    );
  }
}
