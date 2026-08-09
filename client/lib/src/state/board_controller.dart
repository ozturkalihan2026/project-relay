import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/relay_models.dart';

final onlineBoardControllerProvider =
    NotifierProvider<BoardController, BoardEditorState>(BoardController.new);
final trainingBoardControllerProvider =
    NotifierProvider<BoardController, BoardEditorState>(BoardController.new);
final careerBoardControllerProvider =
    NotifierProvider<BoardController, BoardEditorState>(BoardController.new);

final boardControllerProvider = onlineBoardControllerProvider;

const maxBoardModules = 6;

const defaultEditorKitLimits = <ModuleKind, int>{
  ModuleKind.generator: 1,
  ModuleKind.battery: 3,
  ModuleKind.laser: 3,
  ModuleKind.pulseCannon: 3,
  ModuleKind.shield: 3,
  ModuleKind.cooler: 3,
  ModuleKind.amplifier: 3,
  ModuleKind.repair: 3,
};

class BoardEditorState {
  const BoardEditorState({
    required this.placements,
    this.selectedKind,
    this.selectedCell,
    this.validation,
    this.kitName = 'Serbest Kit',
    this.kitLimits = defaultEditorKitLimits,
  });

  factory BoardEditorState.initial() {
    return const BoardEditorState(
      placements: {
        1: ModulePlacement(
          id: 'P-GEN',
          kind: ModuleKind.generator,
          row: 0,
          column: 1,
          orientation: RelayDirection.south,
        ),
        2: ModulePlacement(
          id: 'P-LASER',
          kind: ModuleKind.laser,
          row: 0,
          column: 2,
        ),
      },
      selectedCell: 2,
    );
  }

  final Map<int, ModulePlacement> placements;
  final ModuleKind? selectedKind;
  final int? selectedCell;
  final BoardValidation? validation;
  final String kitName;
  final Map<ModuleKind, int> kitLimits;

  int placedCount(ModuleKind kind) =>
      placements.values.where((item) => item.kind == kind).length;

  int remainingFor(ModuleKind kind) {
    final remaining = (kitLimits[kind] ?? 0) - placedCount(kind);
    return remaining < 0 ? 0 : remaining;
  }

  ModulePlacement? get selectedPlacement {
    final cell = selectedCell;
    return cell == null ? null : placements[cell];
  }

  ModulePlacement? placementById(String id) {
    for (final placement in placements.values) {
      if (placement.id == id) {
        return placement;
      }
    }
    return null;
  }

  BoardDraft get board {
    final modules = placements.values.toList()
      ..sort((left, right) => left.cellIndex.compareTo(right.cellIndex));
    return BoardDraft(name: 'Mavi Devre', modules: modules);
  }

  BoardEditorState copyWith({
    Map<int, ModulePlacement>? placements,
    ModuleKind? selectedKind,
    bool clearSelectedKind = false,
    int? selectedCell,
    bool clearSelectedCell = false,
    BoardValidation? validation,
    bool clearValidation = false,
    String? kitName,
    Map<ModuleKind, int>? kitLimits,
  }) {
    return BoardEditorState(
      placements: placements ?? this.placements,
      selectedKind:
          clearSelectedKind ? null : selectedKind ?? this.selectedKind,
      selectedCell:
          clearSelectedCell ? null : selectedCell ?? this.selectedCell,
      validation: clearValidation ? null : validation ?? this.validation,
      kitName: kitName ?? this.kitName,
      kitLimits: kitLimits ?? this.kitLimits,
    );
  }
}

class BoardController extends Notifier<BoardEditorState> {
  @override
  BoardEditorState build() => BoardEditorState.initial();

  void loadSavedBoard(SavedBoard saved) {
    final rawPlacements = <int, ModulePlacement>{
      for (final module in saved.board.modules) module.cellIndex: module,
    };
    final placements = _normalizeAutomaticOrientations(rawPlacements);
    final orientationChanged = rawPlacements.entries.any(
      (entry) => placements[entry.key]?.orientation != entry.value.orientation,
    );
    int? selectedCell;
    for (final module in placements.values) {
      if (module.kind != ModuleKind.generator) {
        selectedCell = module.cellIndex;
        break;
      }
    }
    state = BoardEditorState(
      placements: placements,
      selectedCell: selectedCell,
      kitName: state.kitName,
      kitLimits: state.kitLimits,
      validation: orientationChanged
          ? null
          : BoardValidation(
              valid: true,
              poweredIds: saved.poweredIds,
              unpoweredIds: saved.unpoweredIds,
            ),
    );
  }

  void applyKit(ControlledKit kit) {
    final limits = <ModuleKind, int>{};
    for (final kind in kit.moduleKinds) {
      limits[kind] = (limits[kind] ?? 0) + 1;
    }
    state = state.copyWith(
      kitName: kit.name,
      kitLimits: limits,
      clearSelectedKind: true,
      clearValidation: true,
    );
  }

  void selectPalette(ModuleKind kind) {
    state = state.copyWith(
      selectedKind: kind,
      clearSelectedCell: true,
    );
  }

  void tapCell(int cellIndex) {
    final existing = state.placements[cellIndex];
    if (existing != null) {
      state = state.copyWith(
        selectedCell: cellIndex,
        clearSelectedKind: true,
      );
      return;
    }

    final kind = state.selectedKind;
    if (kind == null) {
      state = state.copyWith(clearSelectedCell: true);
      return;
    }
    placeModule(cellIndex, kind);
  }

  void placeModule(int cellIndex, ModuleKind kind) {
    _checkPlaceableCell(cellIndex);
    if (state.placements.containsKey(cellIndex)) {
      throw StateError('Seçtiğiniz devre hücresi dolu.');
    }
    _ensureGeneratorAllowed(kind, replacingCell: cellIndex);
    _writePaletteModule(cellIndex, kind);
  }

  void dropModule(int targetCell, ModuleDragData data) {
    _checkPlaceableCell(targetCell);
    final sourceCell = data.sourceCell;
    if (data.isFromBoard && sourceCell != null) {
      moveModule(sourceCell, targetCell);
      return;
    }
    replaceWithPaletteModule(targetCell, data.kind);
  }

  void replaceWithPaletteModule(int cellIndex, ModuleKind kind) {
    _checkPlaceableCell(cellIndex);
    _ensureGeneratorAllowed(kind, replacingCell: cellIndex);
    _writePaletteModule(cellIndex, kind);
  }

  void moveModule(int sourceCell, int targetCell) {
    _checkPlaceableCell(sourceCell);
    _checkPlaceableCell(targetCell);
    final source = state.placements[sourceCell];
    if (source == null) {
      throw StateError('Taşınacak modül devre kartında bulunamadı.');
    }
    if (sourceCell == targetCell) {
      state = state.copyWith(
        selectedCell: targetCell,
        clearSelectedKind: true,
      );
      return;
    }

    final target = state.placements[targetCell];
    if (source.kind == ModuleKind.generator && !isCoreGate(targetCell)) {
      throw StateError(
        'Jeneratör yalnızca çekirdeğin dört kapı hücresine taşınabilir.',
      );
    }
    if (target?.kind == ModuleKind.generator && !isCoreGate(sourceCell)) {
      throw StateError(
        'Jeneratör yalnızca çekirdeğin dört kapı hücresine taşınabilir.',
      );
    }
    final sourceRow = sourceCell ~/ 4;
    final sourceColumn = sourceCell % 4;
    final targetRow = targetCell ~/ 4;
    final targetColumn = targetCell % 4;
    final placements = Map<int, ModulePlacement>.from(state.placements)
      ..remove(sourceCell)
      ..remove(targetCell)
      ..[targetCell] = source.copyWith(
        row: targetRow,
        column: targetColumn,
        orientation: source.kind == ModuleKind.generator
            ? coreGateDirections[targetCell] ?? source.orientation
            : source.orientation,
      );
    if (target != null) {
      placements[sourceCell] = target.copyWith(
        row: sourceRow,
        column: sourceColumn,
        orientation: target.kind == ModuleKind.generator
            ? coreGateDirections[sourceCell] ?? target.orientation
            : target.orientation,
      );
    }
    final normalizedPlacements = _normalizeAutomaticOrientations(placements);
    state = state.copyWith(
      placements: normalizedPlacements,
      selectedCell: targetCell,
      clearSelectedKind: true,
      clearValidation: true,
    );
  }

  void removeModuleAt(int cellIndex) {
    _checkPlaceableCell(cellIndex);
    if (!state.placements.containsKey(cellIndex)) {
      return;
    }
    final placements = Map<int, ModulePlacement>.from(state.placements)
      ..remove(cellIndex);
    state = state.copyWith(
      placements: _normalizeAutomaticOrientations(placements),
      clearSelectedCell: true,
      clearSelectedKind: true,
      clearValidation: true,
    );
  }

  void _writePaletteModule(int cellIndex, ModuleKind kind) {
    final existing = state.placements[cellIndex];
    final usedWithoutTarget = state.placements.values
        .where((placement) => placement.cellIndex != cellIndex)
        .where((placement) => placement.kind == kind)
        .length;
    final allowed = state.kitLimits[kind] ?? 0;
    if (usedWithoutTarget >= allowed && existing?.kind != kind) {
      throw StateError(
        '${kind.displayName} için aktif sekizli kitte boş yuva kalmadı.',
      );
    }
    if (!state.placements.containsKey(cellIndex) &&
        state.placements.length >= maxBoardModules) {
      throw StateError(
        'Bir savaş kartında en fazla $maxBoardModules modül kullanılabilir.',
      );
    }
    final row = cellIndex ~/ 4;
    final column = cellIndex % 4;
    final placement = ModulePlacement(
      id: _nextModuleId(kind, cellIndex),
      kind: kind,
      row: row,
      column: column,
      orientation: kind == ModuleKind.generator
          ? coreGateDirections[cellIndex]!
          : RelayDirection.east,
    );
    final placements = Map<int, ModulePlacement>.from(state.placements)
      ..[cellIndex] = placement;
    state = state.copyWith(
      placements: _normalizeAutomaticOrientations(placements),
      selectedCell: cellIndex,
      clearSelectedKind: true,
      clearValidation: true,
    );
  }

  RelayDirection _autoOrientationFor(
    ModuleKind kind,
    int cellIndex,
    Map<int, ModulePlacement> placements, {
    RelayDirection fallback = RelayDirection.east,
  }) {
    if (kind == ModuleKind.generator) {
      return coreGateDirections[cellIndex] ?? fallback;
    }
    if (!_usesAutomaticConnectionOrientation(kind)) {
      return fallback;
    }

    // Only the four designated gate cells connect directly to the passive core.
    // A normal ring cell merely touching one of the reserved 2x2 core cells must
    // never rotate toward that core cell.
    final coreDirection = coreGateDirections[cellIndex];
    if (coreDirection != null) {
      return coreDirection.opposite;
    }

    final row = cellIndex ~/ 4;
    final column = cellIndex % 4;
    const candidates = <RelayDirection>[
      RelayDirection.west,
      RelayDirection.north,
      RelayDirection.east,
      RelayDirection.south,
    ];

    RelayDirection? bestDirection;
    var bestScore = -1;
    for (var index = 0; index < candidates.length; index++) {
      final direction = candidates[index];
      final neighborCell = _neighborCell(row, column, direction);
      if (neighborCell == null || isCoreCell(neighborCell)) {
        continue;
      }
      final neighbor = placements[neighborCell];
      if (neighbor == null ||
          !_neighborCanReceiveConnection(neighbor, direction.opposite)) {
        continue;
      }

      final score = _connectionPriority(neighbor.kind) * 10 - index;
      if (score > bestScore) {
        bestScore = score;
        bestDirection = direction;
      }
    }

    // Single-port modules expose their local WEST/back port. To make that
    // world port face `bestDirection`, their orientation is the opposite.
    return bestDirection?.opposite ?? fallback;
  }

  Map<int, ModulePlacement> _normalizeAutomaticOrientations(
    Map<int, ModulePlacement> placements,
  ) {
    final source = Map<int, ModulePlacement>.from(placements);
    final normalized = Map<int, ModulePlacement>.from(placements);
    for (final entry in source.entries) {
      final module = entry.value;
      if (module.kind == ModuleKind.generator) {
        final fixed = coreGateDirections[entry.key];
        if (fixed != null && module.orientation != fixed) {
          normalized[entry.key] = module.copyWith(orientation: fixed);
        }
        continue;
      }
      if (!_usesAutomaticConnectionOrientation(module.kind)) {
        continue;
      }
      final orientation = _autoOrientationFor(
        module.kind,
        entry.key,
        source,
        fallback: module.orientation,
      );
      if (orientation != module.orientation) {
        normalized[entry.key] = module.copyWith(orientation: orientation);
      }
    }
    return normalized;
  }

  bool _usesAutomaticConnectionOrientation(ModuleKind kind) => switch (kind) {
        ModuleKind.laser ||
        ModuleKind.pulseCannon ||
        ModuleKind.shield ||
        ModuleKind.cooler ||
        ModuleKind.repair => true,
        _ => false,
      };

  int? _neighborCell(
    int row,
    int column,
    RelayDirection direction,
  ) {
    final neighborRow = row + switch (direction) {
      RelayDirection.north => -1,
      RelayDirection.south => 1,
      _ => 0,
    };
    final neighborColumn = column + switch (direction) {
      RelayDirection.west => -1,
      RelayDirection.east => 1,
      _ => 0,
    };
    if (neighborRow < 0 ||
        neighborRow >= relayBoardSize ||
        neighborColumn < 0 ||
        neighborColumn >= relayBoardSize) {
      return null;
    }
    return neighborRow * relayBoardSize + neighborColumn;
  }

  bool _neighborCanReceiveConnection(
    ModulePlacement neighbor,
    RelayDirection directionTowardModule,
  ) {
    return switch (neighbor.kind) {
      ModuleKind.battery || ModuleKind.amplifier => true,
      ModuleKind.generator =>
        directionTowardModule != neighbor.orientation.opposite,
      _ => false,
    };
  }

  int _connectionPriority(ModuleKind kind) => switch (kind) {
        ModuleKind.generator => 3,
        ModuleKind.battery => 2,
        ModuleKind.amplifier => 1,
        _ => 0,
      };

  String _nextModuleId(ModuleKind kind, int cellIndex) {
    final base =
        'P-${kind.wireValue}-${cellIndex.toString().padLeft(2, '0')}';
    final usedIds = state.placements.entries
        .where((entry) => entry.key != cellIndex)
        .map((entry) => entry.value.id)
        .toSet();
    if (!usedIds.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (usedIds.contains('$base-$suffix')) {
      suffix += 1;
    }
    return '$base-$suffix';
  }

  void _ensureGeneratorAllowed(
    ModuleKind kind, {
    int? replacingCell,
  }) {
    if (kind != ModuleKind.generator) {
      return;
    }
    if (replacingCell == null || !isCoreGate(replacingCell)) {
      throw StateError(
        'Jeneratör yalnızca çekirdeğin dört kapı hücresine yerleştirilebilir.',
      );
    }
    final hasOtherGenerator = state.placements.entries.any(
      (entry) =>
          entry.key != replacingCell &&
          entry.value.kind == ModuleKind.generator,
    );
    if (hasOtherGenerator) {
      throw StateError('Kartta yalnızca bir jeneratör bulunabilir.');
    }
  }

  void _checkCellIndex(int cellIndex) {
    if (cellIndex < 0 || cellIndex >= 16) {
      throw RangeError.range(cellIndex, 0, 15, 'cellIndex');
    }
  }

  void _checkPlaceableCell(int cellIndex) {
    _checkCellIndex(cellIndex);
    if (isCoreCell(cellIndex)) {
      throw StateError(
        'Ortadaki 2×2 alan pasif çekirdeğe ayrılmıştır.',
      );
    }
  }

  void rotateSelected() {
    final cellIndex = state.selectedCell;
    if (cellIndex == null) {
      return;
    }
    rotateAt(cellIndex);
  }

  void rotateAt(int cellIndex) {
    _checkPlaceableCell(cellIndex);
    final selected = state.placements[cellIndex];
    if (selected == null) {
      return;
    }
    if (selected.kind != ModuleKind.amplifier) {
      return;
    }
    final placements = Map<int, ModulePlacement>.from(state.placements)
      ..[cellIndex] = selected.copyWith(
        orientation: selected.orientation.next,
      );
    state = state.copyWith(
      placements: placements,
      selectedCell: cellIndex,
      clearSelectedKind: true,
      clearValidation: true,
    );
  }

  void deleteSelected() {
    final selected = state.selectedPlacement;
    if (selected == null) {
      return;
    }
    final placements = Map<int, ModulePlacement>.from(state.placements)
      ..remove(selected.cellIndex);
    state = state.copyWith(
      placements: placements,
      clearSelectedCell: true,
      clearValidation: true,
    );
  }

  void applyValidation(BoardValidation validation) {
    state = state.copyWith(validation: validation);
  }

  void reset() {
    final fresh = BoardEditorState.initial();
    state = fresh.copyWith(
      kitName: state.kitName,
      kitLimits: state.kitLimits,
    );
  }
}
