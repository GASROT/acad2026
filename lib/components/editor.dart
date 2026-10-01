import 'package:flutter/material.dart';

class Editor extends StatelessWidget {
  final TextEditingController controlador;
  final String rotulo;
  final String dica;
  final IconData? icone;
  final TextInputType teclado;
  final TextCapitalization capitalizacao;

  const Editor({
    super.key,
    required this.controlador,
    required this.rotulo,
    required this.dica,
    this.icone,
    this.teclado = TextInputType.number,
    this.capitalizacao = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controlador,
        textCapitalization: capitalizacao,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(
          icon: icone != null ? Icon(icone) : null,
          labelText: rotulo,
          hintText: dica,
        ),
        keyboardType: teclado,
      ),
    );
  }
}
