import 'package:uuid/uuid.dart';

class MensalidadeAcademia {
  final String id;
  final String matricula;
  final String aluno;
  final int mensalidadeCentavos;
  final bool sincronizado;

  const MensalidadeAcademia({
    required this.id,
    required this.matricula,
    required this.mensalidadeCentavos,
    this.aluno = '',
    this.sincronizado = false,
  });

  factory MensalidadeAcademia.nova({
    required String matricula,
    required int mensalidadeCentavos,
    String aluno = '',
  }) => MensalidadeAcademia(
    id: const Uuid().v4(),
    matricula: matricula.trim(),
    aluno: aluno.trim(),
    mensalidadeCentavos: mensalidadeCentavos,
  );

  static bool matriculaValida(String valor) =>
      RegExp(r'^[a-zA-Z0-9-]{1,30}$').hasMatch(valor.trim());

  // Dinheiro em centavos evita arredondamento binário.
  static int? lerCentavos(String texto) {
    var valor = texto.trim();
    if (RegExp(r'^\d{1,3}(\.\d{3})+,\d{1,2}$').hasMatch(valor)) {
      valor = valor.replaceAll('.', '');
    }
    valor = valor.replaceAll(',', '.');
    if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(valor)) return null;
    final partes = valor.split('.');
    final centavos =
        int.parse(partes[0]) * 100 +
        (partes.length == 2 ? int.parse(partes[1].padRight(2, '0')) : 0);
    return centavos > 0 && centavos <= 9999999999 ? centavos : null;
  }

  String get mensalidadeDecimal =>
      '${mensalidadeCentavos ~/ 100}.${(mensalidadeCentavos % 100).toString().padLeft(2, '0')}';

  MensalidadeAcademia comoSincronizada() => MensalidadeAcademia(
    id: id,
    matricula: matricula,
    aluno: aluno,
    mensalidadeCentavos: mensalidadeCentavos,
    sincronizado: true,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'aluno': aluno,
    'matricula': matricula,
    'mensalidade_centavos': mensalidadeCentavos,
    'sincronizado': sincronizado ? 1 : 0,
  };

  factory MensalidadeAcademia.fromMap(Map<String, Object?> map) =>
      MensalidadeAcademia(
        id: map['id'] as String,
        aluno: map['aluno'] as String? ?? '',
        matricula: map['matricula'] as String,
        mensalidadeCentavos: map['mensalidade_centavos'] as int,
        sincronizado: map['sincronizado'] == 1,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'aluno': aluno,
    'matricula': matricula,
    'mensalidade': mensalidadeDecimal,
  };

  factory MensalidadeAcademia.fromJson(Map<String, dynamic> json) {
    final centavos = lerCentavos(json['mensalidade'].toString());
    final id = json['id'];
    final matricula = json['matricula'];
    final aluno = json['aluno'] ?? '';
    if (centavos == null ||
        id is! String ||
        !Uuid.isValidUUID(fromString: id) ||
        matricula is! String ||
        !matriculaValida(matricula) ||
        aluno is! String ||
        aluno.length > 100) {
      throw const FormatException('Mensalidade inválida recebida da API.');
    }
    return MensalidadeAcademia(
      id: id,
      matricula: matricula,
      aluno: aluno,
      mensalidadeCentavos: centavos,
      sincronizado: true,
    );
  }
}
