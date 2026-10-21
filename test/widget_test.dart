import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atlas_app/main.dart';
import 'package:atlas_app/widgets/atlas_logo_3d.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> loadApp(WidgetTester tester) async {
    await tester.pumpWidget(const AtlasLogApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('opens the logistics dashboard from the demo login', (
    tester,
  ) async {
    await loadApp(tester);

    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), 'Leona');
    await tester.ensureVisible(find.text('Entrar no ambiente de teste'));
    await tester.tap(find.text('Entrar no ambiente de teste'));
    await tester.pump();

    expect(find.text('Olá, Leona'), findsOneWidget);
    expect(find.text('Veículos ativos'), findsOneWidget);
    expect(find.text('Entregas em andamento'), findsOneWidget);
    expect(find.text('Atrasos'), findsOneWidget);
    expect(find.text('Em manutenção'), findsOneWidget);
    expect(find.text('CENTRAL DE OPERAÇÕES'), findsOneWidget);
  });

  testWidgets('navigates to the searchable order list', (tester) async {
    await loadApp(tester);
    await tester.ensureVisible(find.text('Entrar no ambiente de teste'));
    await tester.tap(find.text('Entrar no ambiente de teste'));
    await tester.pump();

    final ordersDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Pedidos'),
    );
    await tester.tap(ordersDestination);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pedidos e rastreamento'), findsOneWidget);
    expect(find.text('Buscar pedido, motorista ou placa...'), findsOneWidget);
  });

  testWidgets('keeps login, dashboard, and orders usable on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await loadApp(tester);
    expect(find.byType(AtlasLogo3D), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Entrar no ambiente de teste'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('Veículos ativos'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Pedidos'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('Pedidos e rastreamento'), findsOneWidget);
    expect(find.text('Buscar pedido, motorista ou placa...'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(360, 800),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    testWidgets('avoids layout overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await loadApp(tester);
      expect(find.text('Bem-vindo'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Entrar no ambiente de teste'));
      await tester.tap(find.text('Entrar no ambiente de teste'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('Veículos ativos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
