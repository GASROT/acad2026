import 'package:flutter/material.dart';

import '../../components/editor.dart';
import '../../models/mensalidade_academia.dart';

class FormularioMensalidade extends StatefulWidget {
  const FormularioMensalidade({super.key});

  @override
  State<FormularioMensalidade> createState() => _FormularioMensalidadeState();
}

class _FormularioMensalidadeState extends State<FormularioMensalidade> {
  final _controladorCampoAluno = TextEditingController();
  final _controladorCampoValor = TextEditingController();
  final _controladorCampoMatricula = TextEditingController();

  @override
  void dispose() {
    _controladorCampoAluno.dispose();
    _controladorCampoValor.dispose();
    _controladorCampoMatricula.dispose();
    super.dispose();
  }

  void _criaMensalidade() {
    final aluno = _controladorCampoAluno.text.trim();
    final valor = double.tryParse(
      _controladorCampoValor.text.trim().replaceAll(',', '.'),
    );
    final matricula = int.tryParse(_controladorCampoMatricula.text.trim());

    if (aluno.isEmpty ||
        valor == null ||
        valor <= 0 ||
        matricula == null ||
        matricula <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha aluno, valor válido e matrícula numérica.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      MensalidadeAcademia(aluno: aluno, valor: valor, matricula: matricula),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Mensalidade')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Editor(
              controlador: _controladorCampoAluno,
              rotulo: 'Aluno',
              dica: 'Nome completo do aluno',
              icone: Icons.person,
              teclado: TextInputType.text,
              capitalizacao: TextCapitalization.words,
            ),
            Editor(
              controlador: _controladorCampoValor,
              rotulo: 'Valor da mensalidade',
              dica: 'Ex.: 99,90',
              icone: Icons.attach_money,
              teclado: const TextInputType.numberWithOptions(decimal: true),
            ),
            Editor(
              controlador: _controladorCampoMatricula,
              rotulo: 'Matrícula',
              dica: 'Ex.: 12345',
              icone: Icons.badge,
              teclado: TextInputType.number,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _criaMensalidade,
                child: const Text('Cadastrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
