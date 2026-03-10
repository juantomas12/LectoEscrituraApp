import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../core/utils/text_utils.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/item.dart';
import '../../domain/models/item_progress.dart';
import '../../domain/models/level.dart';
import 'dataset_repository.dart';

class LocalDatasetRepository implements DatasetRepository {
  LocalDatasetRepository();

  final List<Item> _allItems = [];
  final Random _random = Random();
  final Map<String, String> _imageOverrides = {};
  final Set<String> _availableAssets = <String>{};

  Future<Set<String>> _loadAvailableAssets() async {
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final manifestDecoded = jsonDecode(manifestRaw);
      if (manifestDecoded is Map<String, dynamic>) {
        return manifestDecoded.keys.toSet();
      }
    } catch (_) {
      // BEST-EFFORT: IF MANIFEST IS NOT AVAILABLE, KEEP DATASET PATHS AS-IS.
    }
    return <String>{};
  }

  String _resolvePreferredImageAsset({
    required String originalPath,
    required Set<String> availableAssets,
  }) {
    if (!originalPath.toLowerCase().endsWith('.svg')) {
      return originalPath;
    }

    final dotIndex = originalPath.lastIndexOf('.');
    if (dotIndex <= 0) {
      return originalPath;
    }
    final base = originalPath.substring(0, dotIndex);
    const candidates = ['.jpg', '.jpeg', '.png', '.webp'];
    for (final extension in candidates) {
      final candidate = '$base$extension';
      if (availableAssets.contains(candidate)) {
        return candidate;
      }
    }
    return originalPath;
  }

  @override
  Future<void> load() async {
    if (_allItems.isNotEmpty) {
      return;
    }
    final raw = await rootBundle.loadString(
      'assets/data/lectoescritura_dataset.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>? ?? const [];
    final availableAssets = await _loadAvailableAssets();
    _availableAssets
      ..clear()
      ..addAll(availableAssets);

    _allItems
      ..clear()
      ..addAll(
        items
            .whereType<Map<String, dynamic>>()
            .map((map) {
              final mutable = Map<String, dynamic>.from(map);
              final imageAsset = (mutable['imageAsset'] ?? '').toString();
              if (imageAsset.isNotEmpty) {
                mutable['imageAsset'] = _resolvePreferredImageAsset(
                  originalPath: imageAsset,
                  availableAssets: availableAssets,
                );
              }
              return mutable;
            })
            .map(Item.fromMap)
            .where((item) => item.id.isNotEmpty),
      );
  }

  @override
  List<Item> getAllItems() {
    return _allItems.map(_withOverride).toList();
  }

  @override
  void setImageOverrides(Map<String, String> overrides) {
    final filtered = <String, String>{};
    for (final entry in overrides.entries) {
      final itemId = entry.key.trim();
      final path = entry.value.trim();
      if (itemId.isEmpty || path.isEmpty) {
        continue;
      }

      // Keep only valid packaged assets; invalid/stale overrides fall back to
      // dataset image so activities never show broken image slots.
      final isValidPackagedAsset = _availableAssets.contains(path);
      final isBestEffortAssetPath =
          _availableAssets.isEmpty && path.startsWith('assets/images/');
      if (!isValidPackagedAsset && !isBestEffortAssetPath) {
        continue;
      }
      filtered[itemId] = path;
    }

    _imageOverrides
      ..clear()
      ..addAll(filtered);
  }

  @override
  Map<String, String> getImageOverrides() {
    return Map<String, String>.from(_imageOverrides);
  }

  Item _withOverride(Item item) {
    final override = _imageOverrides[item.id];
    if (override == null || override.isEmpty) {
      return item;
    }
    return item.copyWith(imageAsset: override);
  }

  bool _passesDifficultyFilter({
    required Item item,
    required ActivityType activityType,
    required Difficulty difficulty,
  }) {
    if (difficulty == Difficulty.secundaria) {
      return true;
    }

    if (activityType == ActivityType.imagenFrase) {
      final phrase = item.phrases.isEmpty ? '' : item.phrases.first;
      return countWords(phrase) <= 8;
    }

    if (activityType == ActivityType.palabraPalabra) {
      final left = item.words.isEmpty ? '' : item.words.first;
      return left.length <= 8;
    }

    final baseWord =
        item.word ?? (item.words.isNotEmpty ? item.words.first : '');
    return baseWord.length <= 8;
  }

  @override
  List<Item> getItems({
    required AppCategory category,
    required AppLevel level,
    required ActivityType activityType,
  }) {
    return _allItems
        .where(
          (item) =>
              (category == AppCategory.mixta || item.category == category) &&
              item.level == level &&
              item.activityType == activityType,
        )
        .map(_withOverride)
        .toList();
  }

  @override
  List<Item> getPrioritizedItems({
    required AppCategory category,
    required AppLevel level,
    required ActivityType activityType,
    required Difficulty difficulty,
    required Map<String, ItemProgress> progressMap,
    required int limit,
  }) {
    final filtered =
        getItems(
          category: category,
          level: level,
          activityType: activityType,
        ).where((item) {
          return _passesDifficultyFilter(
            item: item,
            activityType: activityType,
            difficulty: difficulty,
          );
        }).toList();

    filtered.sort((a, b) {
      final scoreA = progressMap[a.id]?.priorityScore ?? 0;
      final scoreB = progressMap[b.id]?.priorityScore ?? 0;
      final byPriority = scoreB.compareTo(scoreA);
      if (byPriority != 0) {
        return byPriority;
      }
      return _random.nextInt(3) - 1;
    });

    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.take(limit).toList();
  }

  @override
  List<Item> getRandomizedPool({
    required AppCategory category,
    required ActivityType activityType,
    required Difficulty difficulty,
    required int poolSize,
  }) {
    if (poolSize <= 0) {
      return const [];
    }

    final filtered = _allItems
        .where(
          (item) =>
              (category == AppCategory.mixta || item.category == category) &&
              item.activityType == activityType,
        )
        .map(_withOverride)
        .where(
          (item) => _passesDifficultyFilter(
            item: item,
            activityType: activityType,
            difficulty: difficulty,
          ),
        )
        .toList();

    if (filtered.isEmpty) {
      return const [];
    }

    if (filtered.length >= poolSize) {
      return filtered.take(poolSize).toList();
    }

    final output = <Item>[...filtered];
    var replicaIndex = 0;
    while (output.length < poolSize) {
      final source = filtered[replicaIndex % filtered.length];
      output.add(source.copyWith(id: '${source.id}__POOL_${replicaIndex + 1}'));
      replicaIndex++;
    }
    return output;
  }
}
