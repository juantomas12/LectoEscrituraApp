import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/category.dart';
import '../../domain/models/item.dart';
import '../widgets/activity_asset_image.dart';
import '../widgets/upper_text.dart';

class ImageManagerScreen extends ConsumerStatefulWidget {
  const ImageManagerScreen({super.key});

  @override
  ConsumerState<ImageManagerScreen> createState() => _ImageManagerScreenState();
}

class _ImageManagerScreenState extends ConsumerState<ImageManagerScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Item> _allItems = [];
  List<String> _allImageAssets = [];
  Map<String, String> _overrides = {};

  AppCategory? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final datasetRepository = ref.read(datasetRepositoryProvider);
    final imageOverrideRepository = ref.read(imageOverrideRepositoryProvider);

    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final assets =
        manifest.keys.where((key) => key.startsWith('assets/images/')).toList()
          ..sort();

    final items = datasetRepository.getAllItems()
      ..sort((a, b) {
        final wordA = a.word ?? (a.words.isNotEmpty ? a.words.first : a.id);
        final wordB = b.word ?? (b.words.isNotEmpty ? b.words.first : b.id);
        return wordA.compareTo(wordB);
      });

    if (!mounted) {
      return;
    }

    setState(() {
      _allImageAssets = assets;
      _allItems = items;
      _overrides = imageOverrideRepository.loadOverrides();
      _isLoading = false;
    });
  }

  String _currentImagePath(Item item) {
    return _overrides[item.id] ?? item.imageAsset;
  }

  List<Item> get _visibleItems {
    final query = _searchController.text.trim().toUpperCase();

    return _allItems.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final word =
          (item.word ?? (item.words.isNotEmpty ? item.words.first : item.id))
              .toUpperCase();

      return item.id.toUpperCase().contains(query) ||
          word.contains(query) ||
          item.category.label.toUpperCase().contains(query);
    }).toList();
  }

  String _folderPrefix(String assetPath) {
    final slash = assetPath.lastIndexOf('/');
    if (slash <= 0) {
      return 'assets/images/';
    }
    return assetPath.substring(0, slash + 1);
  }

  Future<void> _editImage(Item item) async {
    final currentPath = _currentImagePath(item);
    final folderPrefix = _folderPrefix(item.imageAsset);

    final candidates = _allImageAssets
        .where((path) => path.startsWith(folderPrefix))
        .toList();

    if (!candidates.contains(currentPath)) {
      candidates.insert(0, currentPath);
    }

    String selected = candidates.isNotEmpty ? candidates.first : currentPath;
    if (candidates.contains(currentPath)) {
      selected = currentPath;
    }

    final customController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const UpperText('EDITAR IMAGEN DEL ÍTEM'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UpperText('ID: ${item.id}'),
                    const SizedBox(height: 6),
                    UpperText(
                      'PALABRA: ${item.word ?? (item.words.isNotEmpty ? item.words.first : item.id)}',
                    ),
                    const SizedBox(height: 10),
                    UpperText(
                      'IMAGEN ACTUAL',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ActivityAssetImage(assetPath: selected),
                    ),
                    const SizedBox(height: 10),
                    UpperText(
                      'SELECCIONA UNA IMAGEN LOCAL DE ESTA CATEGORÍA',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: candidates.contains(selected)
                          ? selected
                          : candidates.first,
                      items: candidates
                          .map(
                            (path) => DropdownMenuItem(
                              value: path,
                              child: Text(path),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selected = value;
                          customController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    const UpperText('O ESCRIBE UNA RUTA MANUAL'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'ASSETS/IMAGES/.../ARCHIVO.JPG',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const UpperText('CANCELAR'),
                ),
                FilledButton(
                  onPressed: () {
                    final manual = customController.text.trim();
                    Navigator.of(
                      context,
                    ).pop(manual.isNotEmpty ? manual : selected);
                  },
                  child: const UpperText('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );

    customController.dispose();

    if (result == null || result.trim().isEmpty) {
      return;
    }

    final imagePath = result.trim();
    await ref
        .read(imageOverrideRepositoryProvider)
        .setOverride(itemId: item.id, imageAsset: imagePath);

    final updated = Map<String, String>.from(_overrides)..[item.id] = imagePath;
    ref.read(datasetRepositoryProvider).setImageOverrides(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _overrides = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: UpperText('IMAGEN GUARDADA PARA ${item.id}')),
    );
  }

  Future<void> _restoreImage(Item item) async {
    await ref.read(imageOverrideRepositoryProvider).removeOverride(item.id);
    final updated = Map<String, String>.from(_overrides)..remove(item.id);
    ref.read(datasetRepositoryProvider).setImageOverrides(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _overrides = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: UpperText('IMAGEN RESTAURADA PARA ${item.id}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Scaffold(
      appBar: AppBar(title: const UpperText('EDITOR DE IMÁGENES')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: const [
                              Icon(Icons.build_circle_outlined),
                              SizedBox(width: 10),
                              Expanded(
                                child: UpperText(
                                  'AQUÍ PUEDES CAMBIAR CUALQUIER IMAGEN Y GUARDARLA EN LOCAL',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AppCategory?>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'CATEGORÍA',
                              ),
                              items: [
                                const DropdownMenuItem<AppCategory?>(
                                  value: null,
                                  child: UpperText('TODAS'),
                                ),
                                ...AppCategory.values.map(
                                  (category) => DropdownMenuItem<AppCategory?>(
                                    value: category,
                                    child: UpperText(category.label),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'BUSCAR (ID O PALABRA)',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: UpperText(
                          'ÍTEMS MOSTRADOS: ${visibleItems.length}',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      final word =
                          item.word ??
                          (item.words.isNotEmpty ? item.words.first : item.id);
                      final currentImage = _currentImagePath(item);
                      final hasOverride = _overrides.containsKey(item.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 88,
                                height: 88,
                                child: ActivityAssetImage(
                                  assetPath: currentImage,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UpperText(
                                      word,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    UpperText('ID: ${item.id}'),
                                    const SizedBox(height: 2),
                                    UpperText(
                                      'CATEGORÍA: ${item.category.label}',
                                    ),
                                    const SizedBox(height: 2),
                                    UpperText('RUTA: $currentImage'),
                                    if (hasOverride)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: UpperText(
                                          'MODIFICADA MANUALMENTE',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  FilledButton(
                                    onPressed: () => _editImage(item),
                                    child: const UpperText('CAMBIAR'),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: hasOverride
                                        ? () => _restoreImage(item)
                                        : null,
                                    child: const UpperText('RESTAURAR'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
