import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:social_diet/models.dart';
import 'package:social_diet/trello.dart';

TrackerGoal _goal({
  String title = 'Drink water',
  String category = 'lifestyle',
  double target = 8,
  String unit = 'glasses',
  String period = 'day',
}) {
  return TrackerGoal(
    id: 'g1',
    trackerId: 't1',
    title: title,
    category: category,
    kind: 'count',
    targetValue: target,
    targetUnit: unit,
    period: period,
    sortOrder: 0,
  );
}

Tracker _tracker({List<TrackerGoal>? goals}) {
  return Tracker(
    id: 't1',
    ownerId: 'u1',
    title: 'Hydration',
    description: '',
    icon: 'flag',
    color: 'lime',
    goals: goals ?? [_goal()],
    members: const [],
  );
}

void main() {
  test('connection is ready only with key, token, and board', () {
    const connection = TrelloConnection(
      userId: 'u1',
      apiKey: 'key-key-key-key',
      token: 'token-token-token',
      boardId: 'b1',
      boardName: 'Diet',
    );
    expect(connection.isReady, isTrue);
    expect(
      const TrelloConnection(
        userId: 'u1',
        apiKey: 'key-key-key-key',
        token: 'token-token-token',
        boardId: '',
        boardName: '',
      ).isReady,
      isFalse,
    );
  });

  test('authorize URL asks Trello for a never-expiring write token', () {
    expect(
      trelloAuthorizeUrl('abc123').toString(),
      'https://trello.com/1/authorize?expiration=never&name=Social+Diet&scope=read%2Cwrite&response_type=token&key=abc123',
    );
  });

  test('card description carries target and category', () {
    expect(
      trelloCardDesc(_goal()),
      'Social Diet goal\nTarget: 8 glasses / day\nCategory: lifestyle',
    );
  });

  test('boards() drops closed boards and parses open ones', () async {
    final client = TrelloClient(
      apiKey: 'k',
      token: 't',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/1/members/me/boards');
        expect(request.url.queryParameters['key'], 'k');
        return http.Response(
          '[{"id":"b1","name":"Diet","closed":false},{"id":"b2","name":"Old","closed":true}]',
          200,
        );
      }),
    );
    final boards = await client.boards();
    expect(boards.map((board) => board.id), ['b1']);
    expect(boards.single.name, 'Diet');
  });

  test('pushTracker reuses a same-named list and posts one card per goal', () async {
    final posts = <Uri>[];
    final client = TrelloClient(
      apiKey: 'k',
      token: 't',
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response('[{"id":"l1","name":"Hydration"}]', 200);
        }
        posts.add(request.url);
        return http.Response('{"id":"c1","name":"${request.url.queryParameters['name']}"}', 200);
      }),
    );

    final count = await client.pushTracker(
      _tracker(goals: [
        _goal(title: 'Water'),
        _goal(title: 'Walk', category: 'fitness', target: 1, unit: 'sessions', period: 'day'),
      ]),
      boardId: 'b1',
    );

    expect(count, 2);
    expect(posts.length, 2);
    expect(posts.every((uri) => uri.path == '/1/cards'), isTrue);
    expect(posts.map((uri) => uri.queryParameters['name']), ['Water', 'Walk']);
    expect(posts.first.queryParameters['idList'], 'l1');
    expect(posts.first.queryParameters['desc'], contains('glasses'));
  });

  test('pushTracker creates a list when the board has none with that title', () async {
    var lists = 0;
    final client = TrelloClient(
      apiKey: 'k',
      token: 't',
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/lists') && request.method == 'GET') {
          return http.Response('[]', 200);
        }
        if (request.url.path == '/1/lists' && request.method == 'POST') {
          lists += 1;
          expect(request.url.queryParameters['name'], 'Hydration');
          expect(request.url.queryParameters['idBoard'], 'b1');
          return http.Response('{"id":"l-new","name":"Hydration"}', 200);
        }
        expect(request.url.queryParameters['idList'], 'l-new');
        return http.Response('{"id":"c1"}', 200);
      }),
    );

    expect(await client.pushTracker(_tracker(), boardId: 'b1'), 1);
    expect(lists, 1);
  });

  test('pushTracker refuses an empty tracker or missing board', () async {
    final client = TrelloClient(
      apiKey: 'k',
      token: 't',
      httpClient: MockClient((request) async => http.Response('[]', 200)),
    );
    expect(
      () => client.pushTracker(_tracker(goals: const []), boardId: 'b1'),
      throwsA(isA<TrelloException>()),
    );
    expect(
      () => client.pushTracker(_tracker(), boardId: ''),
      throwsA(isA<TrelloException>()),
    );
  });

  test('Trello error JSON becomes TrelloException', () async {
    final client = TrelloClient(
      apiKey: 'k',
      token: 't',
      httpClient: MockClient((request) async {
        return http.Response('{"message":"invalid token"}', 401);
      }),
    );
    expect(
      () => client.boards(),
      throwsA(isA<TrelloException>().having((error) => error.message, 'message', 'invalid token')),
    );
  });
}
