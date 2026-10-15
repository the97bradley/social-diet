import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'models.dart';
import 'repo.dart';

class SessionController extends ChangeNotifier {
  SessionController(this.client) : repo = DietRepo(client) {
    _authSub = client.auth.onAuthStateChange.listen((state) {
      _user = state.session?.user;
      if (_user == null) {
        profile = null;
        notifyListeners();
        return;
      }
      refreshProfile();
    });
    _user = client.auth.currentUser;
  }

  final SupabaseClient client;
  final DietRepo repo;
  late final StreamSubscription<AuthState> _authSub;

  User? _user;
  Profile? profile;
  bool loadingProfile = false;
  String? error;

  User? get user => _user;
  bool get isSignedIn => _user != null;

  Future<void> bootstrap() async {
    _user = client.auth.currentUser;
    if (_user != null) {
      await refreshProfile();
    } else {
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    loadingProfile = true;
    notifyListeners();
    try {
      profile = await repo.myProfile();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
    await refreshProfile();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/create-account'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username.toLowerCase(),
        'display_name': displayName,
      }),
    );
    if (response.statusCode >= 400) {
      throw AuthException(_functionError(_decodeBody(response.body)));
    }
    await signIn(email, password);
    return AuthResponse(
      session: client.auth.currentSession,
      user: client.auth.currentUser,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    profile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

Object? _decodeBody(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return body;
  }
}

String _functionError(Object? data) {
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  if (data is String && data.trim().isNotEmpty) {
    return data;
  }
  return 'Could not create the account.';
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope missing');
    return scope!.notifier!;
  }
}
