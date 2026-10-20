import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atlas_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens the logistics dashboard from the demo login', (
    tester,
  ) async {
    await tester.pumpWidget(const AtlasLogApp());
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo'), findsOneWidget);
    await tester.ensureVisible(find.text('Entrar no ambiente de teste'));
    await tester.tap(find.text('Entrar no ambiente de teste'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Leona'), findsOneWidget);
    expect(find.text('Total de envios'), findsOneWidget);
    expect(find.text('CENTRAL DE OPERAÇÕES'), findsOneWidget);
  });

  testWidgets('navigates to the searchable order list', (tester) async {
    await tester.pumpWidget(const AtlasLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar no ambiente de teste'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedidos').last);
    await tester.pumpAndSettle();

    expect(find.text('Pedidos e rastreamento'), findsOneWidget);
    expect(find.text('Buscar código, cliente ou destino...'), findsOneWidget);
  });
}
