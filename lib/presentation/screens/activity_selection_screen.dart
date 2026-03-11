import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/letter_match_mode.dart';
import '../../domain/models/level.dart';
import '../viewmodels/progress_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/upper_text.dart';
import 'activities/discrimination_screen.dart';
import 'activities/exact_change_store_screen.dart';
import 'activities/inverse_discrimination_screen.dart';
import 'activities/letter_target_screen.dart';
import 'activities/literacy_challenge_screen.dart';
import 'activities/match_image_phrase_screen.dart';
import 'activities/match_image_word_screen.dart';
import 'activities/match_word_word_screen.dart';
import 'activities/roulette_letters_screen.dart';
import 'activities/sound_match_screen.dart';
import 'activities/write_word_screen.dart';

class ActivitySelectionScreen extends ConsumerStatefulWidget {
  const ActivitySelectionScreen({
    super.key,
    required this.category,
    required this.activityType,
    required this.difficulty,
    this.initialGameLevel,
    this.initialVowelMode,
    this.autoLaunchOnLoad = false,
  });

  final AppCategory category;
  final ActivityType activityType;
  final Difficulty difficulty;
  final int? initialGameLevel;
  final String? initialVowelMode;
  final bool autoLaunchOnLoad;

  @override
  ConsumerState<ActivitySelectionScreen> createState() =>
      _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState
    extends ConsumerState<ActivitySelectionScreen> {
  static const _vowels = ['A', 'E', 'I', 'O', 'U'];
  static const _accent = Color(0xFF2C86EA);
  final Random _random = Random();

  int _selectedGameLevel = 1;
  bool _didApplyAutoLevel = false;
  bool _didAutoStartSingleLevel = false;
  bool _didAutoLaunchInitialLevel = false;
  String _selectedVowelMode = 'A';

  @override
  void initState() {
    super.initState();
    final initialVowel = (widget.initialVowelMode ?? '').trim().toUpperCase();
    if (_vowels.contains(initialVowel) || initialVowel == 'RANDOM') {
      _selectedVowelMode = initialVowel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLetterVowelsGame =
        widget.activityType == ActivityType.letraObjetivo;
    final levels = _levelsForGame(widget.activityType);
    final settings = ref.watch(settingsViewModelProvider);
    final progressVm = ref.read(progressViewModelProvider.notifier);

    if (!_didApplyAutoLevel &&
        widget.initialGameLevel != null &&
        levels.contains(widget.initialGameLevel)) {
      _selectedGameLevel = widget.initialGameLevel!;
      _didApplyAutoLevel = true;
    }

    if (!levels.contains(_selectedGameLevel)) {
      _selectedGameLevel = levels.first;
    }

    if (!_didAutoStartSingleLevel && levels.length == 1) {
      _didAutoStartSingleLevel = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _openActivity(context, widget.activityType, levels.first);
      });
    }

    if (!isLetterVowelsGame &&
        !_didApplyAutoLevel &&
        settings.autoAdjustLevel &&
        levels.length > 1) {
      _didApplyAutoLevel = true;
      final recommended = progressVm.recommendedLevelForGame(
        widget.activityType,
        maxLevel: levels.last,
      );
      _selectedGameLevel = levels.contains(recommended)
          ? recommended
          : levels.first;
    }

    if (!_didAutoLaunchInitialLevel &&
        widget.autoLaunchOnLoad &&
        widget.initialGameLevel != null &&
        levels.contains(widget.initialGameLevel)) {
      _didAutoLaunchInitialLevel = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _openActivity(context, widget.activityType, widget.initialGameLevel!);
      });
    }

    final isSingleLevel = levels.length == 1;
    final gameTitle = _displayGameTitle(widget.activityType);
    final gameIcon = _displayGameIcon(widget.activityType);
    final gameColor = _displayGameColor(widget.activityType);
    final vowelModes = [..._vowels, 'RANDOM'];

    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 84,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD7DFEC)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: _accent,
                        tooltip: 'VOLVER',
                      ),
                      const Expanded(
                        child: UpperText(
                          'SELECCIÓN DE JUEGO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF101A39),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(58),
                          ),
                          child: Icon(gameIcon, size: 82, color: gameColor),
                        ),
                      ),
                      const SizedBox(height: 26),
                      UpperText(
                        gameTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101A39),
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 20),
                      UpperText(
                        isLetterVowelsGame
                            ? 'MODOS DEL JUEGO'
                            : 'NIVELES DEL JUEGO',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          color: _accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!isLetterVowelsGame)
                        GridView.builder(
                          itemCount: levels.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.25,
                              ),
                          itemBuilder: (context, index) {
                            final level = levels[index];
                            return _LevelGridCard(
                              indexLabel: '$level',
                              title: 'NIVEL $level',
                              selected: _selectedGameLevel == level,
                              accentColor: _levelAccentColor(level),
                              onTap: () => setState(() {
                                _selectedGameLevel = level;
                              }),
                              onPlay: () => _openActivity(
                                context,
                                widget.activityType,
                                level,
                              ),
                            );
                          },
                        )
                      else
                        GridView.builder(
                          itemCount: vowelModes.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.25,
                              ),
                          itemBuilder: (context, index) {
                            final mode = vowelModes[index];
                            final isRandom = mode == 'RANDOM';
                            return _LevelGridCard(
                              indexLabel: isRandom ? '*' : mode,
                              title: isRandom
                                  ? 'TODAS ALEATORIO'
                                  : 'VOCAL $mode',
                              selected: _selectedVowelMode == mode,
                              accentColor: _vowelModeAccentColor(mode),
                              onTap: () => setState(() {
                                _selectedVowelMode = mode;
                              }),
                              onPlay: () => _openActivity(
                                context,
                                widget.activityType,
                                _selectedGameLevel,
                              ),
                            );
                          },
                        ),
                      if (!isSingleLevel) ...[
                        const SizedBox(height: 8),
                        UpperText(
                          _levelDescription(
                            widget.activityType,
                            _selectedGameLevel,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4B5E82),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (settings.autoAdjustLevel &&
                            levels.length > 1 &&
                            !isLetterVowelsGame)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: UpperText(
                              'NIVEL SUGERIDO AUTOMÁTICO: $_selectedGameLevel',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4B5E82),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                      if (isSingleLevel)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: UpperText(
                            'INICIO AUTOMÁTICO (JUEGO DE NIVEL ÚNICO)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5A6B8B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayGameTitle(ActivityType type) {
    return switch (type) {
      ActivityType.imagenPalabra => 'IMAGEN Y PALABRA',
      ActivityType.escribirPalabra => 'ESCRIBIR PALABRA',
      ActivityType.palabraPalabra => 'PALABRA CON PALABRA',
      ActivityType.imagenFrase => 'IMAGEN Y FRASE',
      ActivityType.sonidos => 'JUEGO DE SONIDOS',
      ActivityType.letraObjetivo => 'LETRAS Y VOCALES',
      ActivityType.cambioExacto => 'TIENDA DE CHUCHES',
      ActivityType.ruletaLetras => 'RULETA DE LETRAS',
      ActivityType.discriminacion => 'DISCRIMINACIÓN VISUAL',
      ActivityType.discriminacionInversa => 'DISCRIMINACIÓN INVERSA',
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
    };
  }

  IconData _displayGameIcon(ActivityType type) {
    return switch (type) {
      ActivityType.imagenPalabra => Icons.image_search_rounded,
      ActivityType.escribirPalabra => Icons.edit_rounded,
      ActivityType.palabraPalabra => Icons.compare_arrows_rounded,
      ActivityType.imagenFrase => Icons.text_snippet_rounded,
      ActivityType.sonidos => Icons.volume_up_rounded,
      ActivityType.letraObjetivo => Icons.spellcheck_rounded,
      ActivityType.cambioExacto => Icons.shopping_bag_rounded,
      ActivityType.ruletaLetras => Icons.rotate_right_rounded,
      ActivityType.discriminacion => Icons.visibility_rounded,
      ActivityType.discriminacionInversa => Icons.find_replace_rounded,
      ActivityType.eligePalabra => Icons.touch_app_rounded,
      ActivityType.verdaderoFalso => Icons.rule_rounded,
      ActivityType.palabraIncompleta => Icons.edit_note_rounded,
      ActivityType.letraInicial => Icons.vertical_align_top_rounded,
      ActivityType.letraFinal => Icons.vertical_align_bottom_rounded,
      ActivityType.cuentaSilabas => Icons.format_list_numbered_rounded,
      ActivityType.primeraSilaba => Icons.skip_previous_rounded,
      ActivityType.ultimaSilaba => Icons.skip_next_rounded,
      ActivityType.ordenaLetras => Icons.sort_by_alpha_rounded,
      ActivityType.ordenaFrase => Icons.reorder_rounded,
    };
  }

  Color _displayGameColor(ActivityType type) {
    return switch (type) {
      ActivityType.cambioExacto => const Color(0xFFC64890),
      ActivityType.sonidos => const Color(0xFF0F9C78),
      ActivityType.ruletaLetras => const Color(0xFF7A5CD6),
      ActivityType.discriminacion => const Color(0xFF2C86EA),
      ActivityType.discriminacionInversa => const Color(0xFFB86115),
      ActivityType.eligePalabra => const Color(0xFFEF7D32),
      ActivityType.verdaderoFalso => const Color(0xFF0F9DAA),
      ActivityType.palabraIncompleta => const Color(0xFFB66A17),
      ActivityType.letraInicial => const Color(0xFF2C86EA),
      ActivityType.letraFinal => const Color(0xFF7A5CD6),
      ActivityType.cuentaSilabas => const Color(0xFF1BA76A),
      ActivityType.primeraSilaba => const Color(0xFF3A9CE6),
      ActivityType.ultimaSilaba => const Color(0xFFC64890),
      ActivityType.ordenaLetras => const Color(0xFF6658D3),
      ActivityType.ordenaFrase => const Color(0xFFD9645D),
      _ => const Color(0xFF2C86EA),
    };
  }

  Color _levelAccentColor(int level) {
    return switch (level) {
      1 => const Color(0xFF2C86EA),
      2 => const Color(0xFF24C45F),
      3 => const Color(0xFFEF5B10),
      _ => const Color(0xFF7A5CD6),
    };
  }

  Color _vowelModeAccentColor(String mode) {
    return switch (mode) {
      'A' => const Color(0xFFEF5B10),
      'E' => const Color(0xFF2C86EA),
      'I' => const Color(0xFF7A5CD6),
      'O' => const Color(0xFF24C45F),
      'U' => const Color(0xFFC64890),
      'RANDOM' => const Color(0xFF0F9DAA),
      _ => _accent,
    };
  }

  List<int> _levelsForGame(ActivityType activityType) {
    return switch (activityType) {
      ActivityType.letraObjetivo => [1, 2, 3],
      ActivityType.cambioExacto => [1, 2, 3],
      ActivityType.sonidos => [1, 2, 3],
      ActivityType.ruletaLetras => [1],
      ActivityType.discriminacion => [1, 2, 3],
      ActivityType.discriminacionInversa => [1, 2, 3],
      ActivityType.eligePalabra => [1, 2, 3],
      ActivityType.verdaderoFalso => [1, 2, 3],
      ActivityType.palabraIncompleta => [1, 2, 3],
      ActivityType.letraInicial => [1, 2, 3],
      ActivityType.letraFinal => [1, 2, 3],
      ActivityType.cuentaSilabas => [1, 2, 3],
      ActivityType.primeraSilaba => [1, 2, 3],
      ActivityType.ultimaSilaba => [1, 2, 3],
      ActivityType.ordenaLetras => [1, 2, 3],
      ActivityType.ordenaFrase => [1, 2, 3],
      _ => [1],
    };
  }

  String _levelDescription(ActivityType activityType, int level) {
    return switch (activityType) {
      ActivityType.letraObjetivo => switch (level) {
        1 => 'VOCALES Y PALABRAS CORTAS',
        2 => 'LETRAS FRECUENTES Y PALABRAS MEDIAS',
        3 => 'LETRAS MIXTAS Y PALABRAS MÁS LARGAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.ruletaLetras => switch (level) {
        1 => 'LA RULETA DEFINE LA LETRA Y EL RETO',
        _ => 'NIVEL BASE',
      },
      ActivityType.sonidos => switch (level) {
        1 => 'ESCUCHA Y ELIGE ENTRE POCAS IMÁGENES MUY DISTINTAS',
        2 => 'MÁS OPCIONES Y REPETICIÓN DE SONIDOS DE APOYO',
        3 => 'MÁS RONDAS Y MAYOR DISCRIMINACIÓN AUDITIVA',
        _ => 'NIVEL BASE',
      },
      ActivityType.cambioExacto => switch (level) {
        1 => 'PRECIOS SIMPLES Y MONEDAS BÁSICAS',
        2 => 'MÁS MONEDAS Y PRECIOS INTERMEDIOS',
        3 => 'MAYOR RETO CON COMBINACIONES COMPLEJAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.discriminacion => switch (level) {
        1 => 'POCAS OPCIONES Y APOYO VISUAL',
        2 => 'MÁS OPCIONES Y MENOS PISTAS',
        3 => 'MÁXIMA DIFICULTAD Y MÁS RONDAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.discriminacionInversa => switch (level) {
        1 => 'ENCUENTRA LA INTRUSA ENTRE POCAS OPCIONES',
        2 => 'MÁS OPCIONES Y MÁS ATENCIÓN',
        3 => 'INTRUSA CON DISTRACCIONES ALTAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.eligePalabra => switch (level) {
        1 => 'POCAS OPCIONES Y PALABRAS MUY CLARAS',
        2 => 'MÁS OPCIONES Y DISTRACCIÓN MEDIA',
        3 => 'MÁS RONDAS Y VOCABULARIO MÁS AMPLIO',
        _ => 'NIVEL BASE',
      },
      ActivityType.verdaderoFalso => switch (level) {
        1 => 'PALABRAS MUY DISTINTAS Y DECISIÓN SIMPLE',
        2 => 'MÁS RONDAS Y PARECIDOS MAYORES',
        3 => 'COMPARACIONES MÁS FINAS Y RITMO MAYOR',
        _ => 'NIVEL BASE',
      },
      ActivityType.palabraIncompleta => switch (level) {
        1 => 'PALABRAS CORTAS Y LETRAS MUY FRECUENTES',
        2 => 'LETRAS INTERIORES Y MÁS OPCIONES',
        3 => 'PALABRAS MÁS LARGAS Y MAYOR RETO',
        _ => 'NIVEL BASE',
      },
      ActivityType.letraInicial => switch (level) {
        1 => 'INICIOS MUY CLAROS Y POCAS OPCIONES',
        2 => 'MÁS LETRAS Y PALABRAS MEDIAS',
        3 => 'DISTINCIÓN ENTRE LETRAS PARECIDAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.letraFinal => switch (level) {
        1 => 'FINALES CLAROS Y POCAS OPCIONES',
        2 => 'MÁS PALABRAS Y MÁS LETRAS FINALES',
        3 => 'MAYOR ATENCIÓN A TERMINACIONES',
        _ => 'NIVEL BASE',
      },
      ActivityType.cuentaSilabas => switch (level) {
        1 => 'PALABRAS DE HASTA 3 SÍLABAS',
        2 => 'PALABRAS DE HASTA 4 SÍLABAS',
        3 => 'PALABRAS LARGAS Y MÁS RONDAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.primeraSilaba => switch (level) {
        1 => 'PALABRAS DE 2 O 3 SÍLABAS',
        2 => 'SÍLABAS MÁS VARIADAS',
        3 => 'PALABRAS MÁS LARGAS Y MÁS OPCIONES',
        _ => 'NIVEL BASE',
      },
      ActivityType.ultimaSilaba => switch (level) {
        1 => 'TERMINACIONES MUY CLARAS',
        2 => 'MÁS OPCIONES Y SÍLABAS MEDIAS',
        3 => 'TERMINACIONES MÁS COMPLEJAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.ordenaLetras => switch (level) {
        1 => 'PALABRAS CORTAS PARA ORDENAR',
        2 => 'PALABRAS MEDIAS CON MÁS LETRAS',
        3 => 'PALABRAS LARGAS Y MAYOR RETO',
        _ => 'NIVEL BASE',
      },
      ActivityType.ordenaFrase => switch (level) {
        1 => 'FRASES CORTAS DE 2 A 4 PALABRAS',
        2 => 'FRASES MEDIAS DE HASTA 8 PALABRAS',
        3 => 'FRASES LARGAS DE COMPRENSIÓN',
        _ => 'NIVEL BASE',
      },
      _ => 'ESTE JUEGO TIENE UN NIVEL ACTIVO POR AHORA',
    };
  }

  void _openActivity(
    BuildContext context,
    ActivityType activity,
    int gameLevel,
  ) {
    switch (activity) {
      case ActivityType.imagenPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchImageWordScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.escribirPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WriteWordScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.palabraPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchWordWordScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.imagenFrase:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchImagePhraseScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.sonidos:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SoundMatchScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
      case ActivityType.letraObjetivo:
        final letter = _selectedVowelMode == 'RANDOM'
            ? _vowels[_random.nextInt(_vowels.length)]
            : _selectedVowelMode;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LetterTargetScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
              targetLetter: letter,
              matchMode: LetterMatchMode.contiene,
              customTitle: 'LETRAS Y VOCALES',
            ),
          ),
        );
        return;
      case ActivityType.ruletaLetras:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RouletteLettersScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.cambioExacto:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExactChangeStoreScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
      case ActivityType.discriminacion:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DiscriminationScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
      case ActivityType.discriminacionInversa:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InverseDiscriminationScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
      case ActivityType.eligePalabra:
      case ActivityType.verdaderoFalso:
      case ActivityType.palabraIncompleta:
      case ActivityType.letraInicial:
      case ActivityType.letraFinal:
      case ActivityType.cuentaSilabas:
      case ActivityType.primeraSilaba:
      case ActivityType.ultimaSilaba:
      case ActivityType.ordenaLetras:
      case ActivityType.ordenaFrase:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LiteracyChallengeScreen(
              activityType: activity,
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
    }
  }
}

class _LevelGridCard extends StatelessWidget {
  const _LevelGridCard({
    required this.indexLabel,
    required this.title,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    required this.onPlay,
  });

  final String indexLabel;
  final String title;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? accentColor : const Color(0xFFCDD7E6);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: selected ? 3 : 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected ? accentColor : const Color(0xFFEEF2F8),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: UpperText(
                      indexLabel,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF62728F),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? accentColor : const Color(0xFFC0CCDD),
                    size: 30,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              UpperText(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF101A39),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? FilledButton.icon(
                          key: const ValueKey('selected-play'),
                          onPressed: onPlay,
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const UpperText(
                            'JUGAR',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(112, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('empty-play'),
                          height: 36,
                          width: 112,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
