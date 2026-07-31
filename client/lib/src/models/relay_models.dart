enum RelayDirection {
  north,
  east,
  south,
  west;

  String get wireValue => name;

  String get shortLabel => switch (this) {
        RelayDirection.north => 'K',
        RelayDirection.east => 'D',
        RelayDirection.south => 'G',
        RelayDirection.west => 'B',
      };

  String get displayName => switch (this) {
        RelayDirection.north => 'Kuzey',
        RelayDirection.east => 'Doğu',
        RelayDirection.south => 'Güney',
        RelayDirection.west => 'Batı',
      };

  int get clockwiseTurnsFromEast => switch (this) {
        RelayDirection.east => 0,
        RelayDirection.south => 1,
        RelayDirection.west => 2,
        RelayDirection.north => 3,
      };

  RelayDirection get next => switch (this) {
        RelayDirection.north => RelayDirection.east,
        RelayDirection.east => RelayDirection.south,
        RelayDirection.south => RelayDirection.west,
        RelayDirection.west => RelayDirection.north,
      };

  RelayDirection get opposite => switch (this) {
        RelayDirection.north => RelayDirection.south,
        RelayDirection.east => RelayDirection.west,
        RelayDirection.south => RelayDirection.north,
        RelayDirection.west => RelayDirection.east,
      };

  static RelayDirection parse(String value) {
    return RelayDirection.values.firstWhere(
      (direction) => direction.wireValue == value,
      orElse: () => throw FormatException('Bilinmeyen yön: $value'),
    );
  }
}

const relayBoardSize = 4;
const reservedCoreCells = <int>{5, 6, 9, 10};
const coreGateDirections = <int, RelayDirection>{
  1: RelayDirection.south,
  7: RelayDirection.west,
  14: RelayDirection.north,
  8: RelayDirection.east,
};

bool isCoreCell(int cellIndex) => reservedCoreCells.contains(cellIndex);

bool isCoreGate(int cellIndex) => coreGateDirections.containsKey(cellIndex);

enum ModuleKind {
  generator,
  battery,
  laser,
  pulseCannon,
  shield,
  cooler,
  amplifier,
  repair;

  String get wireValue => switch (this) {
        ModuleKind.pulseCannon => 'pulse_cannon',
        _ => name,
      };

  String get displayName => switch (this) {
        ModuleKind.generator => 'Jeneratör',
        ModuleKind.battery => 'Batarya',
        ModuleKind.laser => 'Lazer',
        ModuleKind.pulseCannon => 'Darbe Topu',
        ModuleKind.shield => 'Kalkan',
        ModuleKind.cooler => 'Soğutucu',
        ModuleKind.amplifier => 'Güçlendirici',
        ModuleKind.repair => 'Onarım Ünitesi',
      };

  static ModuleKind parse(String value) {
    return ModuleKind.values.firstWhere(
      (kind) => kind.wireValue == value,
      orElse: () => throw FormatException('Bilinmeyen modül: $value'),
    );
  }
}

class ModuleSpec {
  const ModuleSpec({
    required this.kind,
    required this.displayName,
    required this.description,
    required this.maxHp,
    required this.ports,
    required this.energyOutput,
    required this.batteryCapacity,
    required this.energyCost,
    required this.cooldownTicks,
    required this.heatPerAction,
    required this.damage,
    required this.shield,
    required this.cooling,
    required this.repair,
    required this.threat,
  });

  factory ModuleSpec.fromJson(Map<String, dynamic> json) {
    return ModuleSpec(
      kind: ModuleKind.parse(json['kind'] as String),
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      maxHp: (json['max_hp'] as num).toDouble(),
      ports: (json['ports'] as List<dynamic>)
          .map((value) => RelayDirection.parse(value as String))
          .toSet(),
      energyOutput: (json['energy_output'] as num).toDouble(),
      batteryCapacity:
          (json['battery_capacity'] as num? ?? 0).toDouble(),
      energyCost: (json['energy_cost'] as num).toDouble(),
      cooldownTicks: json['cooldown_ticks'] as int,
      heatPerAction: (json['heat_per_action'] as num).toDouble(),
      damage: (json['damage'] as num).toDouble(),
      shield: (json['shield'] as num).toDouble(),
      cooling: (json['cooling'] as num).toDouble(),
      repair: (json['repair'] as num).toDouble(),
      threat: json['threat'] as int? ?? 0,
    );
  }

  final ModuleKind kind;
  final String displayName;
  final String description;
  final double maxHp;
  final Set<RelayDirection> ports;
  final double energyOutput;
  final double batteryCapacity;
  final double energyCost;
  final int cooldownTicks;
  final double heatPerAction;
  final double damage;
  final double shield;
  final double cooling;
  final double repair;
  final int threat;

  Set<RelayDirection> worldPorts(RelayDirection orientation) {
    if (ports.length == RelayDirection.values.length) {
      return RelayDirection.values.toSet();
    }
    return ports.map((port) {
      final index = RelayDirection.values.indexOf(port);
      return RelayDirection.values[
          (index + orientation.clockwiseTurnsFromEast) % 4];
    }).toSet();
  }
}

class BotDefinition {
  const BotDefinition({
    required this.id,
    required this.displayName,
    required this.difficulty,
    required this.description,
    required this.availableModuleCounts,
  });

  factory BotDefinition.fromJson(Map<String, dynamic> json) {
    return BotDefinition(
      id: json['bot_id'] as String,
      displayName: json['display_name'] as String,
      difficulty: json['difficulty'] as String,
      description: json['description'] as String,
      availableModuleCounts:
          (json['available_module_counts'] as List<dynamic>)
              .map((value) => value as int)
              .toList(growable: false),
    );
  }

  final String id;
  final String displayName;
  final String difficulty;
  final String description;
  final List<int> availableModuleCounts;
}

class ModulePlacement {
  const ModulePlacement({
    required this.id,
    required this.kind,
    required this.row,
    required this.column,
    this.orientation = RelayDirection.east,
    this.level = 1,
  });

  factory ModulePlacement.fromJson(Map<String, dynamic> json) {
    return ModulePlacement(
      id: json['module_id'] as String,
      kind: ModuleKind.parse(json['kind'] as String),
      row: json['row'] as int,
      column: json['column'] as int,
      orientation: RelayDirection.parse(
        json['orientation'] as String? ?? 'east',
      ),
      level: json['level'] as int? ?? 1,
    );
  }

  final String id;
  final ModuleKind kind;
  final int row;
  final int column;
  final RelayDirection orientation;
  final int level;

  int get cellIndex => row * relayBoardSize + column;

  ModulePlacement copyWith({
    int? row,
    int? column,
    RelayDirection? orientation,
    int? level,
  }) {
    return ModulePlacement(
      id: id,
      kind: kind,
      row: row ?? this.row,
      column: column ?? this.column,
      orientation: orientation ?? this.orientation,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_id': id,
      'kind': kind.wireValue,
      'row': row,
      'column': column,
      'orientation': orientation.wireValue,
      'level': level,
    };
  }
}

Set<RelayDirection> usableBoardPorts(
  ModulePlacement module,
  Iterable<RelayDirection> worldPorts,
) {
  return worldPorts.where((direction) {
    if (coreGateDirections[module.cellIndex] == direction) {
      return true;
    }
    final (rowDelta, columnDelta) = switch (direction) {
      RelayDirection.north => (-1, 0),
      RelayDirection.east => (0, 1),
      RelayDirection.south => (1, 0),
      RelayDirection.west => (0, -1),
    };
    final neighborRow = module.row + rowDelta;
    final neighborColumn = module.column + columnDelta;
    if (neighborRow < 0 ||
        neighborRow >= relayBoardSize ||
        neighborColumn < 0 ||
        neighborColumn >= relayBoardSize) {
      return false;
    }
    final neighborIndex = neighborRow * relayBoardSize + neighborColumn;
    return !isCoreCell(neighborIndex);
  }).toSet();
}

enum ModuleDragSource { palette, board }

class ModuleDragData {
  const ModuleDragData.palette(this.kind)
      : source = ModuleDragSource.palette,
        sourceCell = null;

  const ModuleDragData.board({
    required this.kind,
    required int cellIndex,
  })  : source = ModuleDragSource.board,
        sourceCell = cellIndex;

  final ModuleKind kind;
  final ModuleDragSource source;
  final int? sourceCell;

  bool get isFromPalette => source == ModuleDragSource.palette;
  bool get isFromBoard => source == ModuleDragSource.board;
}

class BoardDraft {
  const BoardDraft({required this.name, required this.modules});

  factory BoardDraft.fromJson(Map<String, dynamic> json) {
    return BoardDraft(
      name: json['name'] as String,
      modules: (json['modules'] as List<dynamic>)
          .map(
            (module) => ModulePlacement.fromJson(
              module as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String name;
  final List<ModulePlacement> modules;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'modules': modules.map((module) => module.toJson()).toList(),
    };
  }
}

class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['player_id'] as String,
      displayName: json['display_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String displayName;
  final DateTime createdAt;
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresIn: json['access_expires_in'] as int,
      refreshExpiresIn: json['refresh_expires_in'] as int,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int accessExpiresIn;
  final int refreshExpiresIn;
}

class GuestSession {
  const GuestSession({
    required this.player,
    required this.tokens,
  });

  factory GuestSession.fromJson(Map<String, dynamic> json) {
    return GuestSession(
      player: PlayerProfile.fromJson(
        json['player'] as Map<String, dynamic>,
      ),
      tokens: AuthTokens.fromJson(
        json['tokens'] as Map<String, dynamic>,
      ),
    );
  }

  final PlayerProfile player;
  final AuthTokens tokens;
}

class SavedBoard {
  const SavedBoard({
    required this.id,
    required this.fingerprint,
    required this.updatedAt,
    required this.board,
    required this.poweredIds,
    required this.unpoweredIds,
  });

  factory SavedBoard.fromJson(Map<String, dynamic> json) {
    return SavedBoard(
      id: json['board_id'] as String,
      fingerprint: json['fingerprint'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      board: BoardDraft.fromJson(
        json['board'] as Map<String, dynamic>,
      ),
      poweredIds: Set<String>.from(
        json['powered_module_ids'] as List<dynamic>,
      ),
      unpoweredIds: Set<String>.from(
        json['unpowered_module_ids'] as List<dynamic>,
      ),
    );
  }

  final String id;
  final String fingerprint;
  final DateTime updatedAt;
  final BoardDraft board;
  final Set<String> poweredIds;
  final Set<String> unpoweredIds;
}

class BoardValidation {
  const BoardValidation({
    required this.valid,
    required this.poweredIds,
    required this.unpoweredIds,
  });

  factory BoardValidation.fromJson(Map<String, dynamic> json) {
    return BoardValidation(
      valid: json['valid'] as bool,
      poweredIds: Set<String>.from(
        json['powered_module_ids'] as List<dynamic>,
      ),
      unpoweredIds: Set<String>.from(
        json['unpowered_module_ids'] as List<dynamic>,
      ),
    );
  }

  final bool valid;
  final Set<String> poweredIds;
  final Set<String> unpoweredIds;
}

class BoardSummary {
  const BoardSummary({
    required this.name,
    required this.coreHp,
    required this.coreMaxHp,
    required this.shield,
    required this.energySpent,
    required this.totalDamage,
    required this.survivingModules,
    required this.modules,
  });

  factory BoardSummary.fromJson(Map<String, dynamic> json) {
    return BoardSummary(
      name: json['name'] as String,
      coreHp: (json['core_hp'] as num).toDouble(),
      coreMaxHp: (json['core_max_hp'] as num).toDouble(),
      shield: (json['shield'] as num? ?? 0).toDouble(),
      energySpent: (json['energy_spent'] as num? ?? 0).toDouble(),
      totalDamage: (json['total_damage'] as num).toDouble(),
      survivingModules: json['surviving_modules'] as int,
      modules: (json['modules'] as List<dynamic>? ?? const [])
          .map(
            (module) => ModuleBattleSummary.fromJson(
              module as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String name;
  final double coreHp;
  final double coreMaxHp;
  final double shield;
  final double energySpent;
  final double totalDamage;
  final int survivingModules;
  final List<ModuleBattleSummary> modules;
}

class ModuleBattleSummary {
  const ModuleBattleSummary({
    required this.id,
    required this.kind,
    required this.hp,
    required this.maxHp,
    required this.heat,
    required this.powered,
    required this.overheated,
  });

  factory ModuleBattleSummary.fromJson(Map<String, dynamic> json) {
    return ModuleBattleSummary(
      id: json['module_id'] as String,
      kind: ModuleKind.parse(json['kind'] as String),
      hp: (json['hp'] as num).toDouble(),
      maxHp: (json['max_hp'] as num).toDouble(),
      heat: (json['heat'] as num).toDouble(),
      powered: json['powered'] as bool,
      overheated: json['overheated'] as bool,
    );
  }

  final String id;
  final ModuleKind kind;
  final double hp;
  final double maxHp;
  final double heat;
  final bool powered;
  final bool overheated;
}

class DecisionMetric {
  const DecisionMetric({
    required this.key,
    required this.leftValue,
    required this.rightValue,
    required this.preferred,
  });

  factory DecisionMetric.fromJson(Map<String, dynamic> json) {
    return DecisionMetric(
      key: json['key'] as String,
      leftValue: (json['left_value'] as num).toDouble(),
      rightValue: (json['right_value'] as num).toDouble(),
      preferred: json['preferred'] as String,
    );
  }

  final String key;
  final double leftValue;
  final double rightValue;
  final String preferred;
}

class BattleDecision {
  const BattleDecision({
    required this.criterion,
    required this.metrics,
  });

  factory BattleDecision.fromJson(Map<String, dynamic> json) {
    return BattleDecision(
      criterion: json['criterion'] as String,
      metrics: (json['metrics'] as List<dynamic>)
          .map(
            (metric) => DecisionMetric.fromJson(
              metric as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String criterion;
  final List<DecisionMetric> metrics;
}

class MatchResult {
  const MatchResult({
    required this.winner,
    required this.reason,
    required this.ticks,
    required this.left,
    required this.right,
    required this.decision,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      winner: json['winner'] as String?,
      reason: json['reason'] as String,
      ticks: json['ticks'] as int,
      left: BoardSummary.fromJson(json['left'] as Map<String, dynamic>),
      right: BoardSummary.fromJson(json['right'] as Map<String, dynamic>),
      decision: BattleDecision.fromJson(
        json['decision'] as Map<String, dynamic>,
      ),
    );
  }

  final String? winner;
  final String reason;
  final int ticks;
  final BoardSummary left;
  final BoardSummary right;
  final BattleDecision decision;
}

class MatchOpponent {
  const MatchOpponent({
    required this.kind,
    required this.id,
    required this.displayName,
    required this.description,
    this.difficulty = 'player',
    this.availableModuleCounts = const <int>[],
  });

  factory MatchOpponent.fromJson(Map<String, dynamic> json) {
    return MatchOpponent(
      kind: json['kind'] as String? ?? 'bot',
      id: (
        json['opponent_id'] as String? ??
        json['bot_id'] as String? ??
        'unknown'
      ),
      displayName: json['display_name'] as String,
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'player',
      availableModuleCounts:
          (json['available_module_counts'] as List<dynamic>? ?? const [])
              .map((value) => value as int)
              .toList(growable: false),
    );
  }

  final String kind;
  final String id;
  final String displayName;
  final String description;
  final String difficulty;
  final List<int> availableModuleCounts;

  bool get isPlayer => kind == 'player';
}

class RatingChange {
  const RatingChange({
    required this.outcome,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.ratingDelta,
    required this.weekKey,
  });

  factory RatingChange.fromJson(Map<String, dynamic> json) {
    return RatingChange(
      outcome: json['outcome'] as String,
      ratingBefore: json['rating_before'] as int,
      ratingAfter: json['rating_after'] as int,
      ratingDelta: json['rating_delta'] as int,
      weekKey: json['week_key'] as String,
    );
  }

  final String outcome;
  final int ratingBefore;
  final int ratingAfter;
  final int ratingDelta;
  final String weekKey;
}

class MatchResponse {
  const MatchResponse({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.opponent,
    required this.playerBoard,
    required this.opponentBoard,
    required this.result,
    required this.replayChecksum,
    required this.replayEventCount,
    this.ratingChange,
  });

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    final replay = json['replay'] as Map<String, dynamic>;
    final ratingPayload = json['rating_change'];
    return MatchResponse(
      id: json['match_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      source: json['source'] as String? ?? 'bot',
      opponent: MatchOpponent.fromJson(
        json['opponent'] as Map<String, dynamic>,
      ),
      playerBoard: BoardDraft.fromJson(
        json['player_board'] as Map<String, dynamic>,
      ),
      opponentBoard: BoardDraft.fromJson(
        json['opponent_board'] as Map<String, dynamic>,
      ),
      result: MatchResult.fromJson(json['result'] as Map<String, dynamic>),
      replayChecksum: replay['checksum'] as String,
      replayEventCount: replay['event_count'] as int,
      ratingChange: ratingPayload is Map<String, dynamic>
          ? RatingChange.fromJson(ratingPayload)
          : null,
    );
  }

  final String id;
  final DateTime createdAt;
  final String source;
  final MatchOpponent opponent;
  final BoardDraft playerBoard;
  final BoardDraft opponentBoard;
  final MatchResult result;
  final String replayChecksum;
  final int replayEventCount;
  final RatingChange? ratingChange;
}


class BattleEvent {
  const BattleEvent({
    required this.tick,
    required this.side,
    required this.type,
    required this.actorId,
    required this.amount,
    this.targetId,
    this.detail,
  });

  factory BattleEvent.fromJson(Map<String, dynamic> json) {
    return BattleEvent(
      tick: json['tick'] as int,
      side: json['side'] as String,
      type: json['type'] as String,
      actorId: json['actor_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      targetId: json['target_id'] as String?,
      detail: json['detail'] as String?,
    );
  }

  final int tick;
  final String side;
  final String type;
  final String actorId;
  final double amount;
  final String? targetId;
  final String? detail;
}

class ModuleReplayState {
  const ModuleReplayState({
    required this.id,
    required this.hp,
    required this.maxHp,
    required this.heat,
    required this.cooldown,
    required this.powered,
    required this.overheated,
  });

  factory ModuleReplayState.fromJson(Map<String, dynamic> json) {
    return ModuleReplayState(
      id: json['module_id'] as String,
      hp: (json['hp'] as num).toDouble(),
      maxHp: (json['max_hp'] as num).toDouble(),
      heat: (json['heat'] as num).toDouble(),
      cooldown: json['cooldown'] as int,
      powered: json['powered'] as bool,
      overheated: json['overheated'] as bool,
    );
  }

  final String id;
  final double hp;
  final double maxHp;
  final double heat;
  final int cooldown;
  final bool powered;
  final bool overheated;
}

class BoardReplayState {
  const BoardReplayState({
    required this.coreHp,
    required this.shield,
    required this.energyReserve,
    required this.energyOutput,
    required this.energySpent,
    required this.modules,
  });

  factory BoardReplayState.fromJson(Map<String, dynamic> json) {
    return BoardReplayState(
      coreHp: (json['core_hp'] as num).toDouble(),
      shield: (json['shield'] as num).toDouble(),
      energyReserve: (json['energy_reserve'] as num).toDouble(),
      energyOutput: (json['energy_output'] as num).toDouble(),
      energySpent: (json['energy_spent'] as num).toDouble(),
      modules: (json['modules'] as List<dynamic>)
          .map(
            (module) => ModuleReplayState.fromJson(
              module as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final double coreHp;
  final double shield;
  final double energyReserve;
  final double energyOutput;
  final double energySpent;
  final List<ModuleReplayState> modules;

  Map<String, ModuleReplayState> get modulesById => {
        for (final module in modules) module.id: module,
      };
}

class ReplayStateFrame {
  const ReplayStateFrame({
    required this.tick,
    required this.left,
    required this.right,
  });

  factory ReplayStateFrame.fromJson(Map<String, dynamic> json) {
    return ReplayStateFrame(
      tick: json['tick'] as int,
      left: BoardReplayState.fromJson(
        json['left'] as Map<String, dynamic>,
      ),
      right: BoardReplayState.fromJson(
        json['right'] as Map<String, dynamic>,
      ),
    );
  }

  final int tick;
  final BoardReplayState left;
  final BoardReplayState right;
}

class ReplayResponse {
  const ReplayResponse({
    required this.matchId,
    required this.rulesVersion,
    required this.checksum,
    required this.events,
    required this.stateFrames,
  });

  factory ReplayResponse.fromJson(Map<String, dynamic> json) {
    return ReplayResponse(
      matchId: json['match_id'] as String,
      rulesVersion: json['rules_version'] as String,
      checksum: json['checksum'] as String,
      events: (json['events'] as List<dynamic>)
          .map(
            (event) => BattleEvent.fromJson(
              event as Map<String, dynamic>,
            ),
          )
          .toList(),
      stateFrames: (json['state_frames'] as List<dynamic>? ?? const [])
          .map(
            (frame) => ReplayStateFrame.fromJson(
              frame as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String matchId;
  final String rulesVersion;
  final String checksum;
  final List<BattleEvent> events;
  final List<ReplayStateFrame> stateFrames;

  ReplayStateFrame? stateAt(int tick) {
    ReplayStateFrame? nearest;
    for (final frame in stateFrames) {
      if (frame.tick > tick) {
        break;
      }
      nearest = frame;
    }
    return nearest;
  }
}

class RatingProfile {
  const RatingProfile({
    required this.playerId,
    required this.rating,
    required this.peakRating,
    required this.ratedMatches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.winRate,
  });

  factory RatingProfile.fromJson(Map<String, dynamic> json) {
    return RatingProfile(
      playerId: json['player_id'] as String,
      rating: json['rating'] as int,
      peakRating: json['peak_rating'] as int,
      ratedMatches: json['rated_matches'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      winRate: (json['win_rate'] as num).toDouble(),
    );
  }

  final String playerId;
  final int rating;
  final int peakRating;
  final int ratedMatches;
  final int wins;
  final int draws;
  final int losses;
  final double winRate;
}

class LeagueEntry {
  const LeagueEntry({
    required this.weekKey,
    required this.startsAt,
    required this.endsAt,
    required this.points,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.position,
    required this.participantCount,
  });

  factory LeagueEntry.fromJson(Map<String, dynamic> json) {
    return LeagueEntry(
      weekKey: json['week_key'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      points: json['points'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      position: json['position'] as int,
      participantCount: json['participant_count'] as int,
    );
  }

  final String weekKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final int points;
  final int wins;
  final int draws;
  final int losses;
  final int position;
  final int participantCount;
}

class LeagueStanding {
  const LeagueStanding({
    required this.position,
    required this.playerId,
    required this.displayName,
    required this.points,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.rating,
    required this.isCurrentPlayer,
  });

  factory LeagueStanding.fromJson(Map<String, dynamic> json) {
    return LeagueStanding(
      position: json['position'] as int,
      playerId: json['player_id'] as String,
      displayName: json['display_name'] as String,
      points: json['points'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      rating: json['rating'] as int,
      isCurrentPlayer: json['is_current_player'] as bool,
    );
  }

  final int position;
  final String playerId;
  final String displayName;
  final int points;
  final int wins;
  final int draws;
  final int losses;
  final int rating;
  final bool isCurrentPlayer;
}

class MatchHistoryItem {
  const MatchHistoryItem({
    required this.matchId,
    required this.createdAt,
    required this.opponentKind,
    required this.opponentName,
    required this.outcome,
    required this.rated,
    required this.ratingDelta,
    required this.ratingAfter,
    required this.reason,
    required this.replayPath,
  });

  factory MatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return MatchHistoryItem(
      matchId: json['match_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      opponentKind: json['opponent_kind'] as String,
      opponentName: json['opponent_name'] as String,
      outcome: json['outcome'] as String,
      rated: json['rated'] as bool,
      ratingDelta: json['rating_delta'] as int,
      ratingAfter: json['rating_after'] as int?,
      reason: json['reason'] as String,
      replayPath: json['replay_path'] as String,
    );
  }

  final String matchId;
  final DateTime createdAt;
  final String opponentKind;
  final String opponentName;
  final String outcome;
  final bool rated;
  final int ratingDelta;
  final int? ratingAfter;
  final String reason;
  final String replayPath;
}

class MatchmakingMetrics {
  const MatchmakingMetrics({
    required this.searches,
    required this.humanOpponents,
    required this.botFallbacks,
    required this.humanOpponentRate,
  });

  factory MatchmakingMetrics.fromJson(Map<String, dynamic> json) {
    return MatchmakingMetrics(
      searches: json['searches'] as int,
      humanOpponents: json['human_opponents'] as int,
      botFallbacks: json['bot_fallbacks'] as int,
      humanOpponentRate: (json['human_opponent_rate'] as num).toDouble(),
    );
  }

  final int searches;
  final int humanOpponents;
  final int botFallbacks;
  final double humanOpponentRate;
}

class CareerSnapshot {
  const CareerSnapshot({
    required this.profile,
    required this.league,
    required this.leaderboard,
    required this.recentMatches,
    required this.matchmaking,
  });

  factory CareerSnapshot.fromJson(Map<String, dynamic> json) {
    return CareerSnapshot(
      profile: RatingProfile.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      league: LeagueEntry.fromJson(
        json['league'] as Map<String, dynamic>,
      ),
      leaderboard: (json['leaderboard'] as List<dynamic>)
          .map((item) => LeagueStanding.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      recentMatches: (json['recent_matches'] as List<dynamic>)
          .map((item) => MatchHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      matchmaking: MatchmakingMetrics.fromJson(
        json['matchmaking'] as Map<String, dynamic>,
      ),
    );
  }

  final RatingProfile profile;
  final LeagueEntry league;
  final List<LeagueStanding> leaderboard;
  final List<MatchHistoryItem> recentMatches;
  final MatchmakingMetrics matchmaking;
}

class MatchHistoryPage {
  const MatchHistoryPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory MatchHistoryPage.fromJson(Map<String, dynamic> json) {
    return MatchHistoryPage(
      items: (json['items'] as List<dynamic>)
          .map((item) => MatchHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }

  final List<MatchHistoryItem> items;
  final int total;
  final int limit;
  final int offset;
}

class CatalogBundle {
  const CatalogBundle({
    required this.rulesVersion,
    required this.modules,
    required this.bots,
  });

  final String rulesVersion;
  final List<ModuleSpec> modules;
  final List<BotDefinition> bots;
}
