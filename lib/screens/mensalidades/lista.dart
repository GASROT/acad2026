import 'package:flutter/material.dart';

import '../../models/mensalidade_academia.dart';
import 'formulario.dart';

class ListaMensalidades extends StatefulWidget {
  const ListaMensalidades({super.key});

  @override
  State<ListaMensalidades> createState() => _ListaMensalidadesState();
}

class _ListaMensalidadesState extends State<ListaMensalidades> {
  final List<MensalidadeAcademia> _mensalidades = [
    MensalidadeAcademia(
      aluno: 'GUILHERME ARAUJO SILVA',
      valor: 99.90,
      matricula: 12345,
    ),
  ];

  Future<void> _cadastrarMensalidade() async {
    final mensalidadeRecebida = await Navigator.push<MensalidadeAcademia>(
      context,
      MaterialPageRoute(builder: (context) => const FormularioMensalidade()),
    );

    if (mensalidadeRecebida == null || !mounted) return;

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _mensalidades.add(mensalidadeRecebida);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensalidades da Academia')),
      body: ListView.builder(
        itemCount: _mensalidades.length,
        itemBuilder: (context, indice) =>
            ItemMensalidade(mensalidade: _mensalidades[indice]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _cadastrarMensalidade,
        tooltip: 'Cadastrar nova mensalidade',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ItemMensalidade extends StatelessWidget {
  final MensalidadeAcademia mensalidade;

  const ItemMensalidade({super.key, required this.mensalidade});

  String get _valorFormatado =>
      'R\$ ${mensalidade.valor.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(mensalidade.aluno),
        subtitle: Text('Matrícula: ${mensalidade.matricula} • $_valorFormatado'),
      ),
    );
  }
}
