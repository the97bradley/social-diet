import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class TrelloException implements Exception {
  TrelloException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TrelloBoard {
  const TrelloBoard({required this.id, required this.name, this.closed = false});

  final String id;
  final String name;
  final bool closed;

  factory TrelloBoard.fromJson(Map<String, dynamic> json) {
    return TrelloBoard(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      closed: json['closed'] as bool? ?? false,
    );
  }
}

class TrelloList {
  const TrelloList({required this.id, required this.name});

  final String id;
  final String name;

  factory TrelloList.fromJson(Map<String, dynamic> json) {
    return TrelloList(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );
  }
}

Uri trelloAuthorizeUrl(String apiKey) {
  return Uri.https('trello.com', '/1/authorize', {
    'expiration': 'never',
    'name': 'Social Diet',
    'scope': 'read,write',
    'response_type': 'token',
    'key': apiKey,
  });
}

String trelloCardDesc(TrackerGoal goal) {
  return 'Social Diet goal\n'
      'Target: ${goal.targetValue.toStringAsFixed(0)} ${goal.targetUnit} / ${goal.period}\n'
      'Category: ${goal.category}';
}

class TrelloClient {
  TrelloClient({
    required this.apiKey,
    required this.token,
    http.Client? httpClient,
  })  : _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final String apiKey;
  final String token;
  final http.Client _http;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) _http.close();
  }

  Uri _uri(String path, [Map<String, String>? extra]) {
    return Uri.https('api.trello.com', path, {
      'key': apiKey,
      'token': token,
      ...?extra,
    });
  }

  Object _decode(http.Response response) {
    Object? data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }
    if (response.statusCode >= 400) {
      if (data is Map && data['message'] != null) {
        throw TrelloException(data['message'].toString());
      }
      throw TrelloException('Trello request failed (${response.statusCode}).');
    }
    return data ?? {};
  }

  Future<List<TrelloBoard>> boards() async {
    final data = _decode(await _http.get(_uri('/1/members/me/boards', {
      'filter': 'open',
      'fields': 'id,name,closed',
    })));
    return [
      for (final row in data as List)
        TrelloBoard.fromJson(Map<String, dynamic>.from(row as Map)),
    ].where((board) => !board.closed).toList();
  }

  Future<List<TrelloList>> lists(String boardId) async {
    final data = _decode(await _http.get(_uri('/1/boards/$boardId/lists', {
      'filter': 'open',
      'fields': 'id,name',
    })));
    return [
      for (final row in data as List)
        TrelloList.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }

  Future<TrelloList> ensureList({
    required String boardId,
    required String name,
  }) async {
    for (final list in await lists(boardId)) {
      if (list.name == name) return list;
    }
    final data = _decode(await _http.post(_uri('/1/lists', {
      'name': name,
      'idBoard': boardId,
    })));
    return TrelloList.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> createCard({
    required String listId,
    required String name,
    required String desc,
  }) async {
    _decode(await _http.post(_uri('/1/cards', {
      'idList': listId,
      'name': name,
      'desc': desc,
    })));
  }

  Future<int> pushTracker(Tracker tracker, {required String boardId}) async {
    if (tracker.goals.isEmpty) {
      throw TrelloException('This tracker has no goals to send.');
    }
    if (boardId.isEmpty) {
      throw TrelloException('Pick a Trello board in Profile first.');
    }
    // shortcut: re-send duplicates cards, store Trello card ids on goals if that gets noisy
    final list = await ensureList(boardId: boardId, name: tracker.title);
    for (final goal in tracker.goals) {
      await createCard(
        listId: list.id,
        name: goal.title,
        desc: trelloCardDesc(goal),
      );
    }
    return tracker.goals.length;
  }
}
