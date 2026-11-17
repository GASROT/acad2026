import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mensalidade_academia.dart';

class ApiException implements Exception {
  final String mensagem;
  const ApiException(this.mensagem);
  @override
  String toString() => mensagem;
}

class ApiService {
  static const urlConfigurada = String.fromEnvironment('API_BASE_URL');
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  ApiService({
    String? baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : baseUrl = (baseUrl ?? urlConfigurada).replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  Uri _uri(String rota) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const ApiException(
        'API não configurada. Os cadastros ficam neste aparelho.',
      );
    }
    return Uri.parse('$baseUrl$rota');
  }

  Future<http.Response> _request(
    Future<http.Response> Function() enviar,
  ) async {
    try {
      final resposta = await enviar().timeout(timeout);
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        return resposta;
      }
      if (resposta.statusCode == 400 || resposta.statusCode == 409) {
        throw const ApiException(
          'A API recusou os dados. Confira a matrícula e o valor.',
        );
      }
      throw const ApiException(
        'API indisponível. Tente sincronizar novamente mais tarde.',
      );
    } on TimeoutException {
      throw const ApiException(
        'A API demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Sem conexão com a API. Seus dados locais estão preservados.',
      );
    }
  }

  Future<List<MensalidadeAcademia>> buscarMensalidades() async {
    final response = await _request(() => _client.get(_uri('/mensalidades')));
    try {
      final dados = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return dados
          .map(
            (item) =>
                MensalidadeAcademia.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on FormatException {
      throw const ApiException('A API retornou dados inválidos.');
    } on TypeError {
      throw const ApiException('A API retornou um formato inesperado.');
    }
  }

  Future<void> salvarMensalidade(MensalidadeAcademia mensalidade) async {
    final response = await _request(
      () => _client.post(
        _uri('/mensalidades'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mensalidade.toJson()),
      ),
    );
    try {
      final confirmada = MensalidadeAcademia.fromJson(
        jsonDecode(response.body),
      );
      if (confirmada.aluno != mensalidade.aluno ||
          confirmada.id != mensalidade.id ||
          confirmada.matricula != mensalidade.matricula ||
          confirmada.mensalidadeCentavos != mensalidade.mensalidadeCentavos) {
        throw const FormatException('Confirmação divergente.');
      }
    } on FormatException {
      throw const ApiException('Não foi possível confirmar o cadastro remoto.');
    } on TypeError {
      throw const ApiException('A API retornou uma confirmação inválida.');
    }
  }

  Future<String> testarConexaoBanco() async {
    await _request(() => _client.get(_uri('/health')));
    return 'API e banco remoto disponíveis.';
  }

  void close() => _client.close();
}
