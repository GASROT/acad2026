import 'package:flutter/material.dart';
import '../../components/editor.dart';
import '../../models/mensalidade_academia.dart';
import '../../repository/academia_repository.dart';

class FormularioMensalidade extends StatefulWidget {
  final AcademiaRepository repository;
  final String? matricula;
  final String? aluno;
  const FormularioMensalidade({
    super.key,
    required this.repository,
    this.matricula,
    this.aluno,
  });
  @override
  State<FormularioMensalidade> createState() => _FormularioMensalidadeState();
}

class _FormularioMensalidadeState extends State<FormularioMensalidade> {
  final _form = GlobalKey<FormState>();
  late final _matricula = TextEditingController(text: widget.matricula);
  late final _aluno = TextEditingController(text: widget.aluno);
  final _valor = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _matricula.dispose();
    _aluno.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando || !_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final resultado = await widget.repository.salvarMensalidade(
        MensalidadeAcademia.nova(
          aluno: _aluno.text.trim(),
          matricula: _matricula.text.trim(),
          mensalidadeCentavos: MensalidadeAcademia.lerCentavos(_valor.text)!,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(resultado);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar. Confira a conexão ou o armazenamento e tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_salvando,
    child: Scaffold(
      appBar: AppBar(title: const Text('Nova mensalidade')),
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
                    const Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Color(0xFF2346B4),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Informe o aluno, a matrícula e o valor da mensalidade.',
                    ),
                    const SizedBox(height: 12),
                    Editor(
                      controlador: _aluno,
                      rotulo: 'Aluno',
                      dica: 'Nome completo do aluno',
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
                          : 'Use letras, números ou hífen (até 30 caracteres).',
                    ),
                    Editor(
                      controlador: _valor,
                      rotulo: 'Mensalidade (R\$)',
                      dica: 'Ex.: 129,90',
                      icone: Icons.payments_outlined,
                      enabled: !_salvando,
                      tipoTeclado: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) =>
                          MensalidadeAcademia.lerCentavos(v ?? '') != null
                          ? null
                          : 'Informe um valor positivo com até duas casas decimais.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _salvando ? 'Salvando…' : 'Salvar mensalidade',
                      ),
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
