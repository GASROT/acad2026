class Aluno {
  final String nome;
  final String matricula;

  const Aluno({required this.nome, required this.matricula});

  Map<String, Object?> toMap() => {'nome': nome, 'matricula': matricula};

  factory Aluno.fromMap(Map<String, Object?> map) =>
      Aluno(nome: map['nome'] as String, matricula: map['matricula'] as String);
}
