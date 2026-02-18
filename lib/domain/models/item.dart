import 'activity_type.dart';
import 'category.dart';
import 'level.dart';

class Item {
  Item({
    required this.id,
    required this.category,
    required this.level,
    required this.activityType,
    required this.imageAsset,
    this.word,
    this.words = const [],
    this.phrases = const [],
    this.relatedWords = const [],
    this.audioAsset,
    this.ttsText,
  });

  final String id;
  final AppCategory category;
  final AppLevel level;
  final ActivityType activityType;
  final String? word;
  final List<String> words;
  final String imageAsset;
  final List<String> phrases;
  final List<String> relatedWords;
  final String? audioAsset;
  final String? ttsText;

  Item copyWith({
    String? id,
    AppCategory? category,
    AppLevel? level,
    ActivityType? activityType,
    String? word,
    List<String>? words,
    String? imageAsset,
    List<String>? phrases,
    List<String>? relatedWords,
    String? audioAsset,
    String? ttsText,
  }) {
    return Item(
      id: id ?? this.id,
      category: category ?? this.category,
      level: level ?? this.level,
      activityType: activityType ?? this.activityType,
      word: word ?? this.word,
      words: words ?? this.words,
      imageAsset: imageAsset ?? this.imageAsset,
      phrases: phrases ?? this.phrases,
      relatedWords: relatedWords ?? this.relatedWords,
      audioAsset: audioAsset ?? this.audioAsset,
      ttsText: ttsText ?? this.ttsText,
    );
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: (map['id'] ?? '').toString(),
      category: AppCategoryX.fromLabel((map['category'] ?? '').toString()),
      level: AppLevelX.fromInt((map['level'] ?? 1) as int),
      activityType: ActivityTypeX.fromKey(
        (map['activityType'] ?? '').toString(),
      ),
      word: map['word']?.toString(),
      words: (map['words'] as List<dynamic>? ?? const [])
          .map((value) => value.toString().toUpperCase())
          .toList(),
      imageAsset: (map['imageAsset'] ?? '').toString(),
      phrases: (map['phrases'] as List<dynamic>? ?? const [])
          .map((value) => value.toString().toUpperCase())
          .toList(),
      relatedWords: (map['relatedWords'] as List<dynamic>? ?? const [])
          .map((value) => value.toString().toUpperCase())
          .toList(),
      audioAsset: map['audioAsset']?.toString(),
      ttsText: map['ttsText']?.toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.label,
      'level': level.value,
      'activityType': activityType.key,
      'word': word,
      'words': words,
      'imageAsset': imageAsset,
      'phrases': phrases,
      'relatedWords': relatedWords,
      'audioAsset': audioAsset,
      'ttsText': ttsText,
    };
  }
}
