import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_eve/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Construir la app
    await tester.pumpWidget(const SistemaEveApp());

    // Verificar que el título existe
    expect(find.text('Sistema EVE'), findsOneWidget);
  });
}
