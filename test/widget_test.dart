import 'package:flutter_test/flutter_test.dart';

import 'package:sw2627_flutter_firebase_geargrid/main.dart';

void main() {
  testWidgets('GearGrid landing page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GearGridApp());

    expect(find.text('GearGrid'), findsWidgets);
    expect(find.text('Everything You Need'), findsOneWidget);
    expect(find.text('Explore Equipment'), findsOneWidget);
  });
}
