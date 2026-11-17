import 'package:academia/models/mensalidade_academia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valores brasileiros são convertidos sem perder centavos', () {
    expect(MensalidadeAcademia.lerCentavos('129,90'), 12990);
    expect(MensalidadeAcademia.lerCentavos('1.234,56'), 123456);
    expect(MensalidadeAcademia.lerCentavos('0.01'), 1);
    expect(MensalidadeAcademia.lerCentavos('20'), 2000);
    expect(MensalidadeAcademia.lerCentavos('99999999.99'), 9999999999);
    for (final valor in [
      '0',
      '-1',
      'NaN',
      'Infinity',
      '10,001',
      '1e2',
      '',
      '100000000',
      '1.23,45',
    ]) {
      expect(MensalidadeAcademia.lerCentavos(valor), isNull, reason: valor);
    }
  });

  test('matrícula preserva zeros e UUID acompanha o mesmo cadastro', () {
    final registro = MensalidadeAcademia.nova(
      matricula: '0001',
      mensalidadeCentavos: 9990,
    );
    final recebido = MensalidadeAcademia.fromJson(registro.toJson());
    expect(recebido.matricula, '0001');
    expect(recebido.id, registro.id);
    expect(recebido.mensalidadeCentavos, 9990);
    expect(recebido.sincronizado, isTrue);
    expect(MensalidadeAcademia.fromMap(registro.toMap()).sincronizado, isFalse);
    expect(MensalidadeAcademia.matriculaValida('a-001'), isTrue);
    expect(MensalidadeAcademia.matriculaValida('a 001'), isFalse);
  });
}
