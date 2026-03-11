import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../core/utils/pedagogical_feedback.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/models/activity_result.dart';
import '../../../domain/models/activity_type.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/difficulty.dart';
import '../../../domain/models/item.dart';
import '../../../domain/models/level.dart';
import '../../viewmodels/progress_view_model.dart';
import '../../widgets/activity_asset_image.dart';
import '../../widgets/game_style.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

enum _LiteracyChallengeMode {
  chooseWord,
  trueFalse,
  missingLetter,
  firstLetter,
  lastLetter,
  countSyllables,
  firstSyllable,
  lastSyllable,
  orderLetters,
  orderPhrase,
}

class _PhrasePrompt {
  const _PhrasePrompt({required this.item, required this.phrase});

  final Item item;
  final String phrase;
}

class _OrderToken {
  const _OrderToken({required this.position, required this.value});

  final int position;
  final String value;
}

class LiteracyChallengeScreen extends ConsumerStatefulWidget {
  const LiteracyChallengeScreen({
    super.key,
    required this.activityType,
    required this.category,
    required this.difficulty,
    required this.level,
  });

  final ActivityType activityType;
  final AppCategory category;
  final Difficulty difficulty;
  final AppLevel level;

  @override
  ConsumerState<LiteracyChallengeScreen> createState() =>
      _LiteracyChallengeScreenState();
}

class _LiteracyChallengeScreenState
    extends ConsumerState<LiteracyChallengeScreen> {
  final Random _random = Random();

  List<Item> _wordPool = [];
  List<Item> _wordTargets = [];
  List<_PhrasePrompt> _phraseTargets = [];

  Item? _targetItem;
  _PhrasePrompt? _targetPhrase;
  List<String> _choices = [];
  List<_OrderToken> _availableTokens = [];
  List<_OrderToken> _selectedTokens = [];

  bool _isLoading = true;
  bool _answered = false;
  int _currentRound = 0;
  int _correct = 0;
  int _incorrect = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _tokenCount = 0;
  DateTime _startedAt = DateTime.now();

  String _feedback = '';
  String _expectedAnswer = '';
  String _answerReveal = '';
  String? _selectedChoice;
  String? _statementWord;
  String? _patternWord;

  _LiteracyChallengeMode get _mode => switch (widget.activityType) {
    ActivityType.eligePalabra => _LiteracyChallengeMode.chooseWord,
    ActivityType.verdaderoFalso => _LiteracyChallengeMode.trueFalse,
    ActivityType.palabraIncompleta => _LiteracyChallengeMode.missingLetter,
    ActivityType.letraInicial => _LiteracyChallengeMode.firstLetter,
    ActivityType.letraFinal => _LiteracyChallengeMode.lastLetter,
    ActivityType.cuentaSilabas => _LiteracyChallengeMode.countSyllables,
    ActivityType.primeraSilaba => _LiteracyChallengeMode.firstSyllable,
    ActivityType.ultimaSilaba => _LiteracyChallengeMode.lastSyllable,
    ActivityType.ordenaLetras => _LiteracyChallengeMode.orderLetters,
    ActivityType.ordenaFrase => _LiteracyChallengeMode.orderPhrase,
    _ => _LiteracyChallengeMode.chooseWord,
  };

  String get _title => switch (widget.activityType) {
    ActivityType.eligePalabra => 'ELIGE LA PALABRA',
    ActivityType.verdaderoFalso => 'VERDADERO O FALSO',
    ActivityType.palabraIncompleta => 'PALABRA INCOMPLETA',
    ActivityType.letraInicial => 'LETRA INICIAL',
    ActivityType.letraFinal => 'LETRA FINAL',
    ActivityType.cuentaSilabas => 'CUENTA SÍLABAS',
    ActivityType.primeraSilaba => 'PRIMERA SÍLABA',
    ActivityType.ultimaSilaba => 'ÚLTIMA SÍLABA',
    ActivityType.ordenaLetras => 'ORDENA LETRAS',
    ActivityType.ordenaFrase => 'ORDENA FRASE',
    _ => 'RETO DE LECTURA',
  };

  String get _instruction => switch (widget.activityType) {
    ActivityType.eligePalabra => 'MIRA LA IMAGEN Y TOCA LA PALABRA CORRECTA',
    ActivityType.verdaderoFalso =>
      'DECIDE SI LA PALABRA COINCIDE CON LA IMAGEN',
    ActivityType.palabraIncompleta =>
      'OBSERVA LA IMAGEN Y COMPLETA LA LETRA QUE FALTA',
    ActivityType.letraInicial => 'OBSERVA LA IMAGEN Y ELIGE LA LETRA INICIAL',
    ActivityType.letraFinal => 'OBSERVA LA IMAGEN Y ELIGE LA LETRA FINAL',
    ActivityType.cuentaSilabas =>
      'OBSERVA LA IMAGEN Y CUENTA CUÁNTAS SÍLABAS TIENE',
    ActivityType.primeraSilaba => 'OBSERVA LA IMAGEN Y ELIGE LA PRIMERA SÍLABA',
    ActivityType.ultimaSilaba => 'OBSERVA LA IMAGEN Y ELIGE LA ÚLTIMA SÍLABA',
    ActivityType.ordenaLetras =>
      'TOCA LAS LETRAS EN ORDEN PARA FORMAR LA PALABRA',
    ActivityType.ordenaFrase =>
      'ORDENA LAS PALABRAS HASTA FORMAR LA FRASE CORRECTA',
    _ => 'COMPLETA EL RETO',
  };

  int get _roundCount => switch (_mode) {
    _LiteracyChallengeMode.orderPhrase => switch (widget.level) {
      AppLevel.uno => 3,
      AppLevel.dos => 4,
      _ => 5,
    },
    _ => switch (widget.level) {
      AppLevel.uno => 4,
      AppLevel.dos => 5,
      _ => 6,
    },
  };

  int get _choiceCount {
    if (_mode == _LiteracyChallengeMode.trueFalse) {
      return 2;
    }
    return switch (widget.level) {
      AppLevel.uno => widget.difficulty == Difficulty.primaria ? 3 : 4,
      AppLevel.dos => widget.difficulty == Difficulty.primaria ? 4 : 5,
      _ => widget.difficulty == Difficulty.primaria ? 4 : 5,
    };
  }

  bool get _usesOrdering {
    return _mode == _LiteracyChallengeMode.orderLetters ||
        _mode == _LiteracyChallengeMode.orderPhrase;
  }

  int get _totalRounds {
    return _mode == _LiteracyChallengeMode.orderPhrase
        ? _phraseTargets.length
        : _wordTargets.length;
  }

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  String _itemWord(Item item) {
    final direct = (item.word ?? '').trim();
    if (direct.isNotEmpty) {
      return toUpperSingleSpace(direct);
    }
    if (item.words.isNotEmpty) {
      return toUpperSingleSpace(item.words.first);
    }
    return '';
  }

  String _normalizedItemWord(Item item) {
    return normalizeWordForLetters(_itemWord(item));
  }

  bool _categoryMatches(AppCategory category) {
    return widget.category == AppCategory.mixta || category == widget.category;
  }

  bool _primaryDifficultyAccepts(String word) {
    if (widget.difficulty == Difficulty.secundaria) {
      return true;
    }
    return word.length <=
        switch (widget.level) {
          AppLevel.uno => 7,
          AppLevel.dos => 9,
          _ => 11,
        };
  }

  bool _supportsWordMode(Item item, {required bool strict}) {
    if (!_categoryMatches(item.category) ||
        item.activityType != ActivityType.imagenPalabra) {
      return false;
    }

    final displayWord = _itemWord(item);
    final normalized = _normalizedItemWord(item);
    if (displayWord.isEmpty || normalized.isEmpty) {
      return false;
    }

    if (strict && !_primaryDifficultyAccepts(normalized)) {
      return false;
    }

    switch (_mode) {
      case _LiteracyChallengeMode.chooseWord:
      case _LiteracyChallengeMode.trueFalse:
        return true;
      case _LiteracyChallengeMode.missingLetter:
        return normalized.length >= 3;
      case _LiteracyChallengeMode.firstLetter:
      case _LiteracyChallengeMode.lastLetter:
        return normalized.length >= 2;
      case _LiteracyChallengeMode.countSyllables:
        final syllables = estimateSpanishSyllables(displayWord);
        if (!strict) {
          return syllables <= 6;
        }
        return syllables <=
            switch (widget.level) {
              AppLevel.uno => 3,
              AppLevel.dos => 4,
              _ => 6,
            };
      case _LiteracyChallengeMode.firstSyllable:
      case _LiteracyChallengeMode.lastSyllable:
        final syllables = splitIntoSpanishSyllables(displayWord);
        if (syllables.length < 2) {
          return false;
        }
        if (!strict) {
          return true;
        }
        return syllables.length <=
            switch (widget.level) {
              AppLevel.uno => 3,
              AppLevel.dos => 4,
              _ => 6,
            };
      case _LiteracyChallengeMode.orderLetters:
        if (normalized.length < 3) {
          return false;
        }
        if (!strict) {
          return true;
        }
        return switch (widget.level) {
          AppLevel.uno => normalized.length <= 5,
          AppLevel.dos => normalized.length >= 4 && normalized.length <= 8,
          _ => normalized.length >= 5,
        };
      case _LiteracyChallengeMode.orderPhrase:
        return false;
    }
  }

  List<Item> _buildWordPool({required bool strict}) {
    final dataset = ref.read(datasetRepositoryProvider);
    final candidates = dataset.getAllItems().where((item) {
      return _supportsWordMode(item, strict: strict);
    }).toList();
    candidates.shuffle(_random);
    return candidates;
  }

  List<_PhrasePrompt> _buildPhrasePool({required bool strict}) {
    final dataset = ref.read(datasetRepositoryProvider);
    final prompts = <_PhrasePrompt>[];
    for (final item in dataset.getAllItems()) {
      if (!_categoryMatches(item.category) ||
          item.activityType != ActivityType.imagenFrase) {
        continue;
      }
      for (final phrase in item.phrases) {
        final normalizedPhrase = toUpperSingleSpace(phrase);
        if (normalizedPhrase.isEmpty) {
          continue;
        }
        final words = countWords(normalizedPhrase);
        if (strict) {
          final fitsLevel = switch (widget.level) {
            AppLevel.uno => words >= 2 && words <= 4,
            AppLevel.dos => words >= 4 && words <= 8,
            _ => words >= 8,
          };
          if (!fitsLevel) {
            continue;
          }
        }
        prompts.add(_PhrasePrompt(item: item, phrase: normalizedPhrase));
      }
    }
    prompts.shuffle(_random);
    return prompts;
  }

  List<T> _pickRounds<T>(List<T> source, int count) {
    if (source.isEmpty || count <= 0) {
      return <T>[];
    }
    if (source.length >= count) {
      return source.take(count).toList();
    }
    final output = <T>[];
    var index = 0;
    while (output.length < count) {
      output.add(source[index % source.length]);
      index++;
    }
    output.shuffle(_random);
    return output;
  }

  Future<void> _prepare() async {
    final strictWordPool = _buildWordPool(strict: true);
    final relaxedWordPool = strictWordPool.length >= _roundCount
        ? strictWordPool
        : _buildWordPool(strict: false);
    final strictPhrasePool = _buildPhrasePool(strict: true);
    final relaxedPhrasePool = strictPhrasePool.length >= _roundCount
        ? strictPhrasePool
        : _buildPhrasePool(strict: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _wordPool = relaxedWordPool;
      _wordTargets = _mode == _LiteracyChallengeMode.orderPhrase
          ? <Item>[]
          : _pickRounds(relaxedWordPool, _roundCount);
      _phraseTargets = _mode == _LiteracyChallengeMode.orderPhrase
          ? _pickRounds(relaxedPhrasePool, _roundCount)
          : <_PhrasePrompt>[];
      _isLoading = false;
      _answered = false;
      _currentRound = 0;
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _startedAt = DateTime.now();
      _feedback = _instruction;
    });

    _prepareRound();
  }

  List<String> _buildOptions({
    required String correct,
    required Iterable<String> distractors,
    required int desiredCount,
  }) {
    final safeCorrect = toUpperSingleSpace(correct);
    final seen = <String>{safeCorrect};
    final output = <String>[safeCorrect];
    final shuffled =
        distractors
            .map(toUpperSingleSpace)
            .where((value) => value.isNotEmpty && value != safeCorrect)
            .toSet()
            .toList()
          ..shuffle(_random);

    for (final candidate in shuffled) {
      if (output.length >= desiredCount) {
        break;
      }
      if (seen.add(candidate)) {
        output.add(candidate);
      }
    }

    output.shuffle(_random);
    return output;
  }

  List<String> _letterPool() {
    final letters = <String>{};
    for (final item in _wordPool) {
      final word = _normalizedItemWord(item);
      if (word.isNotEmpty) {
        letters.add(word[0]);
        letters.add(word[word.length - 1]);
      }
    }
    const support = [
      'A',
      'E',
      'I',
      'O',
      'U',
      'L',
      'M',
      'N',
      'P',
      'R',
      'S',
      'T',
      'C',
      'D',
      'B',
      'G',
    ];
    letters.addAll(support);
    return letters.toList();
  }

  List<String> _syllablePool({required bool first}) {
    final syllables = <String>{};
    for (final item in _wordPool) {
      final parts = splitIntoSpanishSyllables(_itemWord(item));
      if (parts.length < 2) {
        continue;
      }
      syllables.add(first ? parts.first : parts.last);
    }
    return syllables.toList();
  }

  List<String> _countPool(int correct) {
    final counts = <String>{'$correct'};
    for (var value = 1; value <= 6; value++) {
      counts.add('$value');
    }
    return counts.toList();
  }

  int _missingIndex(String word) {
    final preferred = <int>[];
    final fallback = <int>[];
    const vowels = 'AEIOU';
    for (var i = 0; i < word.length; i++) {
      if (i > 0 && i < word.length - 1) {
        fallback.add(i);
        if (vowels.contains(word[i])) {
          preferred.add(i);
        }
      }
    }
    final source = preferred.isNotEmpty ? preferred : fallback;
    if (source.isNotEmpty) {
      return source[_random.nextInt(source.length)];
    }
    return _random.nextInt(word.length);
  }

  void _prepareRound() {
    if (_currentRound >= _totalRounds) {
      _finish();
      return;
    }

    _targetItem = null;
    _targetPhrase = null;
    _choices = [];
    _availableTokens = [];
    _selectedTokens = [];
    _selectedChoice = null;
    _statementWord = null;
    _patternWord = null;
    _expectedAnswer = '';
    _answerReveal = '';
    _tokenCount = 0;

    if (_mode == _LiteracyChallengeMode.orderPhrase) {
      final phrasePrompt = _phraseTargets[_currentRound];
      final words = phrasePrompt.phrase.split(' ');
      final shuffledWords = List<String>.from(words);
      shuffledWords.shuffle(_random);
      while (listEquals(shuffledWords, words)) {
        shuffledWords.shuffle(_random);
      }

      _targetPhrase = phrasePrompt;
      _expectedAnswer = phrasePrompt.phrase;
      _answerReveal = phrasePrompt.phrase;
      _feedback = 'ORDENA LA FRASE CORRECTA';
      _availableTokens = [
        for (var i = 0; i < shuffledWords.length; i++)
          _OrderToken(position: i, value: shuffledWords[i]),
      ];
      _tokenCount = words.length;
    } else {
      final item = _wordTargets[_currentRound];
      final displayWord = _itemWord(item);
      final normalizedWord = _normalizedItemWord(item);
      _targetItem = item;

      switch (_mode) {
        case _LiteracyChallengeMode.chooseWord:
          _expectedAnswer = displayWord;
          _answerReveal = displayWord;
          _choices = _buildOptions(
            correct: displayWord,
            distractors: _wordPool.map(_itemWord),
            desiredCount: _choiceCount,
          );
          _feedback = 'TOCA LA PALABRA CORRECTA';
          break;
        case _LiteracyChallengeMode.trueFalse:
          final otherWords = _wordPool
              .map(_itemWord)
              .where((word) => word.isNotEmpty && word != displayWord)
              .toList();
          final matches = otherWords.isEmpty ? true : _random.nextBool();
          _statementWord = matches
              ? displayWord
              : otherWords[_random.nextInt(otherWords.length)];
          _expectedAnswer = _statementWord == displayWord ? 'SÍ' : 'NO';
          _answerReveal = _expectedAnswer;
          _choices = const ['SÍ', 'NO'];
          _feedback = '¿LA PALABRA COINCIDE CON LA IMAGEN?';
          break;
        case _LiteracyChallengeMode.missingLetter:
          final hiddenIndex = _missingIndex(normalizedWord);
          _expectedAnswer = normalizedWord[hiddenIndex];
          _patternWord =
              '${normalizedWord.substring(0, hiddenIndex)}_${normalizedWord.substring(hiddenIndex + 1)}';
          _answerReveal = normalizedWord;
          _choices = _buildOptions(
            correct: _expectedAnswer,
            distractors: _letterPool(),
            desiredCount: _choiceCount,
          );
          _feedback = '¿QUÉ LETRA FALTA?';
          break;
        case _LiteracyChallengeMode.firstLetter:
          _expectedAnswer = normalizedWord[0];
          _answerReveal = _expectedAnswer;
          _choices = _buildOptions(
            correct: _expectedAnswer,
            distractors: _letterPool(),
            desiredCount: _choiceCount,
          );
          _feedback = '¿CON QUÉ LETRA EMPIEZA?';
          break;
        case _LiteracyChallengeMode.lastLetter:
          _expectedAnswer = normalizedWord[normalizedWord.length - 1];
          _answerReveal = _expectedAnswer;
          _choices = _buildOptions(
            correct: _expectedAnswer,
            distractors: _letterPool(),
            desiredCount: _choiceCount,
          );
          _feedback = '¿CON QUÉ LETRA TERMINA?';
          break;
        case _LiteracyChallengeMode.countSyllables:
          _expectedAnswer = '${estimateSpanishSyllables(displayWord)}';
          _answerReveal = '$_expectedAnswer SÍLABAS';
          _choices = _buildOptions(
            correct: _expectedAnswer,
            distractors: _countPool(int.parse(_expectedAnswer)),
            desiredCount: _choiceCount,
          );
          _feedback = '¿CUÁNTAS SÍLABAS TIENE?';
          break;
        case _LiteracyChallengeMode.firstSyllable:
          _expectedAnswer = splitIntoSpanishSyllables(displayWord).first;
          _answerReveal = _expectedAnswer;
          _choices = _buildOptions(
            correct: _expectedAnswer,
            distractors: _syllablePool(first: true),
            desiredCount: _choiceCount,
          );
          _feedback = '¿CUÁL ES LA PRIMERA SÍLABA?';
          break;
        case _LiteracyChallengeMode.lastSyllable:
          _expectedAnswer = splitIntoSpanishSyllables(displayWord).last;
          _answerReveal = _expectedAnswer;
          _choices = _buildOptions(
            correct: _expectedAnswer,
            distractors: _syllablePool(first: false),
            desiredCount: _choiceCount,
          );
          _feedback = '¿CUÁL ES LA ÚLTIMA SÍLABA?';
          break;
        case _LiteracyChallengeMode.orderLetters:
          final letters = normalizedWord.split('');
          final shuffledLetters = List<String>.from(letters)..shuffle(_random);
          while (listEquals(shuffledLetters, letters)) {
            shuffledLetters.shuffle(_random);
          }
          _expectedAnswer = normalizedWord;
          _answerReveal = normalizedWord;
          _feedback = 'TOCA LAS LETRAS EN ORDEN';
          _availableTokens = [
            for (var i = 0; i < shuffledLetters.length; i++)
              _OrderToken(position: i, value: shuffledLetters[i]),
          ];
          _tokenCount = letters.length;
          break;
        case _LiteracyChallengeMode.orderPhrase:
          break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _answered = false;
      _selectedChoice = null;
    });
  }

  Future<void> _registerAnswer(bool isCorrect) async {
    final itemId = _targetItem?.id ?? _targetPhrase?.item.id;
    if (itemId == null || itemId.isEmpty) {
      return;
    }

    await ref
        .read(progressViewModelProvider.notifier)
        .registerAttempt(
          itemId: itemId,
          correct: isCorrect,
          activityType: widget.activityType,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _answered = true;
      if (isCorrect) {
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _feedback = PedagogicalFeedback.positive(
          streak: _streak,
          totalCorrect: _correct,
        );
      } else {
        _incorrect++;
        _streak = 0;
        _feedback =
            '${PedagogicalFeedback.retry(attemptsOnCurrent: 1)}. RESPUESTA: $_answerReveal';
      }
    });
  }

  Future<void> _selectChoice(String choice) async {
    if (_answered) {
      return;
    }
    setState(() => _selectedChoice = choice);
    final isCorrect =
        normalizeForComparison(choice, ignoreAccents: true) ==
        normalizeForComparison(_expectedAnswer, ignoreAccents: true);
    await _registerAnswer(isCorrect);
  }

  void _takeToken(_OrderToken token) {
    if (_answered) {
      return;
    }
    setState(() {
      _availableTokens.removeWhere((entry) => entry.position == token.position);
      _selectedTokens.add(token);
    });
  }

  void _returnToken(_OrderToken token) {
    if (_answered) {
      return;
    }
    setState(() {
      _selectedTokens.removeWhere((entry) => entry.position == token.position);
      _availableTokens.add(token);
      _availableTokens.sort((a, b) => a.position.compareTo(b.position));
    });
  }

  void _clearTokens() {
    if (_answered) {
      return;
    }
    setState(() {
      _availableTokens = [..._availableTokens, ..._selectedTokens]
        ..sort((a, b) => a.position.compareTo(b.position));
      _selectedTokens = [];
    });
  }

  Future<void> _checkOrdering() async {
    if (_answered) {
      return;
    }
    if (_selectedTokens.length != _tokenCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('COMPLETA TODAS LAS PIEZAS PRIMERO')),
      );
      return;
    }

    final separator = _mode == _LiteracyChallengeMode.orderPhrase ? ' ' : '';
    final attempt = _selectedTokens.map((token) => token.value).join(separator);
    final isCorrect =
        normalizeForComparison(attempt, ignoreAccents: true) ==
        normalizeForComparison(_expectedAnswer, ignoreAccents: true);
    await _registerAnswer(isCorrect);
  }

  Future<void> _nextRound() async {
    if (!_answered) {
      return;
    }
    setState(() {
      _currentRound++;
    });
    _prepareRound();
  }

  Future<void> _finish() async {
    final result = ActivityResult(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      category: widget.category,
      level: widget.level,
      activityType: widget.activityType,
      correct: _correct,
      incorrect: _incorrect,
      durationInSeconds: DateTime.now().difference(_startedAt).inSeconds,
      bestStreak: _bestStreak,
      createdAt: DateTime.now(),
    );

    await ref.read(progressViewModelProvider.notifier).saveResult(result);

    if (!mounted) {
      return;
    }

    final action = await Navigator.of(context).push<ResultAction>(
      MaterialPageRoute(
        builder: (_) =>
            ResultsScreen(result: result, canReinforceErrors: false),
      ),
    );

    if (!mounted) {
      return;
    }

    if (action == ResultAction.repetir) {
      setState(() {
        _isLoading = true;
      });
      await _prepare();
      return;
    }

    Navigator.of(context).pop();
  }

  Widget _buildFeedbackCard() {
    return GamePanel(
      backgroundColor: const Color(0xFFFFF8EE),
      borderColor: const Color(0xFFFFD7B7),
      child: UpperText(
        _feedback,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFF9D4A16),
        ),
      ),
    );
  }

  Widget _buildPromptDetails() {
    if (_mode == _LiteracyChallengeMode.trueFalse && _statementWord != null) {
      return _PromptPill(
        label: _statementWord!,
        icon: Icons.fact_check_rounded,
      );
    }
    if (_mode == _LiteracyChallengeMode.missingLetter && _patternWord != null) {
      return _PromptPill(label: _patternWord!, icon: Icons.edit_note_rounded);
    }
    if (_mode == _LiteracyChallengeMode.orderLetters &&
        _expectedAnswer.isNotEmpty) {
      return _PromptPill(
        label: '${_expectedAnswer.length} LETRAS',
        icon: Icons.sort_by_alpha_rounded,
      );
    }
    if (_mode == _LiteracyChallengeMode.orderPhrase &&
        _expectedAnswer.isNotEmpty) {
      return _PromptPill(
        label: '${countWords(_expectedAnswer)} PALABRAS',
        icon: Icons.format_align_left_rounded,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPromptPanel() {
    final assetPath = _targetItem?.imageAsset ?? _targetPhrase?.item.imageAsset;
    final semanticsLabel = _targetItem != null
        ? _itemWord(_targetItem!)
        : _targetPhrase?.item.word;

    return GamePanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UpperText(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF13203F),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: assetPath == null || assetPath.isEmpty
                ? const Center(child: UpperText('IMAGEN NO DISPONIBLE'))
                : ActivityAssetImage(
                    assetPath: assetPath,
                    semanticsLabel: semanticsLabel,
                  ),
          ),
          const SizedBox(height: 14),
          _buildPromptDetails(),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(String option) {
    final isSelected = _selectedChoice == option;
    final isCorrect =
        normalizeForComparison(option, ignoreAccents: true) ==
        normalizeForComparison(_expectedAnswer, ignoreAccents: true);

    final backgroundColor = _answered
        ? isCorrect
              ? const Color(0xFFE2F8EA)
              : isSelected
              ? const Color(0xFFFFE3E0)
              : Colors.white
        : isSelected
        ? const Color(0xFFE8F0FF)
        : Colors.white;
    final borderColor = _answered
        ? isCorrect
              ? const Color(0xFF26A65B)
              : isSelected
              ? const Color(0xFFD8614D)
              : const Color(0xFFD6DEEC)
        : isSelected
        ? kGameAccent
        : const Color(0xFFD6DEEC);
    final textColor = _answered
        ? isCorrect
              ? const Color(0xFF18743E)
              : isSelected
              ? const Color(0xFFA13625)
              : const Color(0xFF1A2745)
        : const Color(0xFF1A2745);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _answered ? null : () => _selectChoice(option),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.4 : 1.6,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Center(
            child: UpperText(
              option,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoicePanel(bool compact) {
    final crossAxisCount = _choices.length <= 2
        ? 2
        : compact
        ? 2
        : 3;
    final childAspectRatio = _choices.length <= 2 ? 2.8 : 2.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          child: GridView.builder(
            itemCount: _choices.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              return _buildChoiceButton(_choices[index]);
            },
          ),
        ),
        if (_answered) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _nextRound,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: const UpperText('SIGUIENTE'),
          ),
        ],
      ],
    );
  }

  Widget _buildTokenArea({
    required String title,
    required List<_OrderToken> tokens,
    required void Function(_OrderToken token) onTap,
    required Color backgroundColor,
    required Color borderColor,
    required String emptyText,
  }) {
    return GamePanel(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UpperText(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF354B72),
            ),
          ),
          const SizedBox(height: 10),
          if (tokens.isEmpty)
            UpperText(
              emptyText,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6D7D9C),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tokens.map((token) {
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _answered ? null : () => onTap(token),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFCAD6E7)),
                    ),
                    child: UpperText(
                      token.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF172546),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderingPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTokenArea(
          title: 'TU RESPUESTA',
          tokens: _selectedTokens,
          onTap: _returnToken,
          backgroundColor: const Color(0xFFFFF6E8),
          borderColor: const Color(0xFFFFD7B7),
          emptyText: 'TOCA PIEZAS ABAJO PARA CONSTRUIR LA RESPUESTA',
        ),
        const SizedBox(height: 12),
        _buildTokenArea(
          title: 'PIEZAS DISPONIBLES',
          tokens: _availableTokens,
          onTap: _takeToken,
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFD6DEEC),
          emptyText: 'YA HAS USADO TODAS LAS PIEZAS',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _answered ? null : _clearTokens,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const UpperText('BORRAR'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _answered ? _nextRound : _checkOrdering,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: UpperText(_answered ? 'SIGUIENTE' : 'COMPROBAR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final solvedCount = _answered ? _currentRound + 1 : _currentRound;

    return GameScaffold(
      title: _title,
      instructionText: _instruction,
      progressCurrent: solvedCount,
      progressTotal: _totalRounds,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _totalRounds == 0
          ? Center(
              child: UpperText(
                _mode == _LiteracyChallengeMode.orderPhrase
                    ? 'NO HAY FRASES DISPONIBLES EN ESTA CATEGORÍA'
                    : 'NO HAY PALABRAS DISPONIBLES EN ESTA CATEGORÍA',
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GameProgressHeader(
                      label: 'TU PROGRESO',
                      current: solvedCount,
                      total: _totalRounds,
                      trailingLabel: '⭐ $_correct',
                    ),
                    const SizedBox(height: 12),
                    _buildFeedbackCard(),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 860;
                        if (compact) {
                          return Column(
                            children: [
                              _buildPromptPanel(),
                              const SizedBox(height: 12),
                              _usesOrdering
                                  ? _buildOrderingPanel()
                                  : _buildChoicePanel(true),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 11, child: _buildPromptPanel()),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 10,
                              child: _usesOrdering
                                  ? _buildOrderingPanel()
                                  : _buildChoicePanel(false),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PromptPill extends StatelessWidget {
  const _PromptPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC7D8FF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C86EA)),
          const SizedBox(width: 10),
          Expanded(
            child: UpperText(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF17315E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
