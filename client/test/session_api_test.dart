import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_relay_client/src/api/relay_api.dart';
import 'package:project_relay_client/src/api/session_storage.dart';
import 'package:project_relay_client/src/models/relay_models.dart';

void main() {
  test('ilk açılış güvenli misafir oturumu oluşturup yenilemeyi saklar',
      () async {
    final storage = _MemorySessionStorage();
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/guest');
      return _jsonResponse(
        _sessionPayload('access-1', 'refresh-1'),
        201,
      );
    });
    final api = RelayApi(
      baseUrl: 'http://relay.test',
      client: client,
      sessionStorage: storage,
    );

    final session = await api.bootstrapSession();

    expect(session.player.displayName, 'MaviRole-2026');
    expect(storage.refreshToken, 'refresh-1');
  });

  test('süresi dolan erişim anahtarını döndürüp isteği bir kez yineler',
      () async {
    final storage = _MemorySessionStorage()..refreshToken = 'refresh-old';
    var refreshCount = 0;
    var boardCount = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh') {
        refreshCount += 1;
        final suffix = refreshCount == 1 ? 'old' : 'new';
        return _jsonResponse(
          _sessionPayload(
            'access-$suffix',
            'refresh-$suffix',
          ),
          200,
        );
      }
      if (request.url.path == '/api/v1/me/board') {
        boardCount += 1;
        if (boardCount == 1) {
          expect(
            request.headers['Authorization'],
            'Bearer access-old',
          );
          return _jsonResponse(
            {
              'code': 'token_expired',
              'message': 'Oturum süresi doldu.',
              'details': null,
            },
            401,
          );
        }
        expect(
          request.headers['Authorization'],
          'Bearer access-new',
        );
        return _jsonResponse(_savedBoardPayload(), 200);
      }
      fail('Beklenmeyen istek: ${request.method} ${request.url}');
    });
    final api = RelayApi(
      baseUrl: 'http://relay.test',
      client: client,
      sessionStorage: storage,
    );
    await api.bootstrapSession();

    final saved = await api.saveBoard(_board());

    expect(saved.id, 'board-1');
    expect(saved.board.name, 'Kalıcı Devre');
    expect(refreshCount, 2);
    expect(boardCount, 2);
    expect(storage.refreshToken, 'refresh-new');
  });
}

http.Response _jsonResponse(
  Object? body,
  int statusCode,
) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

Map<String, dynamic> _sessionPayload(
  String accessToken,
  String refreshToken,
) {
  return {
    'player': {
      'player_id': 'player-1',
      'display_name': 'MaviRole-2026',
      'created_at': '2026-07-29T12:00:00+00:00',
    },
    'tokens': {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': 'bearer',
      'access_expires_in': 900,
      'refresh_expires_in': 2592000,
    },
  };
}

BoardDraft _board() {
  return const BoardDraft(
    name: 'Kalıcı Devre',
    modules: [
      ModulePlacement(
        id: 'P-GEN',
        kind: ModuleKind.generator,
        row: 0,
        column: 1,
        orientation: RelayDirection.south,
      ),
    ],
  );
}

Map<String, dynamic> _savedBoardPayload() {
  return {
    'board_id': 'board-1',
    'fingerprint': List.filled(64, 'a').join(),
    'updated_at': '2026-07-29T12:01:00+00:00',
    'board': _board().toJson(),
    'powered_module_ids': ['P-GEN'],
    'unpowered_module_ids': const <String>[],
  };
}

class _MemorySessionStorage implements SessionStorage {
  String? refreshToken;

  @override
  Future<void> clear() async {
    refreshToken = null;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async {
    refreshToken = token;
  }
}
