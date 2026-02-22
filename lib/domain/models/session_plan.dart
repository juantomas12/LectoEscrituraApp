import 'session_block.dart';

class SessionPlan {
  const SessionPlan({
    required this.id,
    required this.title,
    required this.domain,
    required this.ageRange,
    required this.durationLabel,
    required this.modeLabel,
    required this.status,
    required this.totalMinutes,
    required this.objective,
    required this.sourceResourceId,
    required this.sourceResourceTitle,
    required this.blocks,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String domain;
  final String ageRange;
  final String durationLabel;
  final String modeLabel;
  final String status;
  final int totalMinutes;
  final String objective;
  final String sourceResourceId;
  final String sourceResourceTitle;
  final List<SessionBlock> blocks;
  final DateTime createdAt;

  SessionPlan copyWith({
    String? id,
    String? title,
    String? domain,
    String? ageRange,
    String? durationLabel,
    String? modeLabel,
    String? status,
    int? totalMinutes,
    String? objective,
    String? sourceResourceId,
    String? sourceResourceTitle,
    List<SessionBlock>? blocks,
    DateTime? createdAt,
  }) {
    return SessionPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      ageRange: ageRange ?? this.ageRange,
      durationLabel: durationLabel ?? this.durationLabel,
      modeLabel: modeLabel ?? this.modeLabel,
      status: status ?? this.status,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      objective: objective ?? this.objective,
      sourceResourceId: sourceResourceId ?? this.sourceResourceId,
      sourceResourceTitle: sourceResourceTitle ?? this.sourceResourceTitle,
      blocks: blocks ?? this.blocks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'domain': domain,
      'ageRange': ageRange,
      'durationLabel': durationLabel,
      'modeLabel': modeLabel,
      'status': status,
      'totalMinutes': totalMinutes,
      'objective': objective,
      'sourceResourceId': sourceResourceId,
      'sourceResourceTitle': sourceResourceTitle,
      'blocks': blocks.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SessionPlan.fromMap(Map<dynamic, dynamic> map) {
    final rawBlocks = map['blocks'];
    final blocks = rawBlocks is List
        ? rawBlocks
              .whereType<Map>()
              .map((item) => SessionBlock.fromMap(item))
              .toList()
        : const <SessionBlock>[];

    return SessionPlan(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      domain: (map['domain'] ?? '').toString(),
      ageRange: (map['ageRange'] ?? 'INFANTIL (7-12)').toString(),
      durationLabel: (map['durationLabel'] ?? '10-15 MIN').toString(),
      modeLabel: (map['modeLabel'] ?? 'SITUACIÓN DE APRENDIZAJE').toString(),
      status: (map['status'] ?? 'LISTA').toString(),
      totalMinutes: (map['totalMinutes'] ?? 0) is int
          ? (map['totalMinutes'] as int)
          : int.tryParse((map['totalMinutes'] ?? '0').toString()) ?? 0,
      objective: (map['objective'] ?? '').toString(),
      sourceResourceId: (map['sourceResourceId'] ?? '').toString(),
      sourceResourceTitle: (map['sourceResourceTitle'] ?? '').toString(),
      blocks: blocks,
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
