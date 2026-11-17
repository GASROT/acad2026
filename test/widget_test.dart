import 'package:academia/database/app_database.dart';
import 'package:academia/main.dart';
import 'package:academia/models/aluno.dart';
import 'package:academia/repository/academia_repository.dart';
import 'package:academia/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late ApiService api;
  late AcademiaRepository repo;

  setUp(() async {
    sqfliteFfiInit();
    db = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      caminho: inMemoryDatabasePath,
    );
    api = ApiService(
      baseUrl: 'https://academia.test',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    repo = AcademiaRepository(local: db, api: api);
    await db.database;
  });
  tearDown(() async {
    await db.close();
    api.close();
  });

  testWidgets('dashboard, validação e cadastro offline atualizam a lista', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(AcademiaApp(repository: repo));
      expect(find.text('Academia'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsWidgets);
      await tester.tap(find.text('Gerenciar mensalidades'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova mensalidade'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar mensalidade'));
      await tester.tap(find.text('Salvar mensalidade'));
      await tester.pumpAndSettle();
      expect(
        find.text('Use letras, números ou hífen (até 30 caracteres).'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Aluno teste');
      await tester.enterText(find.byType(TextFormField).at(1), '0007');
      await tester.enterText(find.byType(TextFormField).at(2), '129,90');
      await tester.ensureVisible(find.text('Salvar mensalidade'));
      await tester.tap(find.text('Salvar mensalidade'));
      await tester.pumpAndSettle();
      expect(find.text('Matrícula: 0007'), findsOneWidget);
      expect(find.text('Aluno teste'), findsOneWidget);
      expect(find.text('Pendente de sincronização'), findsOneWidget);
      expect(find.text('Sincronizar pendentes'), findsOneWidget);
      final registros = await db.listar();
      expect(registros.single.mensalidadeCentavos, 12990);
      expect(registros.single.aluno, 'Aluno teste');
    });
  });

  testWidgets('aluno abre formulário com matrícula preenchida', (tester) async {
    await tester.runAsync(() async {
      await db.salvarAluno(const Aluno(nome: 'Aluno teste', matricula: '0012'));
      await tester.pumpWidget(AcademiaApp(repository: repo));
      await tester.tap(find.text('Alunos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aluno teste'));
      await tester.pumpAndSettle();
      final campo = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(campo.controller!.text, '0012');
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Aluno teste',
      );
    });
  });
}
