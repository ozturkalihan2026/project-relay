import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/navigation_actions.dart';
import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/module_visuals.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/circuit_credit_icon.dart';
import '../widgets/relay_notice.dart';

enum CollectionScreenMode { collection, store }

enum _CollectionSection { kit, cosmetics }

enum _StoreSection { all, module, board, profile }

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({
    this.mode = CollectionScreenMode.collection,
    this.kitOnly = false,
    this.kitMode = KitMode.online,
    super.key,
  });

  final CollectionScreenMode mode;
  final bool kitOnly;
  final KitMode kitMode;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController _kitNameController = TextEditingController();
  CollectionSnapshot? _snapshot;
  List<ModuleKind>? _kitSlots;
  _CollectionSection _section = _CollectionSection.kit;
  _StoreSection _storeSection = _StoreSection.all;
  bool _busy = false;

  @override
  void dispose() {
    _kitNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(collectionProvider);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        centerTitle: true,
        title: AppHeaderTitle(
          pageTitle: widget.mode == CollectionScreenMode.store
              ? 'MAĞAZA'
              : widget.kitOnly
              ? '${widget.kitMode.displayName.toUpperCase()} SEKİZLİSİ'
              : 'KOLEKSİYON',
        ),
        actions: const [AppHeaderActions(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: remote.when(
          data: (value) {
            _adoptSnapshot(value);
            return _buildContent(_snapshot ?? value);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorPanel(
            message: error.toString(),
            onRetry: () => ref.invalidate(collectionProvider),
          ),
        ),
      ),
    );
  }

  void _adoptSnapshot(CollectionSnapshot value) {
    if (_snapshot != null) return;
    _snapshot = value;
    final selectedKit = value.kitFor(widget.kitMode);
    _kitSlots = List<ModuleKind>.from(selectedKit.moduleKinds);
    _kitNameController.text = selectedKit.name;
  }

  Widget _buildContent(CollectionSnapshot snapshot) {
    final kitSlots = _kitSlots ?? snapshot.kitFor(widget.kitMode).moduleKinds;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(collectionProvider);
        final refreshed = await ref.read(collectionProvider.future);
        if (!mounted) return;
        setState(() {
          _snapshot = refreshed;
          final selectedKit = refreshed.kitFor(widget.kitMode);
          _kitSlots = List<ModuleKind>.from(selectedKit.moduleKinds);
          _kitNameController.text = selectedKit.name;
        });
      },
      child: ListView(
        key: ValueKey(
          widget.mode == CollectionScreenMode.store
              ? 'store-scroll-view'
              : 'collection-scroll-view',
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          if (widget.mode != CollectionScreenMode.store) ...[
            _CollectionHeader(credits: snapshot.credits),
            const SizedBox(height: 14),
          ],
          if (widget.kitOnly) ...[
            _KitEditor(
              nameController: _kitNameController,
              slots: kitSlots,
              busy: _busy,
              onChanged: (index, kind) {
                setState(() {
                  final slots = List<ModuleKind>.from(kitSlots);
                  slots[index] = kind;
                  _kitSlots = slots;
                });
              },
              onSave: () {
                _saveKit();
              },
              showSaveButton: false,
            ),
          ] else if (widget.mode == CollectionScreenMode.store) ...[
            _storeSectionSelector(),
            const SizedBox(height: 14),
            _cosmeticCatalog(
              snapshot,
              owned: false,
              emptyMessage:
                  'Bu mağaza sekmesinde satın alınmamış içerik kalmadı. Yeni içerikler '
                  'tek sayfalı bu düzen içinde aynı sekme yapısına eklenebilir.',
            ),
          ] else ...[
            _collectionSectionSelector(),
            const SizedBox(height: 14),
            if (_section == _CollectionSection.kit)
              _KitEditor(
                nameController: _kitNameController,
                slots: kitSlots,
                busy: _busy,
                onChanged: (index, kind) {
                  setState(() {
                    final slots = List<ModuleKind>.from(kitSlots);
                    slots[index] = kind;
                    _kitSlots = slots;
                  });
                },
                onSave: () {
                  _saveKit();
                },
              )
            else
              _cosmeticCatalog(
                snapshot,
                owned: true,
                emptyMessage:
                    'Henüz sahip olduğun kozmetik yok. Mağazadan Devre Kredisi '
                    'ile görsel içerik alabilirsin.',
              ),
          ],
          const SizedBox(height: 18),
          if (widget.kitOnly)
            FilledButton.icon(
              key: const ValueKey('kit-save-and-return'),
              onPressed: _busy ? null : _saveKitAndReturn,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_busy ? 'KAYDEDİLİYOR' : 'KAYDET'),
            )
          else
            OutlinedButton.icon(
              key: ValueKey(
                widget.mode == CollectionScreenMode.store
                    ? 'store-menu-back'
                    : 'collection-menu-back',
              ),
              onPressed: _busy ? null : () => returnToMainMenu(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('ANA MENÜYE DÖN'),
            ),
        ],
      ),
    );
  }

  Widget _storeSectionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_StoreSection>(
        key: const ValueKey('store-section-selector'),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _StoreSection.all,
            icon: Icon(Icons.grid_view_rounded),
            label: Text('TÜMÜ', key: ValueKey('store-section-all')),
          ),
          ButtonSegment(
            value: _StoreSection.module,
            icon: Icon(Icons.memory_outlined),
            label: Text('MODÜL', key: ValueKey('store-section-module')),
          ),
          ButtonSegment(
            value: _StoreSection.board,
            icon: Icon(Icons.dashboard_outlined),
            label: Text('DEVRE KARTI', key: ValueKey('store-section-board')),
          ),
          ButtonSegment(
            value: _StoreSection.profile,
            icon: Icon(Icons.badge_outlined),
            label: Text('PROFİL', key: ValueKey('store-section-profile')),
          ),
        ],
        selected: {_storeSection},
        onSelectionChanged: _busy
            ? null
            : (selection) {
                setState(() => _storeSection = selection.first);
              },
      ),
    );
  }

  Widget _collectionSectionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_CollectionSection>(
        key: const ValueKey('collection-section-selector'),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _CollectionSection.kit,
            icon: Icon(Icons.dashboard_customize_outlined),
            label: Text(
              'BAŞLANGIÇ 8LİSİ',
              key: ValueKey('collection-section-kit'),
            ),
          ),
          ButtonSegment(
            value: _CollectionSection.cosmetics,
            icon: Icon(Icons.palette_outlined),
            label: Text(
              'KOZMETİK',
              key: ValueKey('collection-section-cosmetics'),
            ),
          ),
        ],
        selected: {_section},
        onSelectionChanged: _busy
            ? null
            : (selection) {
                setState(() => _section = selection.first);
              },
      ),
    );
  }

  Widget _cosmeticCatalog(
    CollectionSnapshot snapshot, {
    required bool owned,
    required String emptyMessage,
  }) {
    final visibleItems = snapshot.cosmetics
        .where((item) => item.owned == owned)
        .where((item) {
          if (widget.mode != CollectionScreenMode.store) {
            return true;
          }
          return switch (_storeSection) {
            _StoreSection.all => true,
            _StoreSection.module => item.category == 'module_skin',
            _StoreSection.board => item.category == 'board_theme',
            _StoreSection.profile => item.category == 'profile_frame',
          };
        })
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return _CollectionEmptyState(
        icon: owned ? Icons.inventory_2_outlined : Icons.storefront_outlined,
        message: emptyMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in const [
          'module_skin',
          'board_theme',
          'profile_frame',
        ])
          if (visibleItems.any((item) => item.category == category)) ...[
            _CategoryTitle(category: category),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = widget.mode == CollectionScreenMode.store
                    ? constraints.maxWidth >= 1320
                          ? 6
                          : constraints.maxWidth >= 1040
                          ? 5
                          : constraints.maxWidth >= 780
                          ? 4
                          : constraints.maxWidth >= 540
                          ? 3
                          : 2
                    : constraints.maxWidth >= 960
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                const spacing = 10.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final items = visibleItems
                    .where((item) => item.category == category)
                    .toList(growable: false);
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: width,
                        child: _CosmeticCard(
                          item: item,
                          busy: _busy,
                          compact: widget.mode == CollectionScreenMode.store,
                          onAction: () => _cosmeticAction(item),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }

  Future<ControlledKit?> _saveKit() async {
    if (_busy) return null;
    final slots = _kitSlots;
    if (slots == null || slots.length != 8) {
      _notice('Kit tam olarak sekiz yuva içermelidir.', RelayNoticeTone.error);
      return null;
    }
    final counts = <ModuleKind, int>{};
    for (final kind in slots) {
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    if (counts[ModuleKind.generator] != 1) {
      _notice(
        'Sekizli kit tam olarak bir Jeneratör içermelidir.',
        RelayNoticeTone.warning,
      );
      return null;
    }
    final excessive = counts.entries
        .where((entry) => entry.key != ModuleKind.generator && entry.value > 3)
        .map((entry) => entry.key.displayName)
        .toList(growable: false);
    if (excessive.isNotEmpty) {
      _notice(
        'Bir modül türü en fazla üç yuvada bulunabilir: '
        '${excessive.join(', ')}',
        RelayNoticeTone.warning,
      );
      return null;
    }

    setState(() => _busy = true);
    try {
      final value = await ref
          .read(relayApiProvider)
          .saveControlledKit(
            mode: widget.kitMode,
            name: _kitNameController.text,
            moduleKinds: slots,
          );
      if (!mounted) return null;
      setState(() {
        _snapshot = value;
        _kitSlots = List<ModuleKind>.from(
          value.kitFor(widget.kitMode).moduleKinds,
        );
      });
      ref.invalidate(collectionProvider);
      _notice(
        'Sekizli kit kaydedildi. Editör paletleri artık bu sınırlara bağlı.',
        RelayNoticeTone.success,
      );
      return value.kitFor(widget.kitMode);
    } on RelayApiException catch (error) {
      _notice(error.message, RelayNoticeTone.error);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveKitAndReturn() async {
    final savedKit = await _saveKit();
    if (savedKit == null || !mounted) return;
    Navigator.of(context).pop(savedKit);
  }

  Future<void> _cosmeticAction(CosmeticItem item) async {
    if (_busy || item.equipped) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(relayApiProvider);
      final value = item.owned
          ? await api.equipCosmetic(item.id)
          : await api.purchaseCosmetic(item.id);
      if (!mounted) return;
      setState(() => _snapshot = value);
      ref.invalidate(collectionProvider);
      ref.invalidate(progressionProvider);
      _notice(
        item.owned
            ? '${item.displayName} kuşanıldı.'
            : '${item.displayName} koleksiyona eklendi ve kuşanıldı.',
        RelayNoticeTone.success,
      );
    } on RelayApiException catch (error) {
      _notice(error.message, RelayNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notice(String message, RelayNoticeTone tone) {
    if (!mounted) return;
    RelayNotice.show(context, message, tone: tone);
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('collection-header'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: RelayColors.cyan),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GÜÇ DEĞİL, KİMLİK VE HAZIRLIK',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Mağaza yalnız kozmetik satar. Sekizli kit ise savaşta '
                    'kullanabileceğiniz modül havuzunu sınırlar.',
                    style: TextStyle(color: RelayColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              avatar: const CircuitCreditGlyph(size: 18),
              label: Text(
                '$credits DEVRE KREDİSİ',
                key: const ValueKey('collection-credits'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitEditor extends StatelessWidget {
  const _KitEditor({
    required this.nameController,
    required this.slots,
    required this.busy,
    required this.onChanged,
    required this.onSave,
    this.showSaveButton = true,
  });

  final TextEditingController nameController;
  final List<ModuleKind> slots;
  final bool busy;
  final void Function(int index, ModuleKind kind) onChanged;
  final VoidCallback onSave;
  final bool showSaveButton;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('controlled-kit-card'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.view_module_outlined, color: RelayColors.mint),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'KONTROLLÜ SEKİZLİ KİT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Kartta en fazla altı modül bulunur; kalan iki yuva rakibe göre '
              'alternatif seçeneğinizdir. Kitte tam bir Jeneratör olmalıdır.',
              style: TextStyle(color: RelayColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('kit-name-field'),
              controller: nameController,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Kit adı',
                counterText: '',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 4 : 2;
                const spacing = 8.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var index = 0; index < slots.length; index++)
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<ModuleKind>(
                          key: ValueKey('kit-slot-$index'),
                          initialValue: slots[index],
                          decoration: InputDecoration(
                            labelText: 'Yuva ${index + 1}',
                            prefixIcon: ModuleGlyph(
                              kind: slots[index],
                              color: moduleColor(slots[index]),
                              size: 22,
                            ),
                          ),
                          items: [
                            for (final kind in ModuleKind.values)
                              DropdownMenuItem(
                                value: kind,
                                child: Text(kind.displayName),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (kind) {
                                  if (kind != null) onChanged(index, kind);
                                },
                        ),
                      ),
                  ],
                );
              },
            ),
            if (showSaveButton) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('save-controlled-kit'),
                onPressed: busy ? null : onSave,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(busy ? 'KAYDEDİLİYOR' : 'SEKİZLİ KİTİ KAYDET'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTitle extends StatelessWidget {
  const _CategoryTitle({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (category) {
      'module_skin' => (
        Icons.palette_outlined,
        'MODÜL KAPLAMALARI',
        'Modül simgesi ve bağlantı vurgusu',
      ),
      'board_theme' => (
        Icons.grid_4x4_outlined,
        'DEVRE KARTI TEMALARI',
        'Laboratuvar zemini ve hücre görünümü',
      ),
      _ => (
        Icons.account_box_outlined,
        'PROFİL ÇERÇEVELERİ',
        'Oyuncu adı ve ilerleme alanı görünümü',
      ),
    };
    return Row(
      children: [
        Icon(icon, color: RelayColors.cyan),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(
              subtitle,
              style: const TextStyle(color: RelayColors.muted, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.item,
    required this.busy,
    required this.onAction,
    this.compact = false,
  });

  final CosmeticItem item;
  final bool busy;
  final bool compact;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final accent = _hexColor(item.accentHex);
    final previewSize = compact ? 24.0 : 54.0;
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: compact ? 11 : 15,
    );
    return Card(
      key: ValueKey('cosmetic-${item.id}'),
      child: Padding(
        padding: EdgeInsets.all(compact ? 7 : 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: compact ? 38 : 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.24),
                    RelayColors.surfaceHigh.withValues(alpha: 0.74),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.78)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 16,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  item.category == 'module_skin'
                      ? Icons.memory
                      : item.category == 'board_theme'
                      ? Icons.grid_on
                      : Icons.person_outline,
                  color: accent,
                  size: previewSize,
                ),
              ),
            ),
            SizedBox(height: compact ? 5 : 9),
            Text(
              item.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
            const SizedBox(height: 3),
            Text(
              item.description,
              maxLines: compact ? 1 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: RelayColors.muted,
                fontSize: compact ? 8.2 : 10.5,
              ),
            ),
            SizedBox(height: compact ? 5 : 10),
            if (item.equipped)
              FilledButton.icon(
                style: compact
                    ? FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 10),
                      )
                    : null,
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('KUŞANILDI'),
              )
            else if (item.owned)
              OutlinedButton.icon(
                style: compact
                    ? OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 10),
                      )
                    : null,
                onPressed: busy ? null : onAction,
                icon: const Icon(Icons.checkroom_outlined),
                label: const Text('KUŞAN'),
              )
            else
              FilledButton.icon(
                style: compact
                    ? FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 10),
                      )
                    : null,
                onPressed: busy ? null : onAction,
                icon: const CircuitCreditGlyph(size: 18),
                label: Text('${item.creditCost} KREDİ'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollectionEmptyState extends StatelessWidget {
  const _CollectionEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        child: Column(
          children: [
            Icon(icon, color: RelayColors.muted, size: 38),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: RelayColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: RelayColors.coral, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('YENİDEN DENE'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _hexColor(String value) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse(normalized, radix: 16) ?? 0x38E8FF;
  return Color(0xFF000000 | parsed);
}
