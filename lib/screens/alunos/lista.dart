import 'package:flutter/material.dart';
import '../../models/aluno.dart';
import '../../repository/academia_repository.dart';
import '../mensalidades/formulario.dart';
import 'formulario.dart';

class ListaAlunos extends StatefulWidget {
  final AcademiaRepository repository;
  const ListaAlunos({super.key, required this.repository});
  @override
  State<ListaAlunos> createState() => _ListaAlunosState();
}

class _ListaAlunosState extends State<ListaAlunos> {
  late Future<List<Aluno>> _alunos;
  @override
  void initState() {
    super.initState();
    _alunos = widget.repository.buscarAlunos();
  }

  Future<void> _novo() async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioAluno(repository: widget.repository),
      ),
    );
    if (!mounted) return;
    setState(() => _alunos = widget.repository.buscarAlunos());
    if (salvo == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aluno salvo neste aparelho.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alunos')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder<List<Aluno>>(
            future: _alunos,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(
                      () => _alunos = widget.repository.buscarAlunos(),
                    ),
                    child: const Text(
                      'Falha ao carregar alunos. Tentar novamente',
                    ),
                  ),
                );
              }
              final alunos = snapshot.data!;
              if (alunos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Cadastre seu primeiro aluno para facilitar o lançamento de mensalidades.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: alunos.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(alunos[i].nome),
                  subtitle: Text('Matrícula: ${alunos[i].matricula}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final resultado = await Navigator.of(context)
                        .push<ResultadoCadastro>(
                          MaterialPageRoute(
                            builder: (_) => FormularioMensalidade(
                              repository: widget.repository,
                              matricula: alunos[i].matricula,
                              aluno: alunos[i].nome,
                            ),
                          ),
                        );
                    if (!context.mounted || resultado == null) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(resultado.mensagem)));
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _novo,
      icon: const Icon(Icons.person_add_outlined),
      label: const Text('Novo aluno'),
    ),
  );
}
