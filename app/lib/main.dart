import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/shell.dart';
import 'session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  final session = SessionController(Supabase.instance.client);
  await session.bootstrap();
  runApp(SocialDietApp(session: session));
}

class SocialDietApp extends StatelessWidget {
  const SocialDietApp({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: session,
      child: MaterialApp(
        title: 'Social Diet',
        debugShowCheckedModeBanner: false,
        theme: PulseTheme.dark(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.isSignedIn) {
      return const AuthScreen();
    }
    if (session.loadingProfile && session.profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const AppShell();
  }
}
