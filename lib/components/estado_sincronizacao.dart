import 'package:flutter/material.dart';

class EstadoSincronizacao extends StatelessWidget {
  final bool sincronizado;
  const EstadoSincronizacao({super.key, required this.sincronizado});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Icon(
        sincronizado ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
        size: 18,
        color: sincronizado ? const Color(0xFF276140) : const Color(0xFF8A4700),
      ),
      Text(
        sincronizado ? 'Sincronizada' : 'Pendente de sincronização',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
