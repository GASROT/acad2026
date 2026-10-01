class MensalidadeAcademia {
  final String aluno;
  final double valor;
  final int matricula;

  MensalidadeAcademia({
    required this.aluno,
    required this.valor,
    required this.matricula,
  });

  @override
  String toString() {
    return 'MensalidadeAcademia{aluno: $aluno, valor: $valor, matricula: $matricula}';
  }
}
