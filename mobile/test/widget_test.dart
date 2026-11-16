// FILE: test/widget_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jdate/main.dart';

void main() {
  testWidgets(
      'Naam app launches on Welcome screen and transitions to Step 01 / 08 on Let\'s begin',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JDateApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text("Let's begin"), findsOneWidget);
    expect(find.text('Meet Malayali singles who get you.'), findsOneWidget);

    await tester.tap(find.text("Let's begin"));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('01 / 08'), findsOneWidget);
    expect(find.text('Your number?'), findsOneWidget);
  });
}
