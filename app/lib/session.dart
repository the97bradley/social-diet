import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username.toLowerCase(),
        'display_name': displayName,
      },
    );
    if (response.session != null) {
      await refreshProfile();
    }
    return response;
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
