import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/aluno.dart';
import '../models/mensalidade_academia.dart';

class AppDatabase {
  final DatabaseFactory factory;
  final String? caminho;
  Future<Database>? _database;

  AppDatabase({DatabaseFactory? factory, this.caminho})
    : factory = factory ?? databaseFactory;

  Future<Database> get database => _database ??= _abrir();

  Future<Database> _abrir() async {
    try {
      // Preserva bank.db: dados bancários não são mensalidades.
      final path =
          caminho ?? join(await factory.getDatabasesPath(), 'academia.db');
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute(
                "ALTER TABLE mensalidades ADD COLUMN aluno TEXT NOT NULL DEFAULT ''",
              );
            }
          },
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE mensalidades (
              id TEXT PRIMARY KEY NOT NULL,
              matricula TEXT NOT NULL,
              aluno TEXT NOT NULL DEFAULT '',
              mensalidade_centavos INTEGER NOT NULL
                CHECK(mensalidade_centavos > 0 AND mensalidade_centavos <= 9999999999),
              sincronizado INTEGER NOT NULL DEFAULT 0 CHECK(sincronizado IN (0, 1))
            )
          ''');
            await db.execute(
              'CREATE INDEX idx_mensalidades_sync ON mensalidades(sincronizado)',
            );
            await db.execute('''
            CREATE TABLE alunos (
              matricula TEXT PRIMARY KEY NOT NULL,
              nome TEXT NOT NULL
            )
          ''');
          },
        ),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  Future<void> salvar(MensalidadeAcademia mensalidade) async {
    await (await database).insert('mensalidades', mensalidade.toMap());
  }

  Future<List<MensalidadeAcademia>> listar({
    bool somentePendentes = false,
  }) async {
    final rows = await (await database).query(
      'mensalidades',
      where: somentePendentes ? 'sincronizado = ?' : null,
      whereArgs: somentePendentes ? [0] : null,
      orderBy: 'rowid DESC',
    );
    return rows.map(MensalidadeAcademia.fromMap).toList();
  }

  Future<void> marcarSincronizada(String id) async {
    await (await database).update(
      'mensalidades',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> importar(List<MensalidadeAcademia> mensalidades) async {
    await (await database).transaction((txn) async {
      for (final mensalidade in mensalidades) {
        // Um GET nunca sobrescreve um cadastro local pendente.
        await txn.insert(
          'mensalidades',
          mensalidade.comoSincronizada().toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<void> salvarAluno(Aluno aluno) async {
    await (await database).insert('alunos', aluno.toMap());
  }

  Future<List<Aluno>> listarAlunos() async {
    final rows = await (await database).query(
      'alunos',
      orderBy: 'nome COLLATE NOCASE',
    );
    return rows.map(Aluno.fromMap).toList();
  }

  Future<void> close() async {
    if (_database != null) await (await _database!).close();
    _database = null;
  }
}
