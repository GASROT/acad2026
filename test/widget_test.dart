import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academia/main.dart';

void main() {
  testWidgets('cadastra mensalidade da academia em memória', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AcademiaApp());

    expect(find.text('GUILHERME ARAUJO SILVA'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Nova Mensalidade'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'ANA SOUZA');
    await tester.enterText(find.byType(TextField).at(1), '120,50');
    await tester.enterText(find.byType(TextField).at(2), '45678');
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('ANA SOUZA'), findsOneWidget);
    expect(find.text('Matrícula: 45678 • R$ 120,50'), findsOneWidget);
  });
}
