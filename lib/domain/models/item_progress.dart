class ItemProgress {
  ItemProgress({
    required this.itemId,
    this.correctAttempts = 0,
    this.incorrectAttempts = 0,
    this.lastSeen,
  });

  final String itemId;
  final int correctAttempts;
  final int incorrectAttempts;
  final DateTime? lastSeen;

  int get priorityScore => incorrectAttempts - (correctAttempts ~/ 2);

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'correctAttempts': correctAttempts,
      'incorrectAttempts': incorrectAttempts,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory ItemProgress.fromMap(Map<dynamic, dynamic> map) {
    return ItemProgress(
      itemId: (map['itemId'] ?? '').toString(),
      correctAttempts: (map['correctAttempts'] ?? 0) as int,
      incorrectAttempts: (map['incorrectAttempts'] ?? 0) as int,
      lastSeen: map['lastSeen'] == null
          ? null
          : DateTime.tryParse(map['lastSeen'].toString()),
    );
  }

  ItemProgress registerAttempt(bool correct) {
    return ItemProgress(
      itemId: itemId,
      correctAttempts: correct ? correctAttempts + 1 : correctAttempts,
      incorrectAttempts: correct ? incorrectAttempts : incorrectAttempts + 1,
      lastSeen: DateTime.now(),
    );
  }
}
