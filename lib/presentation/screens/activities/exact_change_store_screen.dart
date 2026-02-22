import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pedagogical_feedback.dart';
import '../../../domain/models/activity_result.dart';
import '../../../domain/models/activity_type.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/difficulty.dart';
import '../../../domain/models/level.dart';
import '../../viewmodels/progress_view_model.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

class ExactChangeStoreScreen extends ConsumerStatefulWidget {
  const ExactChangeStoreScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.level,
  });

  final AppCategory category;
  final Difficulty difficulty;
  final AppLevel level;

  @override
  ConsumerState<ExactChangeStoreScreen> createState() =>
      _ExactChangeStoreScreenState();
}

class _ExactChangeStoreScreenState
    extends ConsumerState<ExactChangeStoreScreen> {
  final Random _random = Random();

  static const _coinValues = [2.0, 1.0, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01];
  static const _productPool = [
    ('🧸', 'GOMINOLAS'),
    ('🍭', 'PIRULETA'),
    ('🍪', 'GALLETAS'),
    ('🧃', 'ZUMITO'),
    ('🍫', 'CHOCOLATE'),
    ('🍓', 'FRESA DULCE'),
    ('🍌', 'PLÁTANO SNACK'),
    ('🧁', 'MINI CUPCAKE'),
  ];

  int _round = 1;
  int _rounds = 4;
  double _targetPrice = 0.45;
  String _productEmoji = '🧸';
  String _productName = 'GOMINOLAS';
  final List<double> _wallet = [];
  final List<double> _droppedCoins = [];
  bool _checking = false;
  String _feedback = 'ARRASTRA MONEDAS HASTA LOGRAR EL CAMBIO EXACTO';

  int _correct = 0;
  int _incorrect = 0;
  int _streak = 0;
  int _bestStreak = 0;
  DateTime _startedAt = DateTime.now();

  int get _walletSize => switch (widget.level) {
    AppLevel.uno => widget.difficulty == Difficulty.primaria ? 8 : 9,
    AppLevel.dos => widget.difficulty == Difficulty.primaria ? 9 : 10,
    _ => widget.difficulty == Difficulty.primaria ? 10 : 11,
  };

  @override
  void initState() {
    super.initState();
    _prepareGame();
  }

  void _prepareGame() {
    _rounds = switch (widget.level) {
      AppLevel.uno => 4,
      AppLevel.dos => 5,
      _ => 6,
    };
    _correct = 0;
    _incorrect = 0;
    _streak = 0;
    _bestStreak = 0;
    _round = 1;
    _startedAt = DateTime.now();
    _feedback = 'ARRASTRA MONEDAS HASTA LOGRAR EL CAMBIO EXACTO';
    _prepareRound();
  }

  void _prepareRound() {
    final price = _buildTargetPrice();
    final picked = _productPool[_random.nextInt(_productPool.length)];
    final wallet = _buildWalletCoins(targetPrice: price);

    setState(() {
      _targetPrice = price;
      _productEmoji = picked.$1;
      _productName = picked.$2;
      _wallet
        ..clear()
        ..addAll(wallet);
      _droppedCoins.clear();
      _checking = false;
    });
  }

  double _buildTargetPrice() {
    final candidateSets = switch (widget.level) {
      AppLevel.uno => [
        [0.2, 0.2, 0.05],
        [0.2, 0.1, 0.1],
        [0.5, 0.2],
        [0.1, 0.1, 0.1],
        [0.5, 0.1, 0.05],
      ],
      AppLevel.dos => [
        [1.0, 0.2, 0.1],
        [0.5, 0.5, 0.2],
        [1.0, 0.5, 0.2, 0.05],
        [0.2, 0.2, 0.2, 0.1, 0.05],
        [1.0, 0.2, 0.2, 0.1],
      ],
      _ => [
        [2.0, 0.5, 0.2, 0.1],
        [1.0, 1.0, 0.2, 0.05],
        [2.0, 0.2, 0.2, 0.05, 0.02],
        [1.0, 0.5, 0.2, 0.2, 0.1],
        [2.0, 0.5, 0.1, 0.05],
      ],
    };

    final chosen = candidateSets[_random.nextInt(candidateSets.length)];
    final sum = chosen.fold<double>(0, (acc, coin) => acc + coin);
    return double.parse(sum.toStringAsFixed(2));
  }

  List<double> _buildWalletCoins({required double targetPrice}) {
    final wallet = <double>[];
    final exactCombo = <double>[];
    var remaining = targetPrice;
    final ordered = [..._coinValues];
    for (final coin in ordered) {
      while (remaining + 1e-6 >= coin && exactCombo.length < 6) {
        exactCombo.add(coin);
        remaining = double.parse((remaining - coin).toStringAsFixed(2));
      }
    }
    wallet.addAll(exactCombo);

    while (wallet.length < _walletSize) {
      wallet.add(_coinValues[_random.nextInt(_coinValues.length)]);
    }
    wallet.shuffle(_random);
    return wallet;
  }

  double get _currentTotal => double.parse(
    _droppedCoins.fold<double>(0, (acc, coin) => acc + coin).toStringAsFixed(2),
  );

  String _formatEuro(double value) {
    return '${value.toStringAsFixed(2)}€';
  }

  void _undoCoin() {
    if (_droppedCoins.isEmpty) {
      return;
    }
    setState(() {
      _droppedCoins.removeLast();
    });
  }

  void _clearCoins() {
    setState(() {
      _droppedCoins.clear();
    });
  }

  Future<void> _checkAnswer() async {
    if (_checking || _droppedCoins.isEmpty) {
      return;
    }
    _checking = true;
    final total = _currentTotal;
    final diff = (total - _targetPrice).abs();
    final ok = diff <= 0.001;

    if (ok) {
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
      _feedback = total < _targetPrice
          ? 'TE FALTAN ${_formatEuro(_targetPrice - total)}'
          : 'TE PASASTE ${_formatEuro(total - _targetPrice)}';
    }

    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) {
      return;
    }

    if (!ok) {
      setState(() {
        _checking = false;
      });
      return;
    }

    await ref
        .read(progressViewModelProvider.notifier)
        .registerAttempt(
          itemId: 'CAMBIO-$_round-${DateTime.now().millisecondsSinceEpoch}',
          correct: true,
          activityType: ActivityType.cambioExacto,
        );

    if (_round >= _rounds) {
      await _finish();
      return;
    }

    setState(() {
      _round++;
      _checking = false;
    });
    _prepareRound();
  }

  Future<void> _finish() async {
    final result = ActivityResult(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      category: widget.category,
      level: widget.level,
      activityType: ActivityType.cambioExacto,
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
      MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
    );
    if (!mounted) {
      return;
    }
    if (action == ResultAction.repetir) {
      _prepareGame();
      return;
    }
    Navigator.of(context).pop();
  }

  Color _coinColor(double value) {
    if (value >= 2.0) return const Color(0xFFBCA440);
    if (value >= 1.0) return const Color(0xFFB8BCC7);
    if (value >= 0.1) return const Color(0xFFD4A317);
    return const Color(0xFFCC6E2D);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isTablet = width >= 720;
    final isLandscape = media.orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: const UpperText('LA TIENDA DE CHUCHES')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1260),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isTablet
                  ? Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: UpperText(_feedback),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: isLandscape ? 60 : 58,
                                child: _buildProductAndDrop(
                                  context,
                                  compact: !isLandscape,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: isLandscape ? 40 : 42,
                                child: _buildWallet(
                                  context,
                                  compact: !isLandscape,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: UpperText(_feedback),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProductAndDrop(context, compact: true),
                        const SizedBox(height: 12),
                        _buildWallet(context, compact: true),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4FB), Color(0xFFE8F4FF)],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: UpperText(
              'CAMBIO EXACTO',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF263047),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E8FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: UpperText(
              'RONDA $_round/$_rounds',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAndDrop(BuildContext context, {required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFFFF3FB),
        border: Border.all(color: const Color(0xFFFFD5EC)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                UpperText(
                  _productEmoji,
                  style: TextStyle(fontSize: compact ? 56 : 68),
                ),
                const SizedBox(height: 6),
                UpperText(
                  _productName,
                  style: TextStyle(
                    fontSize: compact ? 34 : 42,
                    color: const Color(0xFFE03595),
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0AE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEDD070),
                      width: 2,
                    ),
                  ),
                  child: UpperText(
                    _formatEuro(_targetPrice),
                    style: TextStyle(
                      fontSize: compact ? 38 : 50,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF985E00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DragTarget<double>(
            onAcceptWithDetails: (details) {
              setState(() {
                _droppedCoins.add(details.data);
              });
            },
            builder: (context, candidateData, rejected) {
              final hovering = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: hovering
                      ? Colors.green.shade50
                      : const Color(0xFFFFF8D8),
                  border: Border.all(
                    color: hovering
                        ? Colors.green.shade700
                        : const Color(0xFFE8DFA9),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    UpperText(
                      'BANDEJA DE PAGO',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    UpperText(
                      _formatEuro(_currentTotal),
                      style: TextStyle(
                        fontSize: compact ? 34 : 42,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1D6E37),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_droppedCoins.isEmpty)
                      const UpperText('ARRASTRA MONEDAS AQUÍ')
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: _droppedCoins
                            .map(
                              (coin) => _coinBubble(
                                context,
                                coin,
                                diameter: compact ? 44 : 52,
                                fontSize: compact ? 20 : 24,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _droppedCoins.isEmpty ? null : _undoCoin,
                  icon: const Icon(Icons.undo_rounded),
                  label: UpperText(compact ? 'DESH.' : 'DESHACER'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _droppedCoins.isEmpty ? null : _clearCoins,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const UpperText('LIMPIAR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _droppedCoins.isEmpty || _checking
                      ? null
                      : _checkAnswer,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const UpperText('COMPROBAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWallet(BuildContext context, {required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        final rows = (_wallet.length / crossAxisCount).ceil();
        final spacing = compact ? 8.0 : 10.0;
        final headerHeight = compact ? 56.0 : 64.0;
        final usableHeight =
            constraints.maxHeight - headerHeight - (rows - 1) * spacing;
        final coinDiameter = (usableHeight / rows).clamp(
          54.0,
          compact ? 76.0 : 90.0,
        );
        final fontSize = (coinDiameter * 0.34).clamp(18.0, 32.0);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCBD6E9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpperText(
                'TU MONEDERO',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2C3A55),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    mainAxisExtent: coinDiameter,
                  ),
                  itemCount: _wallet.length,
                  itemBuilder: (context, index) {
                    final coin = _wallet[index];
                    return Draggable<double>(
                      data: coin,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _coinBubble(
                          context,
                          coin,
                          diameter: coinDiameter + 16,
                          fontSize: fontSize + 3,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.25,
                        child: _coinBubble(
                          context,
                          coin,
                          diameter: coinDiameter,
                          fontSize: fontSize,
                        ),
                      ),
                      child: _coinBubble(
                        context,
                        coin,
                        diameter: coinDiameter,
                        fontSize: fontSize,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coinBubble(
    BuildContext context,
    double value, {
    required double diameter,
    required double fontSize,
  }) {
    final color = _coinColor(value);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white, color.withValues(alpha: 0.95)],
            center: const Alignment(-0.3, -0.3),
            radius: 1.0,
          ),
          border: Border.all(color: color, width: 2.4),
        ),
        child: UpperText(
          value >= 1 ? '${value.toInt()}€' : '${(value * 100).toInt()}c',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2C2C2C),
          ),
        ),
      ),
    );
  }
}
