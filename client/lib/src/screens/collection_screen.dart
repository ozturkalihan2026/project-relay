import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../theme/relay_theme.dart';
import '../widgets/module_visuals.dart';
import '../widgets/player_status_bar.dart';
import '../widgets/relay_notice.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController _kitNameController = TextEditingController();
  CollectionSnapshot? _snapshot;
  List<ModuleKind>? _kitSlots;
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KOLEKSİYON VE KİT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'PROJECT RELAY • v0.8.0',
              style: TextStyle(color: RelayColors.muted, fontSize: 10),
            ),
          ],
        ),
        actions: const [
          Center(child: PlayerStatusBar(compact: true)),
          SizedBox(width: 10),
        ],
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
    _kitSlots = List<ModuleKind>.from(value.kit.moduleKinds);
    _kitNameController.text = value.kit.name;
  }

  Widget _buildContent(CollectionSnapshot snapshot) {
    final kitSlots = _kitSlots ?? snapshot.kit.moduleKinds;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(collectionProvider);
        final refreshed = await ref.read(collectionProvider.future);
        if (!mounted) return;
        setState(() {
          _snapshot = refreshed;
          _kitSlots = List<ModuleKind>.from(refreshed.kit.moduleKinds);
          _kitNameController.text = refreshed.kit.name;
        });
      },
      child: ListView(
        key: const ValueKey('collection-scroll-view'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          _CollectionHeader(credits: snapshot.credits),
          const SizedBox(height: 14),
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
            onSave: _saveKit,
          ),
          const SizedBox(height: 18),
          for (final category in const [
            'module_skin',
            'board_theme',
            'profile_frame',
          ]) ...[
            _CategoryTitle(category: category),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 960
                    ? 3
                    : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                const spacing = 10.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final items = snapshot.cosmetics
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
                          onAction: () => _cosmeticAction(item),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
          ],
          OutlinedButton.icon(
            key: const ValueKey('collection-menu-back'),
            onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('ANA MENÜYE DÖN'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveKit() async {
    if (_busy) return;
    final slots = _kitSlots;
    if (slots == null || slots.length != 8) {
      _notice('Kit tam olarak sekiz yuva içermelidir.', RelayNoticeTone.error);
      return;
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
      return;
    }
    final excessive = counts.entries
        .where((entry) =>
            entry.key != ModuleKind.generator && entry.value > 3)
        .map((entry) => entry.key.displayName)
        .toList(growable: false);
    if (excessive.isNotEmpty) {
      _notice(
        'Bir modül türü en fazla üç yuvada bulunabilir: '
        '${excessive.join(', ')}',
        RelayNoticeTone.warning,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final value = await ref.read(relayApiProvider).saveControlledKit(
            name: _kitNameController.text,
            moduleKinds: slots,
          );
      if (!mounted) return;
      setState(() {
        _snapshot = value;
        _kitSlots = List<ModuleKind>.from(value.kit.moduleKinds);
      });
      ref.invalidate(collectionProvider);
      _notice(
        'Sekizli kit kaydedildi. Editör paletleri artık bu sınırlara bağlı.',
        RelayNoticeTone.success,
      );
    } on RelayApiException catch (error) {
      _notice(error.message, RelayNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              avatar: const Icon(
                Icons.toll_outlined,
                color: RelayColors.amber,
                size: 18,
              ),
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
  });

  final TextEditingController nameController;
  final List<ModuleKind> slots;
  final bool busy;
  final void Function(int index, ModuleKind kind) onChanged;
  final VoidCallback onSave;

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
                            prefixIcon: Icon(
                              moduleIcon(slots[index]),
                              color: moduleColor(slots[index]),
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
  });

  final CosmeticItem item;
  final bool busy;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final accent = _hexColor(item.accentHex);
    return Card(
      key: ValueKey('cosmetic-${item.id}'),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.7)),
              ),
              child: Center(
                child: Icon(
                  item.category == 'module_skin'
                      ? Icons.memory
                      : item.category == 'board_theme'
                          ? Icons.grid_on
                          : Icons.person_outline,
                  color: accent,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              item.displayName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              item.description,
              style: const TextStyle(color: RelayColors.muted, fontSize: 10.5),
            ),
            const SizedBox(height: 10),
            if (item.equipped)
              FilledButton.icon(
                onPressed: null,
                icon: Icon(Icons.check_circle_outline),
                label: Text('KUŞANILDI'),
              )
            else if (item.owned)
              OutlinedButton.icon(
                onPressed: busy ? null : onAction,
                icon: const Icon(Icons.checkroom_outlined),
                label: const Text('KUŞAN'),
              )
            else
              FilledButton.icon(
                onPressed: busy ? null : onAction,
                icon: const Icon(Icons.toll_outlined),
                label: Text('${item.creditCost} KREDİ'),
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
