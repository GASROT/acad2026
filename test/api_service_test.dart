import 'dart:async';
import 'dart:convert';
import 'package:academia/models/mensalidade_academia.dart';
import 'package:academia/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('URL ausente produz erro controlado sem enviar requisição', () async {
    final api = ApiService(
      baseUrl: '',
      client: MockClient((_) async => fail('Não deveria enviar')),
    );
    addTearDown(api.close);
    await expectLater(api.buscarMensalidades(), throwsA(isA<ApiException>()));
  });

  test('timeout não bloqueia cadastro indefinidamente', () async {
    final api = ApiService(
      baseUrl: 'https://academia.test',
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(api.close);
    await expectLater(api.buscarMensalidades(), throwsA(isA<ApiException>()));
  });

  test('resposta de POST divergente nunca confirma sincronização', () async {
    final original = MensalidadeAcademia.nova(
      matricula: '001',
      mensalidadeCentavos: 100,
    );
    final outro = MensalidadeAcademia.nova(
      matricula: '002',
      mensalidadeCentavos: 100,
    );
    final api = ApiService(
      baseUrl: 'https://academia.test',
      client: MockClient(
        (_) async => http.Response(jsonEncode(outro.toJson()), 201),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.salvarMensalidade(original),
      throwsA(isA<ApiException>()),
    );
  });

  test('dados malformados da API resultam em erro controlado', () async {
    for (final body in ['<html>erro</html>', '{}', '[{}]', '[{"id":12}]']) {
      final api = ApiService(
        baseUrl: 'https://academia.test',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(api.buscarMensalidades(), throwsA(isA<ApiException>()));
      api.close();
    }
  });
}
