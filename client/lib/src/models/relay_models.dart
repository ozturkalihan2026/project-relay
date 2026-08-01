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

class SeasonPointChangeModel {
  const SeasonPointChangeModel({
    required this.seasonKey,
    required this.outcome,
    required this.pointsGained,
    required this.totalPoints,
  });

  factory SeasonPointChangeModel.fromJson(Map<String, dynamic> json) {
    return SeasonPointChangeModel(
      seasonKey: json['season_key'] as String,
      outcome: json['outcome'] as String,
      pointsGained: json['points_gained'] as int,
      totalPoints: json['total_points'] as int,
    );
  }

  final String seasonKey;
  final String outcome;
  final int pointsGained;
  final int totalPoints;
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
    this.progressionReward,
    this.seasonChange,
  });

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    final replay = json['replay'] as Map<String, dynamic>;
    final ratingPayload = json['rating_change'];
    final progressionPayload = json['progression_reward'];
    final seasonPayload = json['season_change'];
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
      progressionReward: progressionPayload is Map<String, dynamic>
          ? ProgressionReward.fromJson(progressionPayload)
          : null,
      seasonChange: seasonPayload is Map<String, dynamic>
          ? SeasonPointChangeModel.fromJson(seasonPayload)
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
  final ProgressionReward? progressionReward;
  final SeasonPointChangeModel? seasonChange;
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

class ProgressionReward {
  const ProgressionReward({
    required this.sourceType,
    required this.sourceId,
    required this.reason,
    required this.xp,
    required this.credits,
    required this.levelBefore,
    required this.levelAfter,
    required this.levelUp,
    required this.totalXpAfter,
    required this.creditsAfter,
    required this.grantedAt,
  });

  factory ProgressionReward.fromJson(Map<String, dynamic> json) {
    return ProgressionReward(
      sourceType: json['source_type'] as String,
      sourceId: json['source_id'] as String,
      reason: json['reason'] as String,
      xp: json['xp'] as int,
      credits: json['credits'] as int,
      levelBefore: json['level_before'] as int,
      levelAfter: json['level_after'] as int,
      levelUp: json['level_up'] as bool,
      totalXpAfter: json['total_xp_after'] as int,
      creditsAfter: json['credits_after'] as int,
      grantedAt: DateTime.parse(json['granted_at'] as String),
    );
  }

  final String sourceType;
  final String sourceId;
  final String reason;
  final int xp;
  final int credits;
  final int levelBefore;
  final int levelAfter;
  final bool levelUp;
  final int totalXpAfter;
  final int creditsAfter;
  final DateTime grantedAt;
}

class PlayerProgression {
  const PlayerProgression({
    required this.playerId,
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.credits,
    required this.matchesCompleted,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  factory PlayerProgression.fromJson(Map<String, dynamic> json) {
    return PlayerProgression(
      playerId: json['player_id'] as String,
      totalXp: json['total_xp'] as int,
      level: json['level'] as int,
      xpIntoLevel: json['xp_into_level'] as int,
      xpForNextLevel: json['xp_for_next_level'] as int,
      credits: json['credits'] as int,
      matchesCompleted: json['matches_completed'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
    );
  }

  double get levelProgress => xpForNextLevel == 0
      ? 1
      : (xpIntoLevel / xpForNextLevel).clamp(0, 1).toDouble();

  final String playerId;
  final int totalXp;
  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final int credits;
  final int matchesCompleted;
  final int wins;
  final int draws;
  final int losses;
}

class DailyMission {
  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.completed,
    required this.claimed,
    required this.rewardXp,
    required this.rewardCredits,
  });

  factory DailyMission.fromJson(Map<String, dynamic> json) {
    return DailyMission(
      id: json['mission_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      progress: json['progress'] as int,
      target: json['target'] as int,
      completed: json['completed'] as bool,
      claimed: json['claimed'] as bool,
      rewardXp: json['reward_xp'] as int,
      rewardCredits: json['reward_credits'] as int,
    );
  }

  double get progressRatio => target == 0
      ? 1
      : (progress / target).clamp(0, 1).toDouble();

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
  final bool completed;
  final bool claimed;
  final int rewardXp;
  final int rewardCredits;
}

class PlayerAchievement {
  const PlayerAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.unlocked,
    required this.claimed,
    required this.rewardXp,
    required this.rewardCredits,
  });

  factory PlayerAchievement.fromJson(Map<String, dynamic> json) {
    return PlayerAchievement(
      id: json['achievement_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      progress: json['progress'] as int,
      target: json['target'] as int,
      unlocked: json['unlocked'] as bool,
      claimed: json['claimed'] as bool,
      rewardXp: json['reward_xp'] as int,
      rewardCredits: json['reward_credits'] as int,
    );
  }

  double get progressRatio => target == 0
      ? 1
      : (progress / target).clamp(0, 1).toDouble();

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
  final bool unlocked;
  final bool claimed;
  final int rewardXp;
  final int rewardCredits;
}

class BoosterMastery {
  const BoosterMastery({
    required this.id,
    required this.displayName,
    required this.description,
    required this.unlockLevel,
    required this.unlocked,
    required this.tier,
    required this.effectValue,
    required this.effectLabel,
    required this.nextTierLevel,
  });

  factory BoosterMastery.fromJson(Map<String, dynamic> json) {
    return BoosterMastery(
      id: json['booster_id'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      unlockLevel: json['unlock_level'] as int,
      unlocked: json['unlocked'] as bool,
      tier: json['tier'] as int,
      effectValue: json['effect_value'] as int,
      effectLabel: json['effect_label'] as String,
      nextTierLevel: json['next_tier_level'] as int?,
    );
  }

  final String id;
  final String displayName;
  final String description;
  final int unlockLevel;
  final bool unlocked;
  final int tier;
  final int effectValue;
  final String effectLabel;
  final int? nextTierLevel;
}

class ProgressionSnapshot {
  const ProgressionSnapshot({
    required this.dayKey,
    required this.profile,
    required this.dailyMissions,
    required this.achievements,
    required this.boosters,
  });

  factory ProgressionSnapshot.fromJson(Map<String, dynamic> json) {
    return ProgressionSnapshot(
      dayKey: json['day_key'] as String,
      profile: PlayerProgression.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      dailyMissions: (json['daily_missions'] as List<dynamic>)
          .map((item) => DailyMission.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      achievements: (json['achievements'] as List<dynamic>)
          .map(
            (item) => PlayerAchievement.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      boosters: (json['boosters'] as List<dynamic>)
          .map((item) => BoosterMastery.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String dayKey;
  final PlayerProgression profile;
  final List<DailyMission> dailyMissions;
  final List<PlayerAchievement> achievements;
  final List<BoosterMastery> boosters;
}


class CareerBoosterChoice {
  const CareerBoosterChoice({
    required this.id,
    required this.displayName,
    required this.description,
    required this.tier,
    required this.effectValue,
    required this.effectLabel,
    required this.creditCost,
  });

  factory CareerBoosterChoice.fromJson(Map<String, dynamic> json) {
    return CareerBoosterChoice(
      id: json['booster_id'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      tier: json['tier'] as int,
      effectValue: json['effect_value'] as int,
      effectLabel: json['effect_label'] as String,
      creditCost: json['credit_cost'] as int? ?? 0,
    );
  }

  final String id;
  final String displayName;
  final String description;
  final int tier;
  final int effectValue;
  final String effectLabel;
  final int creditCost;
}

class CareerOpponentPreview {
  const CareerOpponentPreview({
    required this.stageNumber,
    required this.totalStages,
    required this.title,
    required this.briefing,
    required this.isBoss,
    required this.opponentId,
    required this.displayName,
    required this.description,
    required this.board,
  });

  factory CareerOpponentPreview.fromJson(Map<String, dynamic> json) {
    return CareerOpponentPreview(
      stageNumber: json['stage_number'] as int,
      totalStages: json['total_stages'] as int,
      title: json['title'] as String,
      briefing: json['briefing'] as String,
      isBoss: json['is_boss'] as bool,
      opponentId: json['opponent_id'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      board: BoardDraft.fromJson(json['board'] as Map<String, dynamic>),
    );
  }

  final int stageNumber;
  final int totalStages;
  final String title;
  final String briefing;
  final bool isBoss;
  final String opponentId;
  final String displayName;
  final String description;
  final BoardDraft board;
}

class CareerRunSnapshot {
  const CareerRunSnapshot({
    required this.runId,
    required this.status,
    required this.stageIndex,
    required this.totalStages,
    required this.wins,
    required this.selectedBoosters,
    required this.offeredBoosters,
    required this.opponent,
    required this.lastMatchId,
    required this.reward,
    required this.boardRequired,
    required this.canBattle,
    required this.canChooseBooster,
    required this.startedAt,
    required this.endedAt,
  });

  factory CareerRunSnapshot.fromJson(Map<String, dynamic> json) {
    final opponentPayload = json['opponent'];
    final rewardPayload = json['reward'];
    return CareerRunSnapshot(
      runId: json['run_id'] as String?,
      status: json['status'] as String,
      stageIndex: json['stage_index'] as int,
      totalStages: json['total_stages'] as int,
      wins: json['wins'] as int,
      selectedBoosters: (json['selected_boosters'] as List<dynamic>)
          .map(
            (item) => CareerBoosterChoice.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      offeredBoosters: (json['offered_boosters'] as List<dynamic>)
          .map(
            (item) => CareerBoosterChoice.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      opponent: opponentPayload is Map<String, dynamic>
          ? CareerOpponentPreview.fromJson(opponentPayload)
          : null,
      lastMatchId: json['last_match_id'] as String?,
      reward: rewardPayload is Map<String, dynamic>
          ? ProgressionReward.fromJson(rewardPayload)
          : null,
      boardRequired: json['board_required'] as bool,
      canBattle: json['can_battle'] as bool,
      canChooseBooster: json['can_choose_booster'] as bool,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
    );
  }

  final String? runId;
  final String status;
  final int stageIndex;
  final int totalStages;
  final int wins;
  final List<CareerBoosterChoice> selectedBoosters;
  final List<CareerBoosterChoice> offeredBoosters;
  final CareerOpponentPreview? opponent;
  final String? lastMatchId;
  final ProgressionReward? reward;
  final bool boardRequired;
  final bool canBattle;
  final bool canChooseBooster;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get isTerminal =>
      status == 'completed' || status == 'failed' || status == 'abandoned';
}

class CareerBattleResponse {
  const CareerBattleResponse({required this.match, required this.run});

  factory CareerBattleResponse.fromJson(Map<String, dynamic> json) {
    return CareerBattleResponse(
      match: MatchResponse.fromJson(json['match'] as Map<String, dynamic>),
      run: CareerRunSnapshot.fromJson(json['run'] as Map<String, dynamic>),
    );
  }

  final MatchResponse match;
  final CareerRunSnapshot run;
}

class ControlledKit {
  const ControlledKit({
    required this.name,
    required this.moduleKinds,
    required this.updatedAt,
  });

  factory ControlledKit.fromJson(Map<String, dynamic> json) {
    return ControlledKit(
      name: json['name'] as String,
      moduleKinds: (json['module_kinds'] as List<dynamic>)
          .map((value) => ModuleKind.parse(value as String))
          .toList(growable: false),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String name;
  final List<ModuleKind> moduleKinds;
  final DateTime updatedAt;

  Map<ModuleKind, int> get counts {
    final values = <ModuleKind, int>{};
    for (final kind in moduleKinds) {
      values[kind] = (values[kind] ?? 0) + 1;
    }
    return values;
  }
}

class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.category,
    required this.displayName,
    required this.description,
    required this.creditCost,
    required this.accentHex,
    required this.owned,
    required this.equipped,
  });

  factory CosmeticItem.fromJson(Map<String, dynamic> json) {
    return CosmeticItem(
      id: json['cosmetic_id'] as String,
      category: json['category'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      creditCost: json['credit_cost'] as int,
      accentHex: json['accent_hex'] as String,
      owned: json['owned'] as bool,
      equipped: json['equipped'] as bool,
    );
  }

  final String id;
  final String category;
  final String displayName;
  final String description;
  final int creditCost;
  final String accentHex;
  final bool owned;
  final bool equipped;
}

class CollectionSnapshot {
  const CollectionSnapshot({
    required this.playerId,
    required this.credits,
    required this.cosmetics,
    required this.kit,
    required this.equippedModuleSkinId,
    required this.equippedBoardThemeId,
    required this.equippedProfileFrameId,
  });

  factory CollectionSnapshot.fromJson(Map<String, dynamic> json) {
    return CollectionSnapshot(
      playerId: json['player_id'] as String,
      credits: json['credits'] as int,
      cosmetics: (json['cosmetics'] as List<dynamic>)
          .map((item) => CosmeticItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      kit: ControlledKit.fromJson(json['kit'] as Map<String, dynamic>),
      equippedModuleSkinId: json['equipped_module_skin_id'] as String,
      equippedBoardThemeId: json['equipped_board_theme_id'] as String,
      equippedProfileFrameId: json['equipped_profile_frame_id'] as String,
    );
  }

  final String playerId;
  final int credits;
  final List<CosmeticItem> cosmetics;
  final ControlledKit kit;
  final String equippedModuleSkinId;
  final String equippedBoardThemeId;
  final String equippedProfileFrameId;
}

class SeasonWindowModel {
  const SeasonWindowModel({
    required this.key,
    required this.title,
    required this.startsAt,
    required this.endsAt,
  });

  factory SeasonWindowModel.fromJson(Map<String, dynamic> json) {
    return SeasonWindowModel(
      key: json['season_key'] as String,
      title: json['title'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
    );
  }

  final String key;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
}

class SeasonEntryModel {
  const SeasonEntryModel({
    required this.points,
    required this.matches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.position,
    required this.participantCount,
    required this.claimedTiers,
  });

  factory SeasonEntryModel.fromJson(Map<String, dynamic> json) {
    return SeasonEntryModel(
      points: json['points'] as int,
      matches: json['matches'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      position: json['position'] as int,
      participantCount: json['participant_count'] as int,
      claimedTiers: (json['claimed_tiers'] as List<dynamic>)
          .map((value) => value as int)
          .toSet(),
    );
  }

  final int points;
  final int matches;
  final int wins;
  final int draws;
  final int losses;
  final int position;
  final int participantCount;
  final Set<int> claimedTiers;
}

class SeasonTierModel {
  const SeasonTierModel({
    required this.tier,
    required this.title,
    required this.requiredPoints,
    required this.rewardXp,
    required this.rewardCredits,
    required this.unlocked,
    required this.claimed,
  });

  factory SeasonTierModel.fromJson(Map<String, dynamic> json) {
    return SeasonTierModel(
      tier: json['tier'] as int,
      title: json['title'] as String,
      requiredPoints: json['required_points'] as int,
      rewardXp: json['reward_xp'] as int,
      rewardCredits: json['reward_credits'] as int,
      unlocked: json['unlocked'] as bool,
      claimed: json['claimed'] as bool,
    );
  }

  final int tier;
  final String title;
  final int requiredPoints;
  final int rewardXp;
  final int rewardCredits;
  final bool unlocked;
  final bool claimed;
}

class SeasonStandingModel {
  const SeasonStandingModel({
    required this.position,
    required this.playerId,
    required this.displayName,
    required this.points,
    required this.wins,
    required this.matches,
    required this.isCurrentPlayer,
  });

  factory SeasonStandingModel.fromJson(Map<String, dynamic> json) {
    return SeasonStandingModel(
      position: json['position'] as int,
      playerId: json['player_id'] as String,
      displayName: json['display_name'] as String,
      points: json['points'] as int,
      wins: json['wins'] as int,
      matches: json['matches'] as int,
      isCurrentPlayer: json['is_current_player'] as bool,
    );
  }

  final int position;
  final String playerId;
  final String displayName;
  final int points;
  final int wins;
  final int matches;
  final bool isCurrentPlayer;
}

class SeasonSnapshotModel {
  const SeasonSnapshotModel({
    required this.season,
    required this.entry,
    required this.tiers,
    required this.leaderboard,
  });

  factory SeasonSnapshotModel.fromJson(Map<String, dynamic> json) {
    return SeasonSnapshotModel(
      season: SeasonWindowModel.fromJson(
        json['season'] as Map<String, dynamic>,
      ),
      entry: SeasonEntryModel.fromJson(
        json['entry'] as Map<String, dynamic>,
      ),
      tiers: (json['tiers'] as List<dynamic>)
          .map((item) => SeasonTierModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      leaderboard: (json['leaderboard'] as List<dynamic>)
          .map(
            (item) => SeasonStandingModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final SeasonWindowModel season;
  final SeasonEntryModel entry;
  final List<SeasonTierModel> tiers;
  final List<SeasonStandingModel> leaderboard;
}

class AlphaSafetySnapshotModel {
  const AlphaSafetySnapshotModel({
    required this.matchRequests,
    required this.matchLimit,
    required this.matchWindowSeconds,
    required this.feedbackRequests,
    required this.feedbackLimit,
    required this.feedbackWindowSeconds,
    required this.blockedUntil,
    required this.serverAuthoritativeResults,
    required this.idempotentRewards,
    required this.boardValidation,
  });

  factory AlphaSafetySnapshotModel.fromJson(Map<String, dynamic> json) {
    return AlphaSafetySnapshotModel(
      matchRequests: json['match_requests'] as int,
      matchLimit: json['match_limit'] as int,
      matchWindowSeconds: json['match_window_seconds'] as int,
      feedbackRequests: json['feedback_requests'] as int,
      feedbackLimit: json['feedback_limit'] as int,
      feedbackWindowSeconds: json['feedback_window_seconds'] as int,
      blockedUntil: json['blocked_until'] == null
          ? null
          : DateTime.parse(json['blocked_until'] as String),
      serverAuthoritativeResults:
          json['server_authoritative_results'] as bool,
      idempotentRewards: json['idempotent_rewards'] as bool,
      boardValidation: json['board_validation'] as bool,
    );
  }

  final int matchRequests;
  final int matchLimit;
  final int matchWindowSeconds;
  final int feedbackRequests;
  final int feedbackLimit;
  final int feedbackWindowSeconds;
  final DateTime? blockedUntil;
  final bool serverAuthoritativeResults;
  final bool idempotentRewards;
  final bool boardValidation;
}

class AlphaFeedbackReceiptModel {
  const AlphaFeedbackReceiptModel({
    required this.feedbackId,
    required this.category,
    required this.createdAt,
  });

  factory AlphaFeedbackReceiptModel.fromJson(Map<String, dynamic> json) {
    return AlphaFeedbackReceiptModel(
      feedbackId: json['feedback_id'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String feedbackId;
  final String category;
  final DateTime createdAt;
}

class SocialPlayerModel {
  const SocialPlayerModel({
    required this.playerId,
    required this.displayName,
    required this.statusMessage,
    required this.favoriteModule,
    required this.relationship,
  });

  factory SocialPlayerModel.fromJson(Map<String, dynamic> json) {
    return SocialPlayerModel(
      playerId: json['player_id'] as String,
      displayName: json['display_name'] as String,
      statusMessage: json['status_message'] as String,
      favoriteModule: ModuleKind.parse(json['favorite_module'] as String),
      relationship: json['relationship'] as String,
    );
  }

  final String playerId;
  final String displayName;
  final String statusMessage;
  final ModuleKind favoriteModule;
  final String relationship;
}

class FriendRequestModel {
  const FriendRequestModel({
    required this.requestId,
    required this.player,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: json['request_id'] as String,
      player: SocialPlayerModel.fromJson(
        json['player'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String requestId;
  final SocialPlayerModel player;
  final DateTime createdAt;
}

class SocialProfileModel {
  const SocialProfileModel({
    required this.playerId,
    required this.displayName,
    required this.statusMessage,
    required this.favoriteModule,
    required this.friendCount,
  });

  factory SocialProfileModel.fromJson(Map<String, dynamic> json) {
    return SocialProfileModel(
      playerId: json['player_id'] as String,
      displayName: json['display_name'] as String,
      statusMessage: json['status_message'] as String,
      favoriteModule: ModuleKind.parse(json['favorite_module'] as String),
      friendCount: json['friend_count'] as int,
    );
  }

  final String playerId;
  final String displayName;
  final String statusMessage;
  final ModuleKind favoriteModule;
  final int friendCount;
}

class ClanMemberModel {
  const ClanMemberModel({
    required this.playerId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    required this.isCurrentPlayer,
  });

  factory ClanMemberModel.fromJson(Map<String, dynamic> json) {
    return ClanMemberModel(
      playerId: json['player_id'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isCurrentPlayer: json['is_current_player'] as bool,
    );
  }

  final String playerId;
  final String displayName;
  final String role;
  final DateTime joinedAt;
  final bool isCurrentPlayer;
}

class ClanModel {
  const ClanModel({
    required this.clanId,
    required this.name,
    required this.tag,
    required this.description,
    required this.leaderPlayerId,
    required this.isOpen,
    required this.memberCount,
    required this.members,
  });

  factory ClanModel.fromJson(Map<String, dynamic> json) {
    return ClanModel(
      clanId: json['clan_id'] as String,
      name: json['name'] as String,
      tag: json['tag'] as String,
      description: json['description'] as String,
      leaderPlayerId: json['leader_player_id'] as String,
      isOpen: json['is_open'] as bool,
      memberCount: json['member_count'] as int,
      members: (json['members'] as List<dynamic>)
          .map(
            (item) => ClanMemberModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String clanId;
  final String name;
  final String tag;
  final String description;
  final String leaderPlayerId;
  final bool isOpen;
  final int memberCount;
  final List<ClanMemberModel> members;
}

class SocialSnapshotModel {
  const SocialSnapshotModel({
    required this.profile,
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.friends,
    required this.clan,
  });

  factory SocialSnapshotModel.fromJson(Map<String, dynamic> json) {
    final clanPayload = json['clan'];
    return SocialSnapshotModel(
      profile: SocialProfileModel.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      incomingRequests: (json['incoming_requests'] as List<dynamic>)
          .map(
            (item) => FriendRequestModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      outgoingRequests: (json['outgoing_requests'] as List<dynamic>)
          .map(
            (item) => FriendRequestModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      friends: (json['friends'] as List<dynamic>)
          .map(
            (item) => SocialPlayerModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      clan: clanPayload is Map<String, dynamic>
          ? ClanModel.fromJson(clanPayload)
          : null,
    );
  }

  final SocialProfileModel profile;
  final List<FriendRequestModel> incomingRequests;
  final List<FriendRequestModel> outgoingRequests;
  final List<SocialPlayerModel> friends;
  final ClanModel? clan;
}
