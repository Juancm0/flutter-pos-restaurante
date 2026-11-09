import 'package:flutter_test/flutter_test.dart';
import 'package:pos_restaurante/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Construir la app
    await tester.pumpWidget(const PosRestauranteApp());

    // Verificar que el título existe
    expect(find.text('POS Restaurante'), findsOneWidget);
  });
}
