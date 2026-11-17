import 'package:flutter/material.dart';
import '../../components/editor.dart';
import '../../models/aluno.dart';
import '../../models/mensalidade_academia.dart';
import '../../repository/academia_repository.dart';

class FormularioAluno extends StatefulWidget {
  final AcademiaRepository repository;
  const FormularioAluno({super.key, required this.repository});
  @override
  State<FormularioAluno> createState() => _FormularioAlunoState();
}

class _FormularioAlunoState extends State<FormularioAluno> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _matricula = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _matricula.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando || !_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await widget.repository.salvarAluno(
        Aluno(nome: _nome.text.trim(), matricula: _matricula.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar. Verifique se a matrícula já está cadastrada.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_salvando,
    child: Scaffold(
      appBar: AppBar(title: const Text('Novo aluno')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Salve os alunos neste aparelho para preencher a matrícula com um toque.',
                    ),
                    const SizedBox(height: 16),
                    Editor(
                      controlador: _nome,
                      rotulo: 'Nome do aluno',
                      icone: Icons.person_outline,
                      maxLength: 100,
                      enabled: !_salvando,
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Informe o nome do aluno.'
                          : null,
                    ),
                    Editor(
                      controlador: _matricula,
                      rotulo: 'Matrícula',
                      dica: 'Ex.: 2026-001',
                      icone: Icons.badge_outlined,
                      maxLength: 30,
                      enabled: !_salvando,
                      validator: (v) =>
                          MensalidadeAcademia.matriculaValida(v ?? '')
                          ? null
                          : 'Use letras, números ou hífen.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _salvando ? null : _salvar,
                      child: Text(_salvando ? 'Salvando…' : 'Salvar aluno'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
