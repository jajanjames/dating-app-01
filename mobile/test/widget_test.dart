// FILE: test/widget_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jdate/main.dart';

void main() {
  testWidgets('Naam app renders Discover, Likes, Chats, and You tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JDateApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });
}
