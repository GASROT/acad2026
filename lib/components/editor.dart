import 'package:flutter/material.dart';

class Editor extends StatelessWidget {
  final TextEditingController controlador;
  final String rotulo;
  final String? dica;
  final IconData? icone;
  final TextInputType tipoTeclado;
  final String? Function(String?)? validator;
  final int? maxLength;
  final bool enabled;

  const Editor({
    super.key,
    required this.controlador,
    required this.rotulo,
    this.dica,
    this.icone,
    this.tipoTeclado = TextInputType.text,
    this.validator,
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: TextFormField(
      controller: controlador,
      enabled: enabled,
      validator: validator,
      maxLength: maxLength,
      keyboardType: tipoTeclado,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        prefixIcon: icone == null ? null : Icon(icone),
      ),
    ),
  );
}
