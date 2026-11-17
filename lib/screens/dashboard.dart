import 'package:flutter/material.dart';
import '../repository/academia_repository.dart';
import 'alunos/lista.dart';
import 'mensalidades/lista.dart';

class Dashboard extends StatelessWidget {
  final AcademiaRepository repository;
  const Dashboard({super.key, required this.repository});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Academia')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Colors.white),
                    SizedBox(height: 28),
                    Text(
                      'Mais foco no treino.\nTudo em dia.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Organize as mensalidades da sua academia por matrícula.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                icon: const Icon(Icons.fitness_center),
                label: const Text('Gerenciar mensalidades'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListaMensalidades(repository: repository),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 52),
                ),
                icon: const Icon(Icons.people_outline),
                label: const Text('Alunos'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListaAlunos(repository: repository),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cloud_upload_outlined),
                title: Text('Cadastre mesmo sem conexão'),
                subtitle: Text(
                  'As mensalidades pendentes ficam neste aparelho. '
                  'Use “Sincronizar pendentes” quando a conexão voltar.',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
