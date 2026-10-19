import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_app/main.dart';

void main() {
  testWidgets('opens the admin dashboard from the demo login', (tester) async {
    await tester.pumpWidget(const AtlasLogApp());

    expect(find.text('Bem-vindo'), findsOneWidget);
    await tester.ensureVisible(find.text('Entrar no ambiente de teste'));
    await tester.tap(find.text('Entrar no ambiente de teste'));
    await tester.pumpAndSettle();

    expect(find.textContaining(', Leona'), findsOneWidget);
    expect(find.text('Acesso rápido'), findsOneWidget);
    expect(find.text('Frota ativa'), findsOneWidget);
  });
}
