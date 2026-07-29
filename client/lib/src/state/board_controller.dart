import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/relay_models.dart';

final boardControllerProvider =
    NotifierProvider<BoardController, BoardEditorState>(BoardController.new);

const maxBoardModules = 6;

class BoardEditorState {
  const BoardEditorState({
    required this.placements,
    this.selectedKind,
    this.selectedCell,
    this.validation,
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
  }) {
    return BoardEditorState(
      placements: placements ?? this.placements,
      selectedKind:
          clearSelectedKind ? null : selectedKind ?? this.selectedKind,
      selectedCell:
          clearSelectedCell ? null : selectedCell ?? this.selectedCell,
      validation: clearValidation ? null : validation ?? this.validation,
    );
  }
}

class BoardController extends Notifier<BoardEditorState> {
  @override
  BoardEditorState build() => BoardEditorState.initial();

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
            ? coreGateDirections[targetCell]
            : source.orientation,
      );
    if (target != null) {
      placements[sourceCell] = target.copyWith(
        row: sourceRow,
        column: sourceColumn,
        orientation: target.kind == ModuleKind.generator
            ? coreGateDirections[sourceCell]
            : target.orientation,
      );
    }
    state = state.copyWith(
      placements: placements,
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
      placements: placements,
      clearSelectedCell: true,
      clearSelectedKind: true,
      clearValidation: true,
    );
  }

  void _writePaletteModule(int cellIndex, ModuleKind kind) {
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
      placements: placements,
      selectedCell: cellIndex,
      clearSelectedKind: true,
      clearValidation: true,
    );
  }

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
    if (selected.kind == ModuleKind.generator) {
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
    state = BoardEditorState.initial();
  }
}
