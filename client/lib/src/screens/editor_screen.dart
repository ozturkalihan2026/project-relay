import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../state/board_controller.dart';
import '../theme/relay_theme.dart';
import '../widgets/circuit_board.dart';
import '../widgets/game_manual.dart';
import '../widgets/module_palette.dart';
import 'replay_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  String _selectedBotId = 'starter_laser';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final catalogs = ref.watch(catalogsProvider);
    final guestSession = ref.watch(guestSessionProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROJECT RELAY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              'DEVRE LABORATUVARI • v0.4.2',
              style: TextStyle(
                color: RelayColors.muted,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          _SessionBadge(
            session: guestSession,
            onRetry: () => ref.invalidate(guestSessionProvider),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Katalogları yenile',
            onPressed: () => ref.invalidate(catalogsProvider),
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: catalogs.when(
          data: _buildEditor,
          loading: () => const _LoadingPanel(),
          error: (error, stackTrace) => _ConnectionError(
            error: error,
            onRetry: () => ref.invalidate(catalogsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(CatalogBundle catalogs) {
    final boardState = ref.watch(boardControllerProvider);
    final guestSession = ref.watch(guestSessionProvider);
    final controller = ref.read(boardControllerProvider.notifier);
    final specs = {
      for (final module in catalogs.modules) module.kind: module,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 940;
        final viewportHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 900.0;
        final boardMaxWidth = wide
            ? math.min(460.0, math.max(340.0, viewportHeight * 0.44))
            : 560.0;
        final boardPanel = _BoardPanel(
          state: boardState,
          specs: specs,
          modules: catalogs.modules,
          boardMaxWidth: boardMaxWidth,
          onPaletteSelected: controller.selectPalette,
          onBoardModuleReturned: _returnModuleToPalette,
          onCellTap: _tapCell,
          onModuleDropped: _dropModule,
          onRotateModule: controller.rotateAt,
          onReset: controller.reset,
        );
        final actionPanel = _ActionPanel(
          rulesVersion: catalogs.rulesVersion,
          state: boardState,
          specs: specs,
          bots: catalogs.bots,
          selectedBotId: _selectedBotId,
          session: guestSession,
          busy: _busy,
          onBotSelected: (botId) {
            setState(() => _selectedBotId = botId);
          },
          onValidate: _validateBoard,
          onStartAsync: _startAsyncMatch,
          onStartBot: _startBotMatch,
        );
        final panels = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: boardPanel),
                  const SizedBox(width: 14),
                  SizedBox(width: 370, child: actionPanel),
                ],
              )
            : Column(
                children: [
                  boardPanel,
                  const SizedBox(height: 14),
                  actionPanel,
                ],
              );

        return SingleChildScrollView(
          key: const ValueKey('editor-scroll-view'),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HowToPlayCard(modules: catalogs.modules),
                  const SizedBox(height: 10),
                  panels,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _tapCell(int index) {
    try {
      ref.read(boardControllerProvider.notifier).tapCell(index);
    } on StateError catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _dropModule(int index, ModuleDragData data) {
    try {
      ref.read(boardControllerProvider.notifier).dropModule(index, data);
    } on StateError catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _returnModuleToPalette(ModuleDragData data) {
    final sourceCell = data.sourceCell;
    if (!data.isFromBoard || sourceCell == null) {
      return;
    }
    ref.read(boardControllerProvider.notifier).removeModuleAt(sourceCell);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modül devre kartından kaldırıldı.')),
    );
  }

  Future<void> _validateBoard() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final state = ref.read(boardControllerProvider);
      final validation =
          await ref.read(relayApiProvider).validateBoard(state.board);
      ref
          .read(boardControllerProvider.notifier)
          .applyValidation(validation);
      if (mounted) {
        final unpowered = validation.unpoweredIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              unpowered == 0
                  ? 'Devre geçerli; bütün modüller enerji alıyor.'
                  : 'Devre geçerli; $unpowered modül enerji almıyor.',
            ),
          ),
        );
      }
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Devre doğrulanamadı: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _startAsyncMatch() async {
    if (_busy) {
      return;
    }
    final session = ref.read(guestSessionProvider);
    if (!session.hasValue) {
      _showError(
        'Misafir oturumu henüz hazır değil. Bağlantıyı kontrol edip '
        'yeniden deneyin.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(relayApiProvider);
      final state = ref.read(boardControllerProvider);
      final validation = await api.validateBoard(state.board);
      ref
          .read(boardControllerProvider.notifier)
          .applyValidation(validation);
      await api.saveBoard(state.board);
      final match = await api.createAsyncMatch();
      await _openReplay(api, match);
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Asenkron savaş başlatılamadı: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _startBotMatch() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(relayApiProvider);
      final state = ref.read(boardControllerProvider);
      final validation = await api.validateBoard(state.board);
      ref
          .read(boardControllerProvider.notifier)
          .applyValidation(validation);
      final match = await api.createBotMatch(
        board: state.board,
        botId: _selectedBotId,
      );
      await _openReplay(api, match);
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Savaş başlatılamadı: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openReplay(
    RelayApi api,
    MatchResponse match,
  ) async {
    final replay = await api.fetchReplay(match.id);
    if (replay.checksum != match.replayChecksum) {
      throw const RelayApiException(
        'Replay özeti maç sonucuyla uyuşmuyor.',
      );
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReplayScreen(
          match: match,
          replay: replay,
          modules: ref.read(catalogsProvider).requireValue.modules,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF713D45),
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({
    required this.state,
    required this.specs,
    required this.modules,
    required this.boardMaxWidth,
    required this.onPaletteSelected,
    required this.onBoardModuleReturned,
    required this.onCellTap,
    required this.onModuleDropped,
    required this.onRotateModule,
    required this.onReset,
  });

  final BoardEditorState state;
  final Map<ModuleKind, ModuleSpec> specs;
  final List<ModuleSpec> modules;
  final double boardMaxWidth;
  final ValueChanged<ModuleKind> onPaletteSelected;
  final ValueChanged<ModuleDragData> onBoardModuleReturned;
  final ValueChanged<int> onCellTap;
  final ModuleDropCallback onModuleDropped;
  final ValueChanged<int> onRotateModule;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          index: '01',
          title: 'MODÜL SEÇ',
          subtitle: 'Boş hücreye yerleştirin; dolu hücredeki modülü '
              'değiştirin.',
        ),
        const SizedBox(height: 8),
        ModulePalette(
          modules: modules,
          selectedKind: state.selectedKind,
          onSelected: onPaletteSelected,
          onBoardModuleReturned: onBoardModuleReturned,
        ),
        const SizedBox(height: 12),
        _SectionHeader(
          index: '02',
          title: 'DEVREYİ KUR',
          subtitle: '12 çevre hücresini kullanın; Jeneratörü dört çekirdek '
              'kapısından birine yerleştirin.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${state.placements.length}/$maxBoardModules MODÜL',
                style: const TextStyle(
                  color: RelayColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Sıfırla'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: boardMaxWidth),
            child: CircuitBoard(
              placements: state.placements,
              specs: specs,
              poweredIds: state.validation?.poweredIds ?? const {},
              validationVisible: state.validation != null,
              selectedCell: state.selectedCell,
              onCellTap: onCellTap,
              onModuleDropped: onModuleDropped,
              onRotateModule: onRotateModule,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.rulesVersion,
    required this.state,
    required this.specs,
    required this.bots,
    required this.selectedBotId,
    required this.session,
    required this.busy,
    required this.onBotSelected,
    required this.onValidate,
    required this.onStartAsync,
    required this.onStartBot,
  });

  final String rulesVersion;
  final BoardEditorState state;
  final Map<ModuleKind, ModuleSpec> specs;
  final List<BotDefinition> bots;
  final String selectedBotId;
  final AsyncValue<GuestSession> session;
  final bool busy;
  final ValueChanged<String> onBotSelected;
  final VoidCallback onValidate;
  final VoidCallback onStartAsync;
  final VoidCallback onStartBot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x2238E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(
                      Icons.dns_outlined,
                      color: RelayColors.cyan,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUNUCU YETKİLİ SAVAŞ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Kural $rulesVersion • Sonucu telefon belirlemez',
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionHeader(
          index: '03',
          title: 'ENERJİYİ KONTROL ET',
          subtitle: 'Sunucu bağlı ve bağlantısız modülleri işaretler.',
        ),
        const SizedBox(height: 7),
        _ValidationCard(
          state: state,
          specs: specs,
          busy: busy,
          onValidate: onValidate,
        ),
        const SizedBox(height: 12),
        _SectionHeader(
          index: '04',
          title: 'ASENKRON PvP',
          subtitle: 'Kartınızı kaydedin; sunucu eşit modüllü gerçek bir '
              'oyuncu devresi bulsun.',
        ),
        const SizedBox(height: 7),
        Card(
          key: const ValueKey('async-pvp-card'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.public,
                      color: RelayColors.mint,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        session.when(
                          data: (value) =>
                              '${value.player.displayName} olarak hazırsınız',
                          loading: () => 'Misafir oturumu hazırlanıyor…',
                          error: (error, stackTrace) =>
                              'Oturum kurulamadı',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                FilledButton.icon(
                  key: const ValueKey('async-match-button'),
                  onPressed:
                      busy || !session.hasValue ? null : onStartAsync,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.hub),
                  label: Text(
                    busy
                        ? 'RAKİP ARANIYOR'
                        : 'KARTI KAYDET VE OYUNCU BUL',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kendinizle ve son rakiplerinizle eşleşmezsiniz. Uygun '
                  'yeni oyuncu yoksa dengeli sunucu rakibi devreye girer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RelayColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _BotPracticePanel(
          bots: bots,
          moduleCount: state.placements.length,
          selectedBotId: selectedBotId,
          busy: busy,
          onBotSelected: onBotSelected,
          onStartBot: onStartBot,
        ),
      ],
    );
  }
}

class _BotPracticePanel extends StatelessWidget {
  const _BotPracticePanel({
    required this.bots,
    required this.moduleCount,
    required this.selectedBotId,
    required this.busy,
    required this.onBotSelected,
    required this.onStartBot,
  });

  final List<BotDefinition> bots;
  final int moduleCount;
  final String selectedBotId;
  final bool busy;
  final ValueChanged<String> onBotSelected;
  final VoidCallback onStartBot;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const ValueKey('bot-practice-panel'),
        leading: const Icon(
          Icons.smart_toy_outlined,
          color: RelayColors.amber,
        ),
        title: const Text(
          'BOT ANTRENMANI',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        subtitle: const Text(
          'İsterseniz dokuz sabit rakiple düzeninizi sınayın.',
          style: TextStyle(color: RelayColors.muted, fontSize: 10),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * 0.22)
                .clamp(165.0, 215.0)
                .toDouble(),
            child: _BotPicker(
              bots: bots,
              moduleCount: moduleCount,
              selectedBotId: selectedBotId,
              onBotSelected: onBotSelected,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onStartBot,
              icon: const Icon(Icons.sports_mma),
              label: const Text('SEÇİLİ BOTLA SAVAŞ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotPicker extends StatefulWidget {
  const _BotPicker({
    required this.bots,
    required this.moduleCount,
    required this.selectedBotId,
    required this.onBotSelected,
  });

  final List<BotDefinition> bots;
  final int moduleCount;
  final String selectedBotId;
  final ValueChanged<String> onBotSelected;

  @override
  State<_BotPicker> createState() => _BotPickerState();
}

class _BotPickerState extends State<_BotPicker> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      key: const ValueKey('bot-picker-scrollbar'),
      controller: _controller,
      thumbVisibility: true,
      interactive: true,
      child: ListView.separated(
        key: const ValueKey('bot-picker-list'),
        controller: _controller,
        primary: false,
        padding: const EdgeInsets.only(right: 10),
        itemCount: widget.bots.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final bot = widget.bots[index];
          return _BotCard(
            bot: bot,
            moduleCount: widget.moduleCount,
            selected: bot.id == widget.selectedBotId,
            onTap: () => widget.onBotSelected(bot.id),
          );
        },
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({
    required this.state,
    required this.specs,
    required this.busy,
    required this.onValidate,
  });

  final BoardEditorState state;
  final Map<ModuleKind, ModuleSpec> specs;
  final bool busy;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final result = state.validation;
    final unpoweredLabels = result?.unpoweredIds
            .map(_unpoweredModuleLabel)
            .toList(growable: false) ??
        const <String>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result == null)
              const Row(
                children: [
                  Icon(Icons.help_outline, color: RelayColors.muted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Devre henüz sunucuda doğrulanmadı.',
                      style: TextStyle(color: RelayColors.muted),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: RelayColors.mint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${result.poweredIds.length}/'
                      '${state.placements.length} modül enerjili',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if (result.unpoweredIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Enerjisiz: ${unpoweredLabels.join(', ')}',
                  style: const TextStyle(
                    color: RelayColors.coral,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: busy ? null : onValidate,
              icon: const Icon(Icons.electrical_services),
              label: const Text('Bağlantıları Doğrula'),
            ),
          ],
        ),
      ),
    );
  }

  String _unpoweredModuleLabel(String id) {
    final placement = state.placementById(id);
    if (placement == null) {
      return 'Bilinmeyen modül';
    }
    final name = specs[placement.kind]?.displayName ??
        placement.kind.displayName;
    return '$name (${placement.row + 1},${placement.column + 1})';
  }
}

class _BotCard extends StatelessWidget {
  const _BotCard({
    required this.bot,
    required this.moduleCount,
    required this.selected,
    required this.onTap,
  });

  final BotDefinition bot;
  final int moduleCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difficulty = switch (bot.difficulty) {
      'easy' => 'KOLAY',
      'medium' => 'ORTA',
      'hard' => 'ZOR',
      'expert' => 'UZMAN',
      _ => bot.difficulty.toUpperCase(),
    };
    return Material(
      color: selected
          ? RelayColors.cyan.withValues(alpha: 0.12)
          : RelayColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? RelayColors.cyan : const Color(0xFF245161),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? RelayColors.cyan : RelayColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bot.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          difficulty,
                          style: TextStyle(
                            color: selected
                                ? RelayColors.cyan
                                : RelayColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bot.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RelayColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bot.availableModuleCounts.contains(moduleCount)
                          ? '$moduleCount modüllük eşleşme hazır'
                          : '$moduleCount modüllük düzen bulunmuyor',
                      style: TextStyle(
                        color: bot.availableModuleCounts.contains(moduleCount)
                            ? RelayColors.mint
                            : RelayColors.coral,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.index,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String index;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          index,
          style: const TextStyle(
            color: RelayColors.cyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: RelayColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SessionBadge extends StatelessWidget {
  const _SessionBadge({
    required this.session,
    required this.onRetry,
  });

  final AsyncValue<GuestSession> session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    return session.when(
      data: (value) => Tooltip(
        message: 'Kalıcı misafir: ${value.player.displayName}',
        child: Container(
          key: const ValueKey('guest-session-badge'),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: RelayColors.mint.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: RelayColors.mint.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_done_outlined,
                color: RelayColors.mint,
                size: 17,
              ),
              if (!compact) ...[
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 125),
                  child: Text(
                    value.player.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RelayColors.mint,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      loading: () => const SizedBox(
        key: ValueKey('guest-session-loading'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stackTrace) => IconButton(
        tooltip: 'Misafir oturumunu yeniden dene',
        onPressed: onRetry,
        icon: const Icon(
          Icons.cloud_off_outlined,
          color: RelayColors.coral,
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Sunucu katalogları alınıyor…'),
        ],
      ),
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: RelayColors.coral,
                  size: 42,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Project Relay API’ye bağlanılamadı',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: RelayColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
