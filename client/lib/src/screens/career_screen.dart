import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/relay_api.dart';
import '../game/module_placement_sound_player.dart';
import '../models/relay_models.dart';
import '../navigation/navigation_actions.dart';
import '../state/app_settings.dart';
import '../state/board_controller.dart';
import '../theme/cosmetic_visuals.dart';
import '../theme/relay_theme.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/circuit_board.dart';
import '../widgets/module_palette.dart';
import '../widgets/relay_notice.dart';
import '../widgets/relay_dialog.dart';
import 'career_battle_screen.dart';
import 'collection_screen.dart';

const double _careerPanelWidth = 430;
const double _careerPanelHeight = 500;
const double _careerBoardMaxWidth = 390;
const double _careerModuleBoardGap = 12;
const double _careerPlayerOpponentGap = 36;
const double _careerPlayerEditorWidth =
    (_careerPanelWidth * 2) + _careerModuleBoardGap;

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen> {
  String? _runAction;
  String? _loadedBoardSignature;
  EquippedVisuals _visuals = const EquippedVisuals.defaults();
  late final ModulePlacementSoundPlayer _placementSoundPlayer;

  bool get _runBusy => _runAction != null;

  @override
  void initState() {
    super.initState();
    _placementSoundPlayer = ModulePlacementSoundPlayer();
  }

  @override
  void dispose() {
    unawaited(_placementSoundPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progression = ref.watch(progressionProvider);
    final run = ref.watch(careerRunProvider);
    final catalogs = ref.watch(catalogsProvider);
    final careerBoard = ref.watch(careerBoardProvider);
    final collection = ref.watch(collectionProvider);
    final editorState = ref.watch(careerBoardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 224,
        leading: const AppHeaderProfile(),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const AppHeaderTitle(pageTitle: 'KARİYER'),
        actions: const [
          AppHeaderActions(),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: RelayDecorations.modeShell(RelayColors.amber),
        child: SafeArea(
          child: progression.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CareerError(
            message: error.toString(),
            onRetry: _refreshAll,
          ),
          data: (snapshot) => run.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _CareerError(
              message: error.toString(),
              onRetry: _refreshAll,
            ),
            data: (careerRun) => catalogs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _CareerError(
                message: error.toString(),
                onRetry: _refreshAll,
              ),
              data: (catalog) => careerBoard.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _CareerError(
                  message: error.toString(),
                  onRetry: _refreshAll,
                ),
                data: (savedBoard) => collection.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _CareerError(
                    message: error.toString(),
                    onRetry: _refreshAll,
                  ),
                  data: (collectionSnapshot) {
                    _scheduleEditorInitialization(
                      savedBoard,
                      collectionSnapshot,
                    );
                    final specs = {
                      for (final module in catalog.modules)
                        module.kind: module,
                    };
                    final playerEditor = _CareerInlineEditor(
                      state: editorState,
                      specs: specs,
                      modules: catalog.modules,
                      visuals: _visuals,
                      busy: _runBusy,
                      onPaletteSelected: ref
                          .read(careerBoardControllerProvider.notifier)
                          .selectPalette,
                      onBoardModuleReturned: _returnModuleToPalette,
                      onCellTap: _tapCell,
                      onModuleDropped: _dropModule,
                      onRotateModule: ref
                          .read(careerBoardControllerProvider.notifier)
                          .rotateAt,
                      onReset: _resetCareerBoard,
                      onValidate: _validateCareerBoard,
                      onEditKit: _editCareerKit,
                    );
                    return RefreshIndicator(
                      onRefresh: _refreshAll,
                      child: ListView(
                        key: const ValueKey('career-scroll-view'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _ProgressCard(profile: snapshot.profile),
                          const SizedBox(height: 12),
                          _CareerRunCard(
                            run: careerRun,
                            playerEditor: playerEditor,
                            modules: catalog.modules,
                            availableCredits: snapshot.profile.credits,
                            busyAction: _runAction,
                            onStart: _prepareRun,
                            onBattle: () => _battle(catalog.modules),
                            onChooseBooster: _chooseBooster,
                            onSkipBooster: () => _chooseBooster('none'),
                            onAbandon: _confirmAbandon,
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'BOSS GÜÇLENDİRİCİ KADEMELERİ',
                            icon: Icons.bolt_outlined,
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: RelayColors.amber
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: RelayColors.amber
                                          .withValues(alpha: 0.38),
                                    ),
                                  ),
                                  child: const Text(
                                    'Bu kademeler modüllere kalıcı güç vermez. '
                                    'Yalnız kariyer koşusunda, boss savaşı öncesinde '
                                    'Devre Kredisiyle alınan geçici güçlendiricinin '
                                    'etkisini belirler. K2/K3/K4/K5 sırasıyla '
                                    '10, 20, 30 ve 40. seviyelerde açılır.',
                                    style: TextStyle(
                                      color: RelayColors.muted,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                for (final booster in snapshot.boosters)
                                  _BoosterRow(booster: booster),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            key: const ValueKey('career-back-button'),
                            onPressed: _runBusy
                                ? null
                                : () => returnToPreviousMenu(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('MENÜYE DÖN'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  void _scheduleEditorInitialization(
    SavedBoard? savedBoard,
    CollectionSnapshot collection,
  ) {
    final signature = [
      savedBoard?.fingerprint ?? 'empty',
      collection.kitFor(KitMode.career).updatedAt.toIso8601String(),
      collection.equippedBoardThemeId,
      collection.equippedModuleSkinId,
    ].join('|');
    if (_loadedBoardSignature == signature) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedBoardSignature == signature) return;
      final controller = ref.read(careerBoardControllerProvider.notifier);
      controller.applyKit(collection.kitFor(KitMode.career));
      if (savedBoard == null) {
        controller.reset();
      } else {
        controller.loadSavedBoard(savedBoard);
      }
      setState(() {
        _loadedBoardSignature = signature;
        _visuals = EquippedVisuals.fromCollection(collection);
      });
    });
  }

  Future<void> _refreshAll() async {
    _loadedBoardSignature = null;
    ref.invalidate(progressionProvider);
    ref.invalidate(careerRunProvider);
    ref.invalidate(catalogsProvider);
    ref.invalidate(careerBoardProvider);
    ref.invalidate(collectionProvider);
    await Future.wait([
      ref.read(progressionProvider.future),
      ref.read(careerRunProvider.future),
      ref.read(catalogsProvider.future),
      ref.read(careerBoardProvider.future),
      ref.read(collectionProvider.future),
    ]);
  }

  Future<void> _editCareerKit() async {
    final kit = await Navigator.of(context).push<ControlledKit>(
      MaterialPageRoute<ControlledKit>(
        builder: (context) => const CollectionScreen(
          kitOnly: true,
          kitMode: KitMode.career,
        ),
      ),
    );
    if (kit == null || !mounted) return;
    ref.read(careerBoardControllerProvider.notifier).applyKit(kit);
    ref.invalidate(collectionProvider);
    _loadedBoardSignature = null;
    setState(() {});
  }

  void _tapCell(int index) {
    try {
      final before = ref.read(careerBoardControllerProvider);
      final shouldSeatModule =
          before.placements[index] == null && before.selectedKind != null;
      ref.read(careerBoardControllerProvider.notifier).tapCell(index);
      if (shouldSeatModule) {
        _playPlacementSound();
      }
    } on StateError catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _dropModule(int index, ModuleDragData data) {
    try {
      ref.read(careerBoardControllerProvider.notifier).dropModule(index, data);
      _playPlacementSound();
    } on StateError catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _playPlacementSound() {
    if (ref.read(appSettingsProvider).replaySoundEnabled) {
      unawaited(_placementSoundPlayer.playLock());
    }
  }

  void _returnModuleToPalette(ModuleDragData data) {
    final sourceCell = data.sourceCell;
    if (!data.isFromBoard || sourceCell == null) return;
    ref.read(careerBoardControllerProvider.notifier).removeModuleAt(sourceCell);
    RelayNotice.show(
      context,
      'Modül kariyer devresinden kaldırıldı.',
      tone: RelayNoticeTone.info,
    );
  }

  void _resetCareerBoard() {
    ref.read(careerBoardControllerProvider.notifier).reset();
    RelayNotice.show(
      context,
      'Kariyer devresi başlangıç düzenine döndürüldü.',
      tone: RelayNoticeTone.info,
    );
  }

  Future<void> _validateCareerBoard() async {
    if (_runBusy) return;
    setState(() => _runAction = 'validate');
    try {
      final state = ref.read(careerBoardControllerProvider);
      final validation =
          await ref.read(relayApiProvider).validateBoard(state.board);
      ref.read(careerBoardControllerProvider.notifier).applyValidation(validation);
      if (mounted) {
        final unpowered = validation.unpoweredIds.length;
        RelayNotice.show(
          context,
          unpowered == 0
              ? 'Kariyer devresi geçerli; bütün modüller enerji alıyor.'
              : 'Kariyer devresi geçerli; $unpowered modül enerji almıyor.',
          tone: unpowered == 0
              ? RelayNoticeTone.success
              : RelayNoticeTone.warning,
        );
      }
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Kariyer devresi doğrulanamadı: $error');
    } finally {
      if (mounted) setState(() => _runAction = null);
    }
  }

  Future<SavedBoard> _validateAndSaveCareerBoard() async {
    final api = ref.read(relayApiProvider);
    final state = ref.read(careerBoardControllerProvider);
    final validation = await api.validateBoard(state.board);
    ref.read(careerBoardControllerProvider.notifier).applyValidation(validation);
    final saved = await api.saveCareerBoard(state.board);
    ref.invalidate(careerBoardProvider);
    return saved;
  }

  Future<void> _prepareRun() async {
    if (_runBusy) return;
    setState(() => _runAction = 'start');
    try {
      await _validateAndSaveCareerBoard();
      await ref.read(relayApiProvider).startCareerRun();
      ref.invalidate(careerRunProvider);
      ref.invalidate(careerBoardProvider);
      await Future.wait([
        ref.read(careerRunProvider.future),
        ref.read(careerBoardProvider.future),
      ]);
      if (mounted) {
        RelayNotice.show(
          context,
          'Kariyer koşusu hazırlandı. Rakip devreyi inceleyip savaşı başlatabilirsin.',
          tone: RelayNoticeTone.success,
        );
      }
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Kariyer koşusu hazırlanamadı: $error');
    } finally {
      if (mounted) setState(() => _runAction = null);
    }
  }

  Future<void> _chooseBooster(String boosterId) async {
    await _executeRunAction('booster:$boosterId', () async {
      await ref.read(relayApiProvider).chooseCareerBooster(boosterId);
    });
  }

  Future<void> _confirmAbandon() async {
    if (_runBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => const RelayConfirmDialog(
        title: 'Koşuyu bırak?',
        message: 'Mevcut aşama ve bütün geçici güçlendiriciler sıfırlanacak.',
        confirmLabel: 'KOŞUYU BIRAK',
        destructive: true,
      ),
    );
    if (confirmed != true) return;
    await _executeRunAction('abandon', () async {
      await ref.read(relayApiProvider).abandonCareerRun();
    });
  }

  Future<void> _battle(List<ModuleSpec> modules) async {
    if (_runBusy) return;
    final runBeforeBattle = ref.read(careerRunProvider).requireValue;
    final stageNumber = runBeforeBattle.opponent?.stageNumber ??
        (runBeforeBattle.stageIndex + 1);
    setState(() => _runAction = 'battle');
    try {
      final api = ref.read(relayApiProvider);
      await _validateAndSaveCareerBoard();
      final outcome = await api.battleCareerRun();
      final replay = await api.fetchReplay(outcome.match.id);
      if (replay.checksum != outcome.match.replayChecksum) {
        throw const RelayApiException(
          'Kariyer replay özeti maç sonucuyla uyuşmuyor.',
        );
      }
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => CareerBattleScreen(
              outcome: outcome,
              replay: replay,
              modules: modules,
              stageNumber: stageNumber,
            ),
          ),
        );
      }
      ref.invalidate(careerRunProvider);
      ref.invalidate(progressionProvider);
      await Future.wait([
        ref.read(careerRunProvider.future),
        ref.read(progressionProvider.future),
      ]);
    } catch (error) {
      _showError('Kariyer savaşı başlatılamadı: $error');
    } finally {
      if (mounted) setState(() => _runAction = null);
    }
  }

  Future<void> _executeRunAction(
    String action,
    Future<void> Function() callback,
  ) async {
    if (_runBusy) return;
    setState(() => _runAction = action);
    try {
      await callback();
      ref.invalidate(careerRunProvider);
      ref.invalidate(progressionProvider);
      await Future.wait([
        ref.read(careerRunProvider.future),
        ref.read(progressionProvider.future),
      ]);
    } on RelayApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _runAction = null);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    RelayNotice.show(context, message, tone: RelayNoticeTone.error);
  }
}

class _CareerInlineEditor extends StatelessWidget {
  const _CareerInlineEditor({
    required this.state,
    required this.specs,
    required this.modules,
    required this.visuals,
    required this.busy,
    required this.onPaletteSelected,
    required this.onBoardModuleReturned,
    required this.onCellTap,
    required this.onModuleDropped,
    required this.onRotateModule,
    required this.onReset,
    required this.onValidate,
    required this.onEditKit,
  });

  final BoardEditorState state;
  final Map<ModuleKind, ModuleSpec> specs;
  final List<ModuleSpec> modules;
  final EquippedVisuals visuals;
  final bool busy;
  final ValueChanged<ModuleKind> onPaletteSelected;
  final ValueChanged<ModuleDragData> onBoardModuleReturned;
  final ValueChanged<int> onCellTap;
  final ModuleDropCallback onModuleDropped;
  final ValueChanged<int> onRotateModule;
  final VoidCallback onReset;
  final VoidCallback onValidate;
  final VoidCallback onEditKit;

  @override
  Widget build(BuildContext context) {
    final validation = state.validation;
    final statusText = validation == null
        ? 'Devre henüz doğrulanmadı.'
        : validation.unpoweredIds.isEmpty
            ? 'Devre geçerli • Bütün modüller enerjili'
            : 'Devre geçerli • ${validation.unpoweredIds.length} modül enerjisiz';
    final statusColor = validation == null
        ? RelayColors.muted
        : validation.unpoweredIds.isEmpty
            ? RelayColors.mint
            : RelayColors.amber;

    final moduleCard = Container(
      key: const ValueKey('career-module-selection-card'),
      width: _careerPanelWidth,
      height: _careerPanelHeight,
      padding: const EdgeInsets.all(12),
      decoration: RelayDecorations.panel(
        accent: RelayColors.mint,
        soft: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.view_module_outlined, color: RelayColors.mint),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MODÜL SEÇ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Modülleri devreye sürükle veya seçip hücreye dokun.',
            style: TextStyle(color: RelayColors.muted, fontSize: 9.5),
          ),
          const SizedBox(height: 10),
          ModulePalette(
            compact: false,
            fixedColumns: 2,
            modules: modules,
            selectedKind: state.selectedKind,
            onSelected: onPaletteSelected,
            onBoardModuleReturned: onBoardModuleReturned,
            remainingByKind: {
              for (final module in modules)
                module.kind: state.remainingFor(module.kind),
            },
          ),
          const Spacer(),
          TextButton.icon(
            key: const ValueKey('career-open-kit-builder'),
            onPressed: busy ? null : onEditKit,
            icon: const Icon(Icons.tune),
            label: const Text(
              'BAŞLANGIÇ SEKİZLİSİNİ DEĞİŞTİR',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: statusColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: statusColor, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('career-validate-board'),
            onPressed: busy ? null : onValidate,
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('DOĞRULA'),
          ),
        ],
      ),
    );

    final boardCard = Container(
      key: const ValueKey('career-player-board-editor'),
      width: _careerPanelWidth,
      height: _careerPanelHeight,
      padding: const EdgeInsets.all(12),
      decoration: RelayDecorations.panel(
        accent: RelayColors.cyan,
        soft: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: RelayColors.cyan),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SENİN DEVREN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Savaş öncesinde otomatik kaydedilir.',
                      style: TextStyle(
                        color: RelayColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${state.placements.length}/$maxBoardModules',
                style: const TextStyle(
                  color: RelayColors.amber,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Devreyi sıfırla',
                onPressed: busy ? null : onReset,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = constraints.maxHeight < _careerBoardMaxWidth
                    ? constraints.maxHeight
                    : _careerBoardMaxWidth;
                return Center(
                  child: SizedBox.square(
                    dimension: boardSize,
                    child: CircuitBoard(
                      placements: state.placements,
                      specs: specs,
                      poweredIds:
                          validation?.poweredIds ?? const <String>{},
                      validationVisible: validation != null,
                      selectedCell: state.selectedCell,
                      onCellTap: onCellTap,
                      onModuleDropped: onModuleDropped,
                      onRotateModule: onRotateModule,
                      visuals: visuals,
                      presentation3d: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _careerPlayerEditorWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              moduleCard,
              const SizedBox(width: _careerModuleBoardGap),
              boardCard,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            moduleCard,
            const SizedBox(height: 12),
            boardCard,
          ],
        );
      },
    );
  }
}

class _CareerRunCard extends StatelessWidget {
  const _CareerRunCard({
    required this.run,
    required this.playerEditor,
    required this.modules,
    required this.availableCredits,
    required this.busyAction,
    required this.onStart,
    required this.onBattle,
    required this.onChooseBooster,
    required this.onSkipBooster,
    required this.onAbandon,
  });

  final CareerRunSnapshot run;
  final Widget playerEditor;
  final List<ModuleSpec> modules;
  final int availableCredits;
  final String? busyAction;
  final VoidCallback onStart;
  final VoidCallback onBattle;
  final ValueChanged<String> onChooseBooster;
  final VoidCallback onSkipBooster;
  final VoidCallback onAbandon;

  bool get busy => busyAction != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('career-run-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: run.status == 'active'
            ? _active(context)
            : run.status == 'awaiting_booster'
                ? _boosterChoice()
                : run.status == 'failed'
                    ? _idle(context)
                    : run.isTerminal
                        ? _terminal()
                        : _idle(context),
      ),
    );
  }

  Widget _idle(BuildContext context) {
    const opponentPreview = _CareerBoardPreview(
      key: ValueKey('career-opponent-board-preview'),
      title: 'KOŞU RAKİBİ',
      subtitle: 'Koşuyu başlattığında ilk rakip burada görünür.',
      icon: Icons.radar,
      accent: RelayColors.amber,
      board: null,
      specs: <ModuleKind, ModuleSpec>{},
      poweredIds: <String>{},
      emptyMessage: 'Önce devreni düzenle ve koşuyu başlat.',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RunTitle(
          icon: Icons.account_tree_outlined,
          color: RelayColors.amber,
          title: 'KARİYER HAZIRLIĞI',
          subtitle:
              'Devreni bu ekranda düzenle. Koşuyu başlattığında rakip devre '
              'yanında açılır; ayrı bir hazırlık sayfasına geçmezsin.',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1360) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: _careerPlayerOpponentGap,
                runSpacing: 14,
                children: [
                  SizedBox(width: _careerPlayerEditorWidth, child: playerEditor),
                  const SizedBox(width: _careerPanelWidth, child: opponentPreview),
                ],
              );
            }
            return Column(
              children: [
                playerEditor,
                const SizedBox(height: 12),
                opponentPreview,
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const ValueKey('career-run-start'),
          onPressed: busy ? null : onStart,
          icon: busyAction == 'start'
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(
            busyAction == 'start' ? 'KOŞU HAZIRLANIYOR' : 'KOŞUYU BAŞLAT',
          ),
        ),
      ],
    );
  }

  Widget _active(BuildContext context) {
    final opponent = run.opponent;
    if (opponent == null) return _idle(context);
    final specs = {for (final item in modules) item.kind: item};
    final opponentPowered =
        opponent.board.modules.map((item) => item.id).toSet();
    final opponentPreview = _CareerBoardPreview(
      key: const ValueKey('career-opponent-board-preview'),
      title: opponent.displayName,
      subtitle: opponent.description,
      icon: opponent.isBoss ? Icons.warning_amber : Icons.radar,
      accent: opponent.isBoss ? RelayColors.coral : RelayColors.amber,
      board: opponent.board,
      specs: specs,
      poweredIds: opponentPowered,
      emptyMessage: 'Rakip devre yüklenemedi.',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunTitle(
          icon: opponent.isBoss ? Icons.warning_amber : Icons.radar,
          color: opponent.isBoss ? RelayColors.coral : RelayColors.cyan,
          title: opponent.isBoss
              ? 'BÖLÜM SONU • ${opponent.title}'
              : 'SAVAŞ ${opponent.stageNumber}/${opponent.totalStages} • ${opponent.title}',
          subtitle: opponent.briefing,
        ),
        const SizedBox(height: 12),
        _RunProgress(run: run),
        if (run.selectedBoosters.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SelectedBoosters(items: run.selectedBoosters),
        ],
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1360) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: _careerPlayerOpponentGap,
                runSpacing: 14,
                children: [
                  SizedBox(width: _careerPlayerEditorWidth, child: playerEditor),
                  SizedBox(width: _careerPanelWidth, child: opponentPreview),
                ],
              );
            }
            return Column(
              children: [
                playerEditor,
                const SizedBox(height: 12),
                opponentPreview,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('career-battle-button'),
          onPressed: busy || !run.canBattle ? null : onBattle,
          icon: busyAction == 'battle'
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.flash_on),
          label: Text(
            opponent.isBoss
                ? 'BOSS SAVAŞINA İLERLE'
                : opponent.stageNumber == 1
                    ? 'İLK SAVAŞA BAŞLA'
                    : 'SONRAKİ SAVAŞA İLERLE',
          ),
        ),
        const SizedBox(height: 7),
        TextButton.icon(
          onPressed: busy ? null : onAbandon,
          icon: const Icon(Icons.close),
          label: const Text('KOŞUYU BIRAK'),
        ),
      ],
    );
  }

  Widget _boosterChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RunTitle(
          icon: Icons.bolt,
          color: RelayColors.amber,
          title: 'BOSS ÖNCESİ GÜÇLENDİRİCİ MAĞAZASI',
          subtitle: 'Yalnız bu koşunun boss savaşında çalışacak tek bir '
              'güçlendirici satın alabilir veya satın almadan ilerleyebilirsin.',
        ),
        const SizedBox(height: 12),
        _RunProgress(run: run),
        const SizedBox(height: 10),
        Text(
          'Mevcut bakiye: $availableCredits Devre Kredisi',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: RelayColors.amber,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (run.selectedBoosters.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SelectedBoosters(items: run.selectedBoosters),
        ],
        const SizedBox(height: 12),
        for (final booster in run.offeredBoosters)
          Container(
            key: ValueKey('career-offer-${booster.id}'),
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1538E8FF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0x5538E8FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: RelayColors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${booster.displayName} • K${booster.tier}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        booster.effectLabel,
                        style: const TextStyle(
                          color: RelayColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        booster.description,
                        style: const TextStyle(
                          color: RelayColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy || availableCredits < booster.creditCost
                      ? null
                      : () => onChooseBooster(booster.id),
                  child: busyAction == 'booster:${booster.id}'
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('${booster.creditCost} DK'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          key: const ValueKey('career-booster-skip'),
          onPressed: busy ? null : onSkipBooster,
          icon: busyAction == 'booster:none'
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: const Text('GÜÇLENDİRİCİ ALMADAN BOSS’A İLERLE'),
        ),
      ],
    );
  }

  Widget _terminal() {
    final completed = run.status == 'completed';
    final failed = run.status == 'failed';
    final reward = run.reward;
    final title = completed
        ? 'KARİYER KOŞUSU TAMAMLANDI'
        : failed
            ? 'KARİYER KOŞUSU SONA ERDİ'
            : 'KARİYER KOŞUSU BIRAKILDI';
    final subtitle = completed
        ? 'Bölüm sonu devresi yenildi. Bütün geçici etkiler sıfırlandı.'
        : 'Geçici etkiler sıfırlandı. Yeni koşu temiz bir devreyle başlar.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunTitle(
          icon: completed ? Icons.emoji_events : Icons.route_outlined,
          color: completed ? RelayColors.mint : RelayColors.coral,
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 14),
        Text(
          '${run.wins}/${run.totalStages} ZAFER',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: RelayColors.cyan,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (reward != null) ...[
          const SizedBox(height: 8),
          Text(
            '+${reward.xp} XP • +${reward.credits} Devre Kredisi',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RelayColors.amber,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const ValueKey('career-new-run'),
          onPressed: busy ? null : onStart,
          icon: busyAction == 'start'
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('YENİ KOŞU BAŞLAT'),
        ),
      ],
    );
  }
}

class _CareerBoardPreview extends StatelessWidget {
  const _CareerBoardPreview({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.board,
    required this.specs,
    required this.poweredIds,
    required this.emptyMessage,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final BoardDraft? board;
  final Map<ModuleKind, ModuleSpec> specs;
  final Set<String> poweredIds;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final draft = board;
    final placements = draft == null
        ? const <int, ModulePlacement>{}
        : {for (final item in draft.modules) item.cellIndex: item};
    return Container(
      width: _careerPanelWidth,
      height: _careerPanelHeight,
      padding: const EdgeInsets.all(12),
      decoration: RelayDecorations.panel(
        accent: accent,
        soft: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RelayColors.muted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = constraints.maxHeight < _careerBoardMaxWidth
                    ? constraints.maxHeight
                    : _careerBoardMaxWidth;
                if (draft == null) {
                  return Center(
                    child: SizedBox.square(
                      dimension: boardSize,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: RelayColors.surface.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: RelayColors.muted.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.memory_outlined,
                                color: accent,
                                size: 38,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                emptyMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: RelayColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Center(
                  child: SizedBox.square(
                    dimension: boardSize,
                    child: IgnorePointer(
                      child: CircuitBoard(
                        placements: placements,
                        specs: specs,
                        poweredIds: poweredIds,
                        validationVisible: false,
                        selectedCell: null,
                        onCellTap: (_) {},
                        onModuleDropped: (_, _) {},
                        onRotateModule: (_) {},
                      ),
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

class _RunTitle extends StatelessWidget {
  const _RunTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: RelayColors.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunProgress extends StatelessWidget {
  const _RunProgress({required this.run});

  final CareerRunSnapshot run;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'KOŞU İLERLEMESİ • ${run.wins}/${run.totalStages} ZAFER',
                style: const TextStyle(
                  color: RelayColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: run.wins / run.totalStages,
          minHeight: 7,
          borderRadius: BorderRadius.circular(20),
        ),
      ],
    );
  }
}

class _SelectedBoosters extends StatelessWidget {
  const _SelectedBoosters({required this.items});

  final List<CareerBoosterChoice> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final booster in items)
          Chip(
            avatar: const Icon(Icons.bolt, size: 16),
            label: Text('${booster.displayName} K${booster.tier}'),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.profile});

  final PlayerProgression profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('career-progress-card'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: RelayColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RelayColors.cyan.withValues(alpha: 0.32),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  Icons.route_outlined,
                  color: RelayColors.cyan,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 11),
            SizedBox(
              width: 82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KARİYER',
                    style: TextStyle(
                      color: RelayColors.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'SV. ${profile.level}',
                    style: const TextStyle(
                      color: RelayColors.cyan,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      key: const ValueKey('career-level-progress'),
                      value: profile.levelProgress,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${profile.xpIntoLevel}/${profile.xpForNextLevel} XP • '
                    'Toplam ${profile.totalXp} XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RelayColors.muted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: RelayColors.cyan),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _BoosterRow extends StatelessWidget {
  const _BoosterRow({required this.booster});

  final BoosterMastery booster;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('booster-${booster.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1538E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x5538E8FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: RelayColors.cyan),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booster.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  booster.effectLabel,
                  style: const TextStyle(
                    color: RelayColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  booster.description,
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'K${booster.tier}',
                style: const TextStyle(
                  color: RelayColors.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (booster.nextTierLevel != null)
                Text(
                  'K${booster.tier + 1}: SV ${booster.nextTierLevel}',
                  style: const TextStyle(
                    color: RelayColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const Text(
                  'MAKS.',
                  style: TextStyle(
                    color: RelayColors.mint,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CareerError extends StatelessWidget {
  const _CareerError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: RelayColors.coral, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('YENİDEN DENE'),
            ),
          ],
        ),
      ),
    );
  }
}
