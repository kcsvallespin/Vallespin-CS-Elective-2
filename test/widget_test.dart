// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_project/main.dart';

void main() {
  testWidgets('home displays the product catalog', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MORROW MOBILE'), findsOneWidget);
    expect(find.text('Pocket Pro'), findsOneWidget);
    expect(find.text('Studio Max'), findsOneWidget);
  });
}
