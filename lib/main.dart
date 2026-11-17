import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database/app_database.dart';
import 'repository/academia_repository.dart';
import 'repository/configuracao_persistencia.dart';
import 'screens/dashboard.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase local;
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    final diretorio = await getApplicationSupportDirectory();
    await diretorio.create(recursive: true);
    local = AppDatabase(
      factory: databaseFactoryFfi,
      caminho: path.join(diretorio.path, 'academia.db'),
    );
  } else {
    local = AppDatabase();
  }
  runApp(
    AcademiaApp(
      repository: AcademiaRepository(
        local: local,
        api: ApiService(),
        origem: ConfiguracaoPersistencia.origem,
      ),
    ),
  );
}

class AcademiaApp extends StatelessWidget {
  final AcademiaRepository repository;
  const AcademiaApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Academia',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2346B4),
        primary: const Color(0xFF2346B4),
        secondary: const Color(0xFFB34A19),
        surface: const Color(0xFFF7F8FC),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFFF7F8FC),
        foregroundColor: Color(0xFF192340),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
      ),
    ),
    home: Dashboard(repository: repository),
  );
}
