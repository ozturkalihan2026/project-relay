import '../models/relay_models.dart';

class ReplayEventFormatter {
  ReplayEventFormatter(MatchResponse match)
    : _modules = {
        for (final module in match.playerBoard.modules)
          module.id: _KnownModule(module, 'Sen'),
        for (final module in match.opponentBoard.modules)
          module.id: _KnownModule(module, match.opponent.displayName),
      },
      _sideLabel = _labelFrom(match.opponent.displayName);

  ReplayEventFormatter.fromBoards({
    required BoardDraft playerBoard,
    required BoardDraft opponentBoard,
    required String opponentName,
  }) : _modules = {
         for (final module in playerBoard.modules)
           module.id: _KnownModule(module, 'Sen'),
         for (final module in opponentBoard.modules)
           module.id: _KnownModule(module, opponentName),
       },
       _sideLabel = _labelFrom(opponentName);

  final Map<String, _KnownModule> _modules;
  final String Function(String side) _sideLabel;

  static String Function(String side) _labelFrom(String opponentName) =>
      (side) => switch (side) {
        'left' => 'SEN',
        'right' => opponentName.toUpperCase(),
        _ => 'SİSTEM',
      };

  String moduleLabel(String? id) {
    if (id == null) {
      return 'Modül';
    }
    final known = _modules[id];
    if (known != null) {
      final module = known.module;
      return '${known.owner} ${module.kind.displayName} '
          '(${module.row + 1},${module.column + 1})';
    }
    return switch (id) {
      'board' => 'kart',
      'enemy_board' => 'rakip kart',
      'powered_circuit' => 'enerjili devre',
      'enemy_core' => 'rakip çekirdek',
      _ => 'Modül',
    };
  }

  String eventLabel(BattleEvent event) {
    final actor = moduleLabel(event.actorId);
    final target = moduleLabel(event.targetId);
    final amount = event.amount.toStringAsFixed(1);
    return switch (event.type) {
      'overload' =>
        'Aşırı yük kademesi ${event.amount.toStringAsFixed(0)} etkinleşti.',
      'attack' => '$actor, $target hedefine $amount hasar verdi.',
      'core_damage' => '$actor rakip çekirdeğe $amount hasar verdi.',
      'shield' => '$actor ortak havuza $amount kalkan ekledi.',
      'shield_absorb' =>
        '$actor saldırısının $amount hasarı kalkan tarafından emildi.',
      'cool' => '$actor devre ısısını $amount düşürdü.',
      'repair' => '$actor, $target modülünü $amount onardı.',
      'overheat' => '$actor aşırı ısındı ve geçici olarak durdu.',
      'recovered' => '$actor soğudu ve yeniden çalışmaya başladı.',
      'destroyed' => '$target imha edildi.',
      'energy_starved' => '$actor çalışamadı; $amount enerji eksik.',
      _ => 'Bilinmeyen savaş olayı.',
    };
  }

  String sideLabel(String side) => _sideLabel(side);
}

class _KnownModule {
  const _KnownModule(this.module, this.owner);

  final ModulePlacement module;
  final String owner;
}
