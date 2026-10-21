import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_diet/theme.dart';
import 'package:social_diet/widgets.dart';

void main() {
  testWidgets('tracker card leads with remaining work', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: PulseTheme.dark(),
        home: Scaffold(
          body: TrackerSummaryCard(
            title: 'Beer night',
            headline: '2 beers left this week',
            progress: 0.5,
            meta: '1 goal · 2 people',
            memberInitials: const ['YO', 'AL'],
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Beer night'), findsOneWidget);
    expect(find.text('2 beers left this week'), findsOneWidget);
    expect(find.text('1 goal · 2 people'), findsOneWidget);
    expect(find.text('YO'), findsOneWidget);
    expect(find.text('AL'), findsOneWidget);

    await tester.tap(find.text('Beer night'));
    expect(tapped, isTrue);
  });
}
