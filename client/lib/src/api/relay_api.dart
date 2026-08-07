import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/relay_models.dart';
import 'session_storage.dart';

const _defaultApiUrl = 'http://127.0.0.1:8000';

final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'RELAY_API_URL',
    defaultValue: _defaultApiUrl,
  );
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SecureSessionStorage();
});

final relayApiProvider = Provider<RelayApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return RelayApi(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: client,
    sessionStorage: ref.watch(sessionStorageProvider),
  );
});

final guestSessionProvider = FutureProvider<GuestSession>((ref) {
  return ref.watch(relayApiProvider).bootstrapSession();
});

final catalogsProvider = FutureProvider<CatalogBundle>((ref) {
  return ref.watch(relayApiProvider).fetchCatalogs();
});

final statisticsProvider = FutureProvider<CareerSnapshot>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchStatistics();
});

final careerProvider = statisticsProvider;

final progressionProvider = FutureProvider<ProgressionSnapshot>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchProgression();
});

final careerRunProvider = FutureProvider<CareerRunSnapshot>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchCareerRun();
});

final careerBoardProvider = FutureProvider.autoDispose<SavedBoard?>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchCareerBoard();
});

final collectionProvider = FutureProvider.autoDispose<CollectionSnapshot>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchCollection();
});

final seasonProvider = FutureProvider.autoDispose<SeasonSnapshotModel>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchSeason();
});

final alphaSafetyProvider =
    FutureProvider.autoDispose<AlphaSafetySnapshotModel>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchAlphaSafety();
});

final socialProvider = FutureProvider.autoDispose<SocialSnapshotModel>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchSocial();
});

final clanDirectoryProvider = FutureProvider.autoDispose<List<ClanModel>>((ref) async {
  await ref.watch(guestSessionProvider.future);
  return ref.watch(relayApiProvider).fetchClans();
});

class RelayApi {
  RelayApi({
    required String baseUrl,
    required http.Client client,
    required SessionStorage sessionStorage,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client,
        _sessionStorage = sessionStorage;

  final String _baseUrl;
  final http.Client _client;
  final SessionStorage _sessionStorage;
  AuthTokens? _tokens;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<GuestSession> bootstrapSession() async {
    final storedRefreshToken = await _sessionStorage.readRefreshToken();
    if (storedRefreshToken != null) {
      try {
        return await refreshSession(storedRefreshToken);
      } on RelayApiException catch (error) {
        if (error.statusCode != 401) {
          rethrow;
        }
        await _sessionStorage.clear();
      }
    }
    return createGuestSession();
  }

  Future<GuestSession> createGuestSession() async {
    final payload = await _post('/api/v1/auth/guest', const {});
    return _acceptSession(payload);
  }

  Future<GuestSession> refreshSession(String refreshToken) async {
    final payload = await _post('/api/v1/auth/refresh', {
      'refresh_token': refreshToken,
    });
    return _acceptSession(payload);
  }

  Future<CatalogBundle> fetchCatalogs() async {
    final responses = await Future.wait([
      _get('/api/v1/modules'),
      _get('/api/v1/bots'),
    ]);
    final modulePayload = responses[0];
    final botPayload = responses[1];
    return CatalogBundle(
      rulesVersion: modulePayload['rules_version'] as String,
      modules: (modulePayload['modules'] as List<dynamic>)
          .map(
            (module) => ModuleSpec.fromJson(
              module as Map<String, dynamic>,
            ),
          )
          .toList(),
      bots: (botPayload['bots'] as List<dynamic>)
          .map(
            (bot) => BotDefinition.fromJson(
              bot as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Future<SavedBoard?> fetchCurrentBoard() async {
    final payload = await _get(
      '/api/v1/me',
      authorized: true,
    );
    final boardPayload = payload['board'];
    return boardPayload is Map<String, dynamic>
        ? SavedBoard.fromJson(boardPayload)
        : null;
  }

  Future<SavedBoard?> fetchCareerBoard() async {
    try {
      final payload = await _get(
        '/api/v1/me/career-board',
        authorized: true,
      );
      return SavedBoard.fromJson(payload);
    } on RelayApiException catch (error) {
      if (error.code == 'career_board_not_found' || error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<SavedBoard> saveCareerBoard(BoardDraft board) async {
    final payload = await _put(
      '/api/v1/me/career-board',
      board.toJson(),
      authorized: true,
    );
    return SavedBoard.fromJson(payload);
  }

  Future<BoardValidation> validateBoard(BoardDraft board) async {
    final payload = await _post(
      '/api/v1/boards/validate',
      board.toJson(),
    );
    return BoardValidation.fromJson(payload);
  }

  Future<SavedBoard> saveBoard(BoardDraft board) async {
    final payload = await _put(
      '/api/v1/me/board',
      board.toJson(),
      authorized: true,
    );
    return SavedBoard.fromJson(payload);
  }

  Future<MatchResponse> createAsyncMatch() async {
    final payload = await _post(
      '/api/v1/matches/async',
      const {},
      authorized: true,
    );
    return MatchResponse.fromJson(payload);
  }

  Future<MatchResponse> createBotMatch({
    required BoardDraft board,
    required String botId,
  }) async {
    final payload = await _post('/api/v1/matches/bot', {
      'board': board.toJson(),
      'bot_id': botId,
    });
    return MatchResponse.fromJson(payload);
  }

  Future<MatchResponse> fetchMatch(String matchId) async {
    final payload = await _get(
      '/api/v1/matches/$matchId',
      authorized: true,
    );
    return MatchResponse.fromJson(payload);
  }

  Future<CareerSnapshot> fetchStatistics({
    int historyLimit = 10,
    int leaderboardLimit = 20,
  }) async {
    final payload = await _get(
      '/api/v1/me/statistics?history_limit=$historyLimit'
      '&leaderboard_limit=$leaderboardLimit',
      authorized: true,
    );
    return CareerSnapshot.fromJson(payload);
  }

  Future<CareerSnapshot> fetchCareer({
    int historyLimit = 10,
    int leaderboardLimit = 20,
  }) {
    return fetchStatistics(
      historyLimit: historyLimit,
      leaderboardLimit: leaderboardLimit,
    );
  }

  Future<ProgressionSnapshot> fetchProgression() async {
    final payload = await _get(
      '/api/v1/me/progression',
      authorized: true,
    );
    return ProgressionSnapshot.fromJson(payload);
  }


  Future<SeasonSnapshotModel> fetchSeason({int limit = 20}) async {
    final payload = await _get(
      '/api/v1/me/season?limit=$limit',
      authorized: true,
    );
    return SeasonSnapshotModel.fromJson(payload);
  }

  Future<ProgressionReward> claimSeasonTier(int tier) async {
    final payload = await _post(
      '/api/v1/me/season/tiers/$tier/claim',
      const {},
      authorized: true,
    );
    return ProgressionReward.fromJson(
      payload['reward'] as Map<String, dynamic>,
    );
  }

  Future<AlphaSafetySnapshotModel> fetchAlphaSafety() async {
    final payload = await _get(
      '/api/v1/me/alpha-safety',
      authorized: true,
    );
    return AlphaSafetySnapshotModel.fromJson(payload);
  }

  Future<AlphaFeedbackReceiptModel> submitAlphaFeedback({
    required String category,
    required String message,
  }) async {
    final payload = await _post(
      '/api/v1/alpha/feedback',
      {
        'category': category,
        'message': message,
        'client_version': '0.8.10',
      },
      authorized: true,
    );
    return AlphaFeedbackReceiptModel.fromJson(payload);
  }

  Future<SocialSnapshotModel> fetchSocial() async {
    final payload = await _get(
      '/api/v1/me/social',
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<SocialSnapshotModel> updateSocialProfile({
    required String statusMessage,
    required ModuleKind favoriteModule,
  }) async {
    final payload = await _put(
      '/api/v1/me/social/profile',
      {
        'status_message': statusMessage,
        'favorite_module': favoriteModule.wireValue,
      },
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<List<SocialPlayerModel>> searchSocialPlayers(String query) async {
    final payload = await _get(
      '/api/v1/social/players?query=${Uri.encodeQueryComponent(query)}',
      authorized: true,
    );
    return (payload['players'] as List<dynamic>)
        .map(
          (item) => SocialPlayerModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  Future<SocialSnapshotModel> sendFriendRequest(String playerId) async {
    final payload = await _post(
      '/api/v1/me/friends/requests/$playerId',
      const {},
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<SocialSnapshotModel> respondFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    final action = accept ? 'accept' : 'decline';
    final payload = await _post(
      '/api/v1/me/friends/requests/$requestId/$action',
      const {},
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<SocialSnapshotModel> removeFriend(String playerId) async {
    final payload = await _post(
      '/api/v1/me/friends/$playerId/remove',
      const {},
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<List<ClanModel>> fetchClans() async {
    final payload = await _get(
      '/api/v1/clans',
      authorized: true,
    );
    return (payload['clans'] as List<dynamic>)
        .map(
          (item) => ClanModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  Future<SocialSnapshotModel> createClan({
    required String name,
    required String tag,
    required String description,
  }) async {
    final payload = await _post(
      '/api/v1/clans',
      {
        'name': name,
        'tag': tag,
        'description': description,
      },
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<SocialSnapshotModel> joinClan(String clanId) async {
    final payload = await _post(
      '/api/v1/clans/$clanId/join',
      const {},
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<SocialSnapshotModel> leaveClan() async {
    final payload = await _post(
      '/api/v1/me/clan/leave',
      const {},
      authorized: true,
    );
    return SocialSnapshotModel.fromJson(payload);
  }

  Future<CollectionSnapshot> fetchCollection() async {
    final payload = await _get(
      '/api/v1/me/collection',
      authorized: true,
    );
    return CollectionSnapshot.fromJson(payload);
  }

  Future<CollectionSnapshot> purchaseCosmetic(String cosmeticId) async {
    final payload = await _post(
      '/api/v1/me/collection/cosmetics/$cosmeticId/purchase',
      const {},
      authorized: true,
    );
    return CollectionSnapshot.fromJson(payload);
  }

  Future<CollectionSnapshot> equipCosmetic(String cosmeticId) async {
    final payload = await _put(
      '/api/v1/me/collection/equipped',
      {'cosmetic_id': cosmeticId},
      authorized: true,
    );
    return CollectionSnapshot.fromJson(payload);
  }

  Future<CollectionSnapshot> saveControlledKit({
    required KitMode mode,
    required String name,
    required List<ModuleKind> moduleKinds,
  }) async {
    final payload = await _put(
      '/api/v1/me/kit',
      {
        'mode': mode.wireValue,
        'name': name,
        'module_kinds': moduleKinds.map((kind) => kind.wireValue).toList(),
      },
      authorized: true,
    );
    return CollectionSnapshot.fromJson(payload);
  }

  Future<CareerRunSnapshot> fetchCareerRun() async {
    final payload = await _get(
      '/api/v1/me/career-run',
      authorized: true,
    );
    return CareerRunSnapshot.fromJson(payload);
  }

  Future<CareerRunSnapshot> startCareerRun() async {
    final payload = await _post(
      '/api/v1/me/career-run/start',
      const {},
      authorized: true,
    );
    return CareerRunSnapshot.fromJson(payload);
  }

  Future<CareerRunSnapshot> chooseCareerBooster(String boosterId) async {
    final payload = await _post(
      '/api/v1/me/career-run/booster',
      {'booster_id': boosterId},
      authorized: true,
    );
    return CareerRunSnapshot.fromJson(payload);
  }

  Future<CareerBattleResponse> battleCareerRun() async {
    final payload = await _post(
      '/api/v1/me/career-run/battle',
      const {},
      authorized: true,
    );
    return CareerBattleResponse.fromJson(payload);
  }

  Future<CareerRunSnapshot> abandonCareerRun() async {
    final payload = await _post(
      '/api/v1/me/career-run/abandon',
      const {},
      authorized: true,
    );
    return CareerRunSnapshot.fromJson(payload);
  }

  Future<ProgressionReward> claimDailyMission(String missionId) async {
    final payload = await _post(
      '/api/v1/me/daily-missions/$missionId/claim',
      const {},
      authorized: true,
    );
    return ProgressionReward.fromJson(
      payload['reward'] as Map<String, dynamic>,
    );
  }

  Future<ProgressionReward> claimAchievement(String achievementId) async {
    final payload = await _post(
      '/api/v1/me/achievements/$achievementId/claim',
      const {},
      authorized: true,
    );
    return ProgressionReward.fromJson(
      payload['reward'] as Map<String, dynamic>,
    );
  }

  Future<MatchHistoryPage> fetchMatchHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final payload = await _get(
      '/api/v1/me/matches?limit=$limit&offset=$offset',
      authorized: true,
    );
    return MatchHistoryPage.fromJson(payload);
  }

  Future<ReplayResponse> fetchReplay(String matchId) async {
    final payload = await _get(
      '/api/v1/matches/$matchId/replay',
      authorized: _tokens != null,
    );
    return ReplayResponse.fromJson(payload);
  }

  Future<GuestSession> _acceptSession(
    Map<String, dynamic> payload,
  ) async {
    final session = GuestSession.fromJson(payload);
    _tokens = session.tokens;
    await _sessionStorage.writeRefreshToken(
      session.tokens.refreshToken,
    );
    return session;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool authorized = false,
  }) {
    return _request('GET', path, authorized: authorized);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authorized = false,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body, {
    bool authorized = false,
  }) {
    return _request(
      'PUT',
      path,
      body: body,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
    bool allowRefresh = true,
  }) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };
      if (authorized) {
        final accessToken = _tokens?.accessToken;
        if (accessToken == null) {
          throw const RelayApiException(
            'Misafir oturumu henüz hazır değil.',
            code: 'authorization_required',
            statusCode: 401,
          );
        }
        headers['Authorization'] = 'Bearer $accessToken';
      }
      final encodedBody = body == null ? null : jsonEncode(body);
      late final http.Response response;
      if (method == 'GET') {
        response = await _client
            .get(_uri(path), headers: headers)
            .timeout(const Duration(seconds: 12));
      } else if (method == 'POST') {
        response = await _client
            .post(_uri(path), headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: 20));
      } else if (method == 'PUT') {
        response = await _client
            .put(_uri(path), headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: 20));
      } else {
        throw StateError('Desteklenmeyen HTTP yöntemi: $method');
      }
      if (
        response.statusCode == 401 &&
        authorized &&
        allowRefresh &&
        _tokens != null
      ) {
        await refreshSession(_tokens!.refreshToken);
        return _request(
          method,
          path,
          body: body,
          authorized: true,
          allowRefresh: false,
        );
      }
      return _decode(response);
    } on TimeoutException {
      throw const RelayApiException(
        'Sunucu zamanında yanıt vermedi. FastAPI servisinin açık olduğundan '
        'emin olun.',
      );
    } on http.ClientException catch (error) {
      throw RelayApiException(
        'Sunucuya bağlanılamadı: ${error.message}',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map<String, dynamic>) {
        throw RelayApiException(
          decoded['message'] as String? ?? 'Sunucu isteği reddetti.',
          code: decoded['code'] as String?,
          statusCode: response.statusCode,
        );
      }
      throw RelayApiException(
        'Sunucu isteği reddetti.',
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const RelayApiException('Sunucudan beklenmeyen veri geldi.');
    }
    return decoded;
  }
}

class RelayApiException implements Exception {
  const RelayApiException(
    this.message, {
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}
