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
import '../../widgets/game_style.dart';
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
  static const _catalogPool = [
    _StoreProduct(emoji: '🐻', name: 'OSITOS DE GOMA', price: 1.20),
    _StoreProduct(emoji: '☁️', name: 'NUBES DULCES', price: 0.80),
    _StoreProduct(emoji: '🍭', name: 'PIRULETAS', price: 0.50),
    _StoreProduct(emoji: '🍫', name: 'REGALIZ NEGRO', price: 1.00),
    _StoreProduct(emoji: '🧃', name: 'ZUMO DE FRUTA', price: 0.15),
    _StoreProduct(emoji: '🥚', name: 'HUEVOS FRITOS', price: 0.75),
    _StoreProduct(emoji: '🍬', name: 'CARAMELOS MIX', price: 0.40),
    _StoreProduct(emoji: '🍪', name: 'MINI GALLETAS', price: 0.60),
    _StoreProduct(emoji: '🍓', name: 'FRESA ÁCIDA', price: 0.35),
    _StoreProduct(emoji: '🍌', name: 'PLÁTANO SNACK', price: 0.90),
  ];

  int _round = 1;
  int _rounds = 4;
  int _requiredUnits = 2;
  bool _isSelectingItems = true;
  double _targetPrice = 0.0;
  final List<_StoreProduct> _catalog = [];
  final Map<int, int> _basketByIndex = {};
  final List<double> _wallet = [];
  final List<double> _droppedCoins = [];
  bool _checking = false;
  String _feedback = 'SELECCIONA VARIAS CHUCHES PARA TU BANDEJA';

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
    _feedback = 'SELECCIONA VARIAS CHUCHES PARA TU BANDEJA';
    _prepareRound();
  }

  void _prepareRound() {
    final shuffledCatalog = [..._catalogPool]..shuffle(_random);
    final required = switch (widget.level) {
      AppLevel.uno => 2,
      AppLevel.dos => widget.difficulty == Difficulty.primaria ? 2 : 3,
      _ => widget.difficulty == Difficulty.primaria ? 3 : 4,
    };

    setState(() {
      _requiredUnits = required;
      _isSelectingItems = true;
      _targetPrice = 0.0;
      _catalog
        ..clear()
        ..addAll(shuffledCatalog.take(6));
      _basketByIndex.clear();
      _wallet.clear();
      _droppedCoins.clear();
      _checking = false;
      _feedback = 'SELECCIONA AL MENOS $_requiredUnits CHUCHES';
    });
  }

  List<double> _buildWalletCoins({required double targetPrice}) {
    final wallet = <double>[];
    final exactCombo = <double>[];
    var remaining = targetPrice;
    final ordered = [..._coinValues];
    for (final coin in ordered) {
      while (remaining + 1e-6 >= coin) {
        exactCombo.add(coin);
        remaining = double.parse((remaining - coin).toStringAsFixed(2));
      }
    }
    wallet.addAll(exactCombo);

    final walletSlots = max(_walletSize, exactCombo.length + 2);
    while (wallet.length < walletSlots) {
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

  int get _basketUnits =>
      _basketByIndex.values.fold<int>(0, (acc, qty) => acc + qty);

  double get _basketTotal => double.parse(
    _basketByIndex.entries
        .fold<double>(
          0,
          (acc, entry) => acc + (_catalog[entry.key].price * entry.value),
        )
        .toStringAsFixed(2),
  );

  List<({int index, int qty})> get _basketEntries => _basketByIndex.entries
      .where((entry) => entry.value > 0)
      .map((entry) => (index: entry.key, qty: entry.value))
      .toList();

  String get _progressItemId =>
      'CAMBIO-L${widget.level.value}-${_targetPrice.toStringAsFixed(2)}';

  void _addProductToBasket(int index) {
    if (_checking) {
      return;
    }
    setState(() {
      _basketByIndex[index] = (_basketByIndex[index] ?? 0) + 1;
      _feedback = _basketUnits >= _requiredUnits
          ? 'PEDIDO LISTO. PULSA IR A PAGAR'
          : 'AÑADE ${_requiredUnits - _basketUnits} MÁS';
    });
  }

  void _removeProductFromBasket(int index) {
    final current = _basketByIndex[index] ?? 0;
    if (current <= 0) {
      return;
    }
    setState(() {
      if (current == 1) {
        _basketByIndex.remove(index);
      } else {
        _basketByIndex[index] = current - 1;
      }
      _feedback = _basketUnits >= _requiredUnits
          ? 'PEDIDO LISTO. PULSA IR A PAGAR'
          : 'AÑADE ${_requiredUnits - _basketUnits} MÁS';
    });
  }

  void _clearBasket() {
    setState(() {
      _basketByIndex.clear();
      _feedback = 'SELECCIONA AL MENOS $_requiredUnits CHUCHES';
    });
  }

  void _startPaymentPhase() {
    if (_basketUnits < _requiredUnits) {
      setState(() {
        _feedback = 'TE FALTAN ${_requiredUnits - _basketUnits} ARTÍCULOS';
      });
      return;
    }
    final total = _basketTotal;
    final wallet = _buildWalletCoins(targetPrice: total);
    setState(() {
      _isSelectingItems = false;
      _targetPrice = total;
      _wallet
        ..clear()
        ..addAll(wallet);
      _droppedCoins.clear();
      _checking = false;
      _feedback = 'AHORA PAGA EXACTAMENTE ${_formatEuro(total)}';
    });
  }

  void _backToSelectionPhase() {
    if (_checking) {
      return;
    }
    setState(() {
      _isSelectingItems = true;
      _droppedCoins.clear();
      _checking = false;
      _feedback = _basketUnits >= _requiredUnits
          ? 'EDITA TU PEDIDO Y VUELVE A PAGAR'
          : 'SELECCIONA AL MENOS $_requiredUnits CHUCHES';
    });
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

  Future<void> _handleCoinDropped(double coin) async {
    if (_checking) {
      return;
    }
    setState(() {
      _droppedCoins.add(coin);
    });
    await _checkAnswer(fromAutoDrop: true);
  }

  Future<void> _checkAnswer({bool fromAutoDrop = false}) async {
    if (_checking || _droppedCoins.isEmpty) {
      return;
    }
    final total = _currentTotal;
    if (fromAutoDrop && total + 0.001 < _targetPrice) {
      setState(() {
        _feedback = 'TE FALTAN ${_formatEuro(_targetPrice - total)}';
      });
      return;
    }

    setState(() {
      _checking = true;
    });

    try {
      final diff = (total - _targetPrice).abs();
      final ok = diff <= 0.001;

      await ref
          .read(progressViewModelProvider.notifier)
          .registerAttempt(
            itemId: _progressItemId,
            correct: ok,
            activityType: ActivityType.cambioExacto,
          );

      if (!mounted) {
        return;
      }

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
          if (fromAutoDrop) {
            _droppedCoins.clear();
          }
          _checking = false;
        });
        return;
      }

      if (_round >= _rounds) {
        await _finish();
        return;
      }

      setState(() {
        _round++;
        _checking = false;
      });
      _prepareRound();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
        _feedback = 'NO SE PUDO COMPROBAR. INTÉNTALO OTRA VEZ';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('ERROR AL COMPROBAR. REVISA E INTENTA DE NUEVO'),
        ),
      );
    }
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
    final height = media.size.height;
    final isTabletLandscapePrimary = isPrimaryTabletLandscape(context);
    final isTablet = width >= 720;
    final isLandscape = media.orientation == Orientation.landscape;
    final isShortDisplay = height < 860;
    final useCompactMetrics = !isLandscape || isShortDisplay;

    return GameScaffold(
      title: 'LA TIENDA DE CHUCHES',
      instructionText: _isSelectingItems
          ? 'SELECCIONA VARIAS CHUCHES Y LUEGO PAGA EL TOTAL'
          : 'ARRASTRA MONEDAS A LA BANDEJA. SE COMPRUEBA AUTOMÁTICAMENTE',
      progressCurrent: _round - 1,
      progressTotal: _rounds,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isTablet
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final enableDesktopScroll =
                          !isTabletLandscapePrimary &&
                          constraints.maxHeight < 760;
                      final row = _isSelectingItems
                          ? _buildSelectionBoard(
                              context,
                              compact: useCompactMetrics,
                              forceColumn: false,
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: isLandscape ? 60 : 58,
                                  child: _buildOrderAndDrop(
                                    context,
                                    compact: useCompactMetrics,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: isLandscape ? 40 : 42,
                                  child: _buildWallet(
                                    context,
                                    compact: useCompactMetrics,
                                  ),
                                ),
                              ],
                            );

                      final top = <Widget>[
                        GameProgressHeader(
                          label: 'TU PROGRESO',
                          current: _round - 1,
                          total: _rounds,
                          trailingLabel: '⭐ $_correct',
                        ),
                        const SizedBox(height: 10),
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        GamePanel(child: UpperText(_feedback)),
                        const SizedBox(height: 12),
                      ];

                      if (!enableDesktopScroll) {
                        return Column(
                          children: [
                            ...top,
                            Expanded(child: row),
                          ],
                        );
                      }

                      final rowHeight = isLandscape ? 620.0 : 700.0;
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            ...top,
                            SizedBox(height: rowHeight, child: row),
                          ],
                        ),
                      );
                    },
                  )
                : ListView(
                    children: [
                      GameProgressHeader(
                        label: 'TU PROGRESO',
                        current: _round - 1,
                        total: _rounds,
                        trailingLabel: '⭐ $_correct',
                      ),
                      const SizedBox(height: 10),
                      _buildHeader(context),
                      const SizedBox(height: 10),
                      GamePanel(child: UpperText(_feedback)),
                      const SizedBox(height: 12),
                      if (_isSelectingItems)
                        _buildSelectionBoard(
                          context,
                          compact: true,
                          forceColumn: true,
                        )
                      else ...[
                        _buildOrderAndDrop(context, compact: true),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 360,
                          child: _buildWallet(context, compact: true),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final phaseTitle = _isSelectingItems
        ? 'SELECCIONA TUS CHUCHES'
        : 'PAGA EL PEDIDO';
    final phaseHint = _isSelectingItems
        ? 'AÑADE PRODUCTOS A LA BANDEJA ANTES DE PAGAR'
        : 'USA TU MONEDERO PARA DAR EL CAMBIO EXACTO';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD6E9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpperText(
                  phaseTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF263047),
                  ),
                ),
                const SizedBox(height: 2),
                UpperText(
                  phaseHint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF60708C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (_isSelectingItems) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: UpperText(
                'MÍNIMO: $_requiredUnits',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF35598E),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: UpperText(
              'RONDA $_round/$_rounds',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C3D77),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBoard(
    BuildContext context, {
    required bool compact,
    required bool forceColumn,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = !forceColumn && constraints.maxWidth >= 860;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 62,
                child: _buildCatalogPanel(context, compact: compact),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 38,
                child: _buildBasketPanel(context, compact: compact),
              ),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(
              height: forceColumn ? 520 : 360,
              child: _buildCatalogPanel(context, compact: compact),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: forceColumn ? 420 : 320,
              child: _buildBasketPanel(context, compact: compact),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCatalogPanel(BuildContext context, {required bool compact}) {
    final isTabletLandscapePrimary = isPrimaryTabletLandscape(context);
    final crossAxisCount = isTabletLandscapePrimary ? 3 : 2;
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
            'SELECCIONA TUS CHUCHES',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1F2F4E),
            ),
          ),
          const SizedBox(height: 4),
          const UpperText(
            'ARRASTRA O TOCA PARA AÑADIR A LA BANDEJA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF60708C),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: compact ? 148 : 166,
              ),
              itemCount: _catalog.length,
              itemBuilder: (context, index) {
                final item = _catalog[index];
                final qty = _basketByIndex[index] ?? 0;
                return Draggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 170,
                      child: _buildCandyCard(
                        context,
                        item: item,
                        qty: qty,
                        compact: true,
                        interactive: false,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: _buildCandyCard(
                      context,
                      item: item,
                      qty: qty,
                      compact: compact,
                      interactive: false,
                    ),
                  ),
                  child: _buildCandyCard(
                    context,
                    item: item,
                    qty: qty,
                    compact: compact,
                    interactive: true,
                    onTap: () => _addProductToBasket(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandyCard(
    BuildContext context, {
    required _StoreProduct item,
    required int qty,
    required bool compact,
    required bool interactive,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E9F5)),
            ),
            child: Center(
              child: UpperText(
                item.emoji,
                style: TextStyle(fontSize: compact ? 34 : 42),
              ),
            ),
          ),
          const SizedBox(height: 8),
          UpperText(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 16 : 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              UpperText(
                _formatEuro(item.price),
                style: TextStyle(
                  fontSize: compact ? 20 : 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2B80E2),
                ),
              ),
              const Spacer(),
              if (qty > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: UpperText(
                    'X$qty',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2A5B9E),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    if (!interactive) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }

  Widget _buildBasketPanel(BuildContext context, {required bool compact}) {
    final entries = _basketEntries;
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
            'MI BANDEJA',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1F2F4E),
            ),
          ),
          const SizedBox(height: 8),
          DragTarget<int>(
            onAcceptWithDetails: (details) => _addProductToBasket(details.data),
            builder: (context, candidateData, rejected) {
              final hovering = candidateData.isNotEmpty;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hovering
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF5F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hovering
                        ? const Color(0xFF2B8CEE)
                        : const Color(0xFFB9CDEB),
                    width: 2,
                  ),
                ),
                child: entries.isEmpty
                    ? const UpperText(
                        'ARRASTRA AQUÍ TUS CHUCHES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF60708C),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Column(
                        children: entries.map((entry) {
                          final item = _catalog[entry.index];
                          final subtotal = item.price * entry.qty;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: UpperText(
                                    '${item.name} X${entry.qty}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                UpperText(
                                  _formatEuro(subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () =>
                                      _removeProductFromBasket(entry.index),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  tooltip: 'QUITAR UNO',
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2F88E8), Color(0xFF2A67D8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UpperText(
                  'TOTAL EN BANDEJA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                UpperText(
                  _formatEuro(_basketTotal),
                  style: TextStyle(
                    fontSize: compact ? 34 : 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: entries.isEmpty ? null : _clearBasket,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const UpperText('LIMPIAR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: entries.isEmpty ? null : _startPaymentPhase,
                  icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  label: const UpperText('IR A PAGAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderAndDrop(BuildContext context, {required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final isTabletLandscapePrimary = isPrimaryTabletLandscape(context);
        final isShortPanel = hasBoundedHeight && constraints.maxHeight < 560;
        final useCompactMetrics = compact || isShortPanel;
        final entries = _basketEntries;

        final panelContent = Column(
          mainAxisSize: MainAxisSize.min,
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
                    'TU PEDIDO',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (entries.isEmpty)
                    const UpperText('NO HAY ARTÍCULOS')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: entries.map((entry) {
                        final item = _catalog[entry.index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: UpperText(
                            '${item.emoji} ${item.name} X${entry.qty}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF9F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFB8E2CB),
                        width: 2,
                      ),
                    ),
                    child: UpperText(
                      _formatEuro(_targetPrice),
                      style: TextStyle(
                        fontSize: useCompactMetrics ? 30 : 40,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1F8A58),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DragTarget<double>(
              onAcceptWithDetails: (details) async {
                await _handleCoinDropped(details.data);
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
                          fontSize: useCompactMetrics ? 32 : 40,
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
                                  diameter: useCompactMetrics ? 42 : 52,
                                  fontSize: useCompactMetrics ? 19 : 24,
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
                    onPressed: _checking ? null : _backToSelectionPhase,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: UpperText(useCompactMetrics ? 'EDITAR' : 'PEDIDO'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _droppedCoins.isEmpty || _checking
                        ? null
                        : _undoCoin,
                    icon: const Icon(Icons.undo_rounded),
                    label: UpperText(useCompactMetrics ? 'DESH.' : 'DESHACER'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _droppedCoins.isEmpty || _checking
                        ? null
                        : _clearCoins,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const UpperText('LIMPIAR'),
                  ),
                ),
              ],
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFFFFF3FB),
            border: Border.all(color: const Color(0xFFFFD5EC)),
          ),
          child: hasBoundedHeight && !isTabletLandscapePrimary
              ? Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(child: panelContent),
                )
              : panelContent,
        );
      },
    );
  }

  Widget _buildWallet(BuildContext context, {required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        final rows = max(1, (_wallet.length / crossAxisCount).ceil());
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final spacing = compact ? 8.0 : 10.0;
        final headerHeight = compact ? 56.0 : 64.0;
        final availableHeight = hasBoundedHeight
            ? constraints.maxHeight
            : (compact ? 360.0 : 440.0);
        final usableHeight =
            availableHeight - headerHeight - (rows - 1) * spacing;
        final coinDiameter = (usableHeight / rows).clamp(
          54.0,
          compact ? 76.0 : 90.0,
        );
        final fontSize = (coinDiameter * 0.34).clamp(18.0, 32.0);
        final gridHeight = rows * coinDiameter + (rows - 1) * spacing;

        final grid = GridView.builder(
          shrinkWrap: !hasBoundedHeight,
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
        );

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD8E5FF)),
                ),
                child: const UpperText(
                  'SE COMPRUEBA AL SOLTAR LA MONEDA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B5688),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (hasBoundedHeight)
                Expanded(child: grid)
              else
                SizedBox(height: gridHeight, child: grid),
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

class _StoreProduct {
  const _StoreProduct({
    required this.emoji,
    required this.name,
    required this.price,
  });

  final String emoji;
  final String name;
  final double price;
}
