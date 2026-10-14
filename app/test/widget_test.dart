import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_diet/screens/auth_screen.dart';

void main() {
  testWidgets('auth screen offers sign in and create account', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(),
      ),
    );

    expect(find.text('Social Diet'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });
}
