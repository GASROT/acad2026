import 'dart:convert';
import 'dart:io';
import 'package:academia/database/app_database.dart';
import 'package:academia/models/aluno.dart';
import 'package:academia/models/mensalidade_academia.dart';
import 'package:academia/repository/academia_repository.dart';
import 'package:academia/repository/configuracao_persistencia.dart';
import 'package:academia/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory diretorio;
  late AppDatabase db;
  late ApiService api;
  late AcademiaRepository repo;
  late Map<String, Map<String, dynamic>> servidor;
  var online = true;
  var perderResposta = false;
  String? recusarId;
  var posts = 0;

  MensalidadeAcademia nova([String matricula = '0001']) =>
      MensalidadeAcademia.nova(
        aluno: 'Aluno teste',
        matricula: matricula,
        mensalidadeCentavos: 12990,
      );

  setUp(() async {
    sqfliteFfiInit();
    diretorio = await Directory.systemTemp.createTemp('academia-test-');
    db = AppDatabase(
      factory: databaseFactoryFfi,
      caminho: '${diretorio.path}/academia.db',
    );
    servidor = {};
    online = true;
    perderResposta = false;
    recusarId = null;
    posts = 0;
    api = ApiService(
      baseUrl: 'https://academia.test',
      client: MockClient((request) async {
        if (!online) throw http.ClientException('offline');
        if (request.method == 'GET') {
          return http.Response(jsonEncode(servidor.values.toList()), 200);
        }
        posts++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['id'] == recusarId) return http.Response('{}', 503);
        servidor[body['id'] as String] = body;
        if (perderResposta) throw http.ClientException('resposta perdida');
        return http.Response(jsonEncode(body), 201);
      }),
    );
    repo = AcademiaRepository(local: db, api: api);
  });

  tearDown(() async {
    api.close();
    await db.close();
    await diretorio.delete(recursive: true);
  });

  test('cadastro online persiste na API e no SQLite sincronizado', () async {
    final registro = nova();
    final resultado = await repo.salvarMensalidade(registro);
    expect(resultado.sincronizado, isTrue);
    expect(servidor[registro.id]?['mensalidade'], '129.90');
    expect(servidor[registro.id]?['aluno'], 'Aluno teste');
    expect((await db.listar()).single.sincronizado, isTrue);
    expect(await db.listar(somentePendentes: true), isEmpty);
  });

  test(
    'cadastro offline permanece após fechar e reabrir SQLite e sincroniza',
    () async {
      online = false;
      final registro = nova();
      expect((await repo.salvarMensalidade(registro)).sincronizado, isFalse);
      await db.close();
      db = AppDatabase(
        factory: databaseFactoryFfi,
        caminho: '${diretorio.path}/academia.db',
      );
      repo = AcademiaRepository(local: db, api: api);
      expect((await repo.buscarMensalidades()).single.id, registro.id);
      expect((await repo.buscarMensalidades()).single.aluno, 'Aluno teste');
      expect((await db.listar(somentePendentes: true)).length, 1);
      online = true;
      final resultado = await repo.sincronizarPendentes();
      expect(resultado.enviados, 1);
      expect(resultado.pendentes, 0);
      expect(servidor.length, 1);
      expect((await db.listar()).single.sincronizado, isTrue);
    },
  );

  test('resposta perdida e reenvios usam o mesmo id sem duplicar', () async {
    perderResposta = true;
    final registro = nova();
    await repo.salvarMensalidade(registro);
    expect(servidor.length, 1);
    expect((await db.listar()).single.sincronizado, isFalse);
    perderResposta = false;
    await Future.wait([
      repo.sincronizarPendentes(),
      repo.sincronizarPendentes(),
    ]);
    await repo.sincronizarPendentes();
    expect(posts, 2);
    expect(servidor.length, 1);
    expect((await db.listar()).single.sincronizado, isTrue);
  });

  test(
    'falha parcial mantém somente os registros não confirmados pendentes',
    () async {
      online = false;
      final a = nova('A');
      final b = nova('B');
      await repo.salvarMensalidade(a);
      await repo.salvarMensalidade(b);
      online = true;
      recusarId = a.id;
      final resultado = await repo.sincronizarPendentes();
      expect(resultado.enviados, 1);
      expect(resultado.pendentes, 1);
      expect(resultado.erro, isNotNull);
      expect((await db.listar(somentePendentes: true)).single.id, a.id);
    },
  );

  test(
    'GET importa remotos sem apagar ou sobrescrever os pendentes locais',
    () async {
      online = false;
      final pendente = nova();
      await repo.salvarMensalidade(pendente);
      final remoto = nova('REMOTO');
      servidor[remoto.id] = remoto.toJson();
      servidor[pendente.id] = pendente.toJson();
      online = true;
      await repo.atualizarDaApi();
      await repo.atualizarDaApi();
      expect((await db.listar()).length, 2);
      expect((await db.listar(somentePendentes: true)).single.id, pendente.id);
    },
  );

  test('falha no GET preserva registros e sinaliza erro', () async {
    await repo.salvarMensalidade(nova());
    online = false;
    await expectLater(repo.atualizarDaApi(), throwsA(isA<ApiException>()));
    expect((await repo.buscarMensalidades()).length, 1);
  });

  test('modos local e remoto respeitam a fonte escolhida', () async {
    final local = AcademiaRepository(
      local: db,
      api: api,
      origem: OrigemPersistencia.local,
    );
    await local.salvarMensalidade(nova());
    expect(posts, 0);
    final remoto = AcademiaRepository(
      local: db,
      api: api,
      origem: OrigemPersistencia.remota,
    );
    await remoto.salvarMensalidade(nova('REMOTO'));
    expect(posts, 1);
    expect((await db.listar()).length, 1);
    expect((await remoto.buscarMensalidades()).single.matricula, 'REMOTO');
    online = false;
    await expectLater(
      remoto.salvarMensalidade(nova()),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'migração SQLite mantém mensalidades anteriores e aceita nome do aluno',
    () async {
      final caminho = '${diretorio.path}/versao1.db';
      final antiga = await databaseFactoryFfi.openDatabase(
        caminho,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE mensalidades (id TEXT PRIMARY KEY NOT NULL, '
              'matricula TEXT NOT NULL, mensalidade_centavos INTEGER NOT NULL, '
              'sincronizado INTEGER NOT NULL DEFAULT 0)',
            );
          },
        ),
      );
      final registro = nova();
      final dados = registro.toMap()..remove('aluno');
      await antiga.insert('mensalidades', dados);
      await antiga.close();
      final atualizada = AppDatabase(
        factory: databaseFactoryFfi,
        caminho: caminho,
      );
      try {
        final preservado = (await atualizada.listar()).single;
        expect(preservado.id, registro.id);
        expect(preservado.mensalidadeCentavos, 12990);
        expect(preservado.sincronizado, isFalse);
        expect(preservado.aluno, isEmpty);
        await atualizada.salvar(nova('NOVA'));
        expect((await atualizada.listar()).first.aluno, 'Aluno teste');
      } finally {
        await atualizada.close();
      }
    },
  );

  test('alunos persistem com matrícula única e zeros preservados', () async {
    await repo.salvarAluno(const Aluno(nome: 'Aluno teste', matricula: '0001'));
    await db.close();
    expect((await repo.buscarAlunos()).single.matricula, '0001');
    await expectLater(
      repo.salvarAluno(const Aluno(nome: 'Outro', matricula: '0001')),
      throwsA(isA<DatabaseException>()),
    );
  });
}
