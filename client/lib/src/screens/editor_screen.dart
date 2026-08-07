import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../models/relay_models.dart';
import '../navigation/navigation_actions.dart';
import '../state/board_controller.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import '../widgets/circuit_board.dart';
import '../widgets/module_palette.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/relay_notice.dart';
import 'collection_screen.dart';
import 'replay_screen.dart';

enum EditorMode {
  online,
  training,
  career;

  String get title => switch (this) {
        EditorMode.online => 'ÇEVRİMİÇİ SAVAŞ',
        EditorMode.training => 'ANTRENMAN',
        EditorMode.career => 'KARİYER DEVRESİ',
      };

  KitMode get kitMode => switch (this) {
        EditorMode.online => KitMode.online,
        EditorMode.training => KitMode.training,
        EditorMode.career => KitMode.career,
      };
}


class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    required this.mode,
    super.key,
  });

  final EditorMode mode;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  String _selectedBotId = 'starter_laser';
  bool _busy = false;
  bool _loadingBoard = false;
  final ScrollController _editorScrollController = ScrollController();
  EquippedVisuals _visuals = const EquippedVisuals.defaults();

  @override
  void initState() {
    super.initState();
    _loadingBoard = true;
    Future<void>.microtask(_loadModeBoard);
  }


  @override
  void dispose() {
    _editorScrollController.dispose();
    super.dispose();
  }

  NotifierProvider<BoardController, BoardEditorState> get _boardProvider =>
      switch (widget.mode) {
        EditorMode.online => onlineBoardControllerProvider,
        EditorMode.training => trainingBoardControllerProvider,
        EditorMode.career => careerBoardControllerProvider,
      };

  Color get _modeAccent => switch (widget.mode) {
        EditorMode.online => RelayColors.electricBlue,
        EditorMode.training => RelayColors.lime,
        EditorMode.career => RelayColors.amber,
      };

  @override
  Widget build(BuildContext context) {
    final catalogs = ref.watch(catalogsProvider);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROJECT RELAY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              '${widget.mode.title} • v0.8.16',
              style: const TextStyle(
                color: RelayColors.muted,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          const AppHeaderActions(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Katalogları yenile',
            onPressed: () => ref.invalidate(catalogsProvider),
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: RelayDecorations.modeShell(_modeAccent),
        child: SafeArea(
          child: catalogs.when(
          data: (bundle) => _loadingBoard
              ? const _LoadingPanel()
              : _buildEditor(bundle),
          loading: () => const _LoadingPanel(),
          error: (error, stackTrace) => _ConnectionError(
            error: error,
            onRetry: () => ref.invalidate(catalogsProvider),
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _loadModeBoard() async {
    try {
      await ref.read(guestSessionProvider.future);
      final api = ref.read(relayApiProvider);
      final controller = ref.read(_boardProvider.notifier);
      final collection = await ref.read(collectionProvider.future);
      _visuals = EquippedVisuals.fromCollection(collection);
      controller.applyKit(collection.kitFor(widget.mode.kitMode));
      final SavedBoard? saved = switch (widget.mode) {
        EditorMode.career => await api.fetchCareerBoard(),
        EditorMode.online => await api.fetchCurrentBoard(),
        EditorMode.training => null,
      };
      if (saved == null) {
        controller.reset();
      } else {
        controller.loadSavedBoard(saved);
      }
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Kayıtlı devre yüklenemedi: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingBoard = false);
      }
    }
  }

  Widget _buildEditor(CatalogBundle catalogs) {
    final boardState = ref.watch(_boardProvider);
    final guestSession = widget.mode != EditorMode.training
        ? ref.watch(guestSessionProvider)
        : const AsyncValue<GuestSession>.loading();
    final controller = ref.read(_boardProvider.notifier);
    final specs = {
      for (final module in catalogs.modules) module.kind: module,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 940;
        final viewportHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 900.0;
        final boardMaxWidth = wide
            ? math.min(520.0, math.max(360.0, viewportHeight * 0.50))
            : 560.0;
        final boardPanel = _BoardPanel(
          state: boardState,
          specs: specs,
          modules: catalogs.modules,
          boardMaxWidth: boardMaxWidth,
          visuals: _visuals,
          onPaletteSelected: controller.selectPalette,
          onBoardModuleReturned: _returnModuleToPalette,
          onCellTap: _tapCell,
          onModuleDropped: _dropModule,
          onRotateModule: controller.rotateAt,
          onReset: () {
            controller.reset();
            _showNotice(
              'Devre başlangıç düzenine döndürüldü.',
              RelayNoticeTone.info,
            );
          },
          onEditKit: _editStartingKit,
        );
        final actionPanel = _ActionPanel(
          mode: widget.mode,
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
          onSaveCareer: _saveCareerBoard,
          onStartBot: _startBotMatch,
        );
        final panels = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: boardPanel),
                  const SizedBox(width: 24),
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

        return Scrollbar(
          key: const ValueKey('editor-page-scrollbar'),
          controller: _editorScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            key: const ValueKey('editor-scroll-view'),
            controller: _editorScrollController,
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: panels,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editStartingKit() async {
    final kit = await Navigator.of(context).push<ControlledKit>(
      MaterialPageRoute<ControlledKit>(
        builder: (context) => CollectionScreen(
          kitOnly: true,
          kitMode: widget.mode.kitMode,
        ),
      ),
    );
    if (kit == null || !mounted) return;
    ref.read(_boardProvider.notifier).applyKit(kit);
    ref.invalidate(collectionProvider);
    setState(() {});
  }

  void _tapCell(int index) {
    try {
      ref.read(_boardProvider.notifier).tapCell(index);
    } on StateError catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _dropModule(int index, ModuleDragData data) {
    try {
      ref.read(_boardProvider.notifier).dropModule(index, data);
    } on StateError catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _returnModuleToPalette(ModuleDragData data) {
    final sourceCell = data.sourceCell;
    if (!data.isFromBoard || sourceCell == null) {
      return;
    }
    ref.read(_boardProvider.notifier).removeModuleAt(sourceCell);
    _showNotice(
      'Modül devre kartından kaldırıldı.',
      RelayNoticeTone.info,
    );
  }

  Future<void> _validateBoard() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final state = ref.read(_boardProvider);
      final validation =
          await ref.read(relayApiProvider).validateBoard(state.board);
      ref.read(_boardProvider.notifier).applyValidation(validation);
      if (mounted) {
        final unpowered = validation.unpoweredIds.length;
        _showNotice(
          unpowered == 0
              ? 'Devre geçerli; bütün modüller enerji alıyor.'
              : 'Devre geçerli; $unpowered modül enerji almıyor.',
          unpowered == 0
              ? RelayNoticeTone.success
              : RelayNoticeTone.warning,
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
      final state = ref.read(_boardProvider);
      final validation = await api.validateBoard(state.board);
      ref.read(_boardProvider.notifier).applyValidation(validation);
      await api.saveBoard(state.board);
      final match = await api.createAsyncMatch();
      await _openReplay(api, match);
      ref.invalidate(progressionProvider);
      ref.invalidate(statisticsProvider);
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

  Future<void> _saveCareerBoard() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(relayApiProvider);
      final state = ref.read(_boardProvider);
      final validation = await api.validateBoard(state.board);
      ref.read(_boardProvider.notifier).applyValidation(validation);
      await api.saveCareerBoard(state.board);
      ref.invalidate(careerRunProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Kariyer devresi kaydedilemedi: $error');
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
      final state = ref.read(_boardProvider);
      final validation = await api.validateBoard(state.board);
      ref.read(_boardProvider.notifier).applyValidation(validation);
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
    _showNotice(message, RelayNoticeTone.error);
  }

  void _showNotice(String message, RelayNoticeTone tone) {
    if (!mounted) return;
    RelayNotice.show(context, message, tone: tone);
  }

}

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({
    required this.state,
    required this.specs,
    required this.modules,
    required this.boardMaxWidth,
    required this.visuals,
    required this.onPaletteSelected,
    required this.onBoardModuleReturned,
    required this.onCellTap,
    required this.onModuleDropped,
    required this.onRotateModule,
    required this.onReset,
    required this.onEditKit,
  });

  final BoardEditorState state;
  final Map<ModuleKind, ModuleSpec> specs;
  final List<ModuleSpec> modules;
  final double boardMaxWidth;
  final EquippedVisuals visuals;
  final ValueChanged<ModuleKind> onPaletteSelected;
  final ValueChanged<ModuleDragData> onBoardModuleReturned;
  final ValueChanged<int> onCellTap;
  final ModuleDropCallback onModuleDropped;
  final ValueChanged<int> onRotateModule;
  final VoidCallback onReset;
  final VoidCallback onEditKit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          index: '1',
          title: 'MODÜL SEÇ',
          subtitle: '${state.kitName} • Kartta kullanabileceğiniz kit yuvaları '
              'sayı rozetlerinde görünür.',
        ),
        const SizedBox(height: 8),
        ModulePalette(
          compact: true,
          modules: modules,
          selectedKind: state.selectedKind,
          onSelected: onPaletteSelected,
          onBoardModuleReturned: onBoardModuleReturned,
          remainingByKind: {
            for (final module in modules)
              module.kind: state.remainingFor(module.kind),
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('editor-open-kit-builder'),
            onPressed: onEditKit,
            icon: const Icon(Icons.tune),
            label: const Text('BAŞLANGIÇ SEKİZLİSİNİ DEĞİŞTİR'),
          ),
        ),
        const SizedBox(height: 12),
        _SectionHeader(
          index: '2',
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
              visuals: visuals,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.mode,
    required this.state,
    required this.specs,
    required this.bots,
    required this.selectedBotId,
    required this.session,
    required this.busy,
    required this.onBotSelected,
    required this.onValidate,
    required this.onStartAsync,
    required this.onSaveCareer,
    required this.onStartBot,
  });

  final EditorMode mode;
  final BoardEditorState state;
  final Map<ModuleKind, ModuleSpec> specs;
  final List<BotDefinition> bots;
  final String selectedBotId;
  final AsyncValue<GuestSession> session;
  final bool busy;
  final ValueChanged<String> onBotSelected;
  final VoidCallback onValidate;
  final VoidCallback onStartAsync;
  final VoidCallback onSaveCareer;
  final VoidCallback onStartBot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        _SectionHeader(
          index: '3',
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
        if (mode == EditorMode.online) ...[
          const _SectionHeader(
            index: '4',
            title: 'ASENKRON PvP',
            subtitle:
                'Kartınızı kaydedin; sunucu eşit modüllü gerçek bir oyuncu '
                'devresi bulsun.',
          ),
          const SizedBox(height: 7),
          _AsyncMatchCard(
            session: session,
            busy: busy,
            onStartAsync: onStartAsync,
          ),
          const SizedBox(height: 8),
          _EditorMenuBackCard(busy: busy),
        ] else if (mode == EditorMode.career) ...[
          const _SectionHeader(
            index: '4',
            title: 'KARŞI DEVREYİ HAZIRLA',
            subtitle:
                'Rakip ön izlemesine göre devrenizi kaydedin ve kariyere dönün.',
          ),
          const SizedBox(height: 7),
          _CareerSaveCard(
            session: session,
            busy: busy,
            onSave: onSaveCareer,
          ),
          const SizedBox(height: 8),
          _EditorMenuBackCard(busy: busy),
        ] else ...[
          const _SectionHeader(
            index: '4',
            title: 'RAKİBİ SEÇ',
            subtitle:
                'Dokuz sabit rakipten birini seçip düzeninizi sınayın.',
          ),
          const SizedBox(height: 7),
          _TrainingPanel(
            bots: bots,
            moduleCount: state.placements.length,
            selectedBotId: selectedBotId,
            busy: busy,
            onBotSelected: onBotSelected,
            onStartBot: onStartBot,
          ),
          const SizedBox(height: 8),
          _EditorMenuBackCard(busy: busy),
        ],
      ],
    );
  }
}

class _AsyncMatchCard extends StatelessWidget {
  const _AsyncMatchCard({
    required this.session,
    required this.busy,
    required this.onStartAsync,
  });

  final AsyncValue<GuestSession> session;
  final bool busy;
  final VoidCallback onStartAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      error: (error, stackTrace) => 'Oturum kurulamadı',
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
              onPressed: busy || !session.hasValue ? null : onStartAsync,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.hub),
              label: Text(
                busy ? 'RAKİP ARANIYOR' : 'SAVAŞA BAŞLA',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kendinizle ve son rakiplerinizle eşleşmezsiniz. Uygun yeni '
              'oyuncu yoksa dengeli sunucu rakibi devreye girer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RelayColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerSaveCard extends StatelessWidget {
  const _CareerSaveCard({
    required this.session,
    required this.busy,
    required this.onSave,
  });

  final AsyncValue<GuestSession> session;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('career-save-card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bu düzen kaydedildiğinde kariyer ekranındaki tam rakip '
              'ön izlemesi güncellenir. Savaş yalnız kaydedilen devreyle başlar.',
              style: TextStyle(color: RelayColors.muted, fontSize: 10),
            ),
            const SizedBox(height: 9),
            FilledButton.icon(
              key: const ValueKey('career-save-button'),
              onPressed: busy || !session.hasValue ? null : onSave,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(busy ? 'KAYDEDİLİYOR' : 'KAYDET VE KARİYERE DÖN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorMenuBackCard extends StatelessWidget {
  const _EditorMenuBackCard({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('editor-menu-back-card'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: OutlinedButton.icon(
          key: const ValueKey('editor-menu-back-button'),
          onPressed: busy ? null : () => returnToPreviousMenu(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('MENÜYE DÖN'),
        ),
      ),
    );
  }
}

class _TrainingPanel extends StatelessWidget {
  const _TrainingPanel({
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
      key: const ValueKey('training-panel'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  color: RelayColors.amber,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'ANTRENMAN RAKİPLERİ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
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
