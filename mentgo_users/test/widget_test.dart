import 'package:flutter_test/flutter_test.dart';
import 'package:mentgo_users/main.dart';

void main() {
  testWidgets('Login and navigation to Register screen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MentalGoApp());

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Regístrate'), findsOneWidget);

    await tester.ensureVisible(find.text('Regístrate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Cuenta'), findsOneWidget);
    expect(find.text('Cédula'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });
}
