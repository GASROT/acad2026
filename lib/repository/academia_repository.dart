import '../database/app_database.dart';
import '../models/aluno.dart';
import '../models/mensalidade_academia.dart';
import '../services/api_service.dart';
import 'configuracao_persistencia.dart';

class ResultadoCadastro {
  final bool sincronizado;
  final String mensagem;
  const ResultadoCadastro(this.sincronizado, this.mensagem);
}

class ResultadoSincronizacao {
  final int enviados;
  final int pendentes;
  final String? erro;
  const ResultadoSincronizacao(this.enviados, this.pendentes, this.erro);
}

class AcademiaRepository {
  final AppDatabase local;
  final ApiService api;
  final OrigemPersistencia origem;
  Future<ResultadoSincronizacao>? _sincronizacao;

  AcademiaRepository({
    required this.local,
    required this.api,
    this.origem = OrigemPersistencia.offlineFirst,
  });

  Future<List<MensalidadeAcademia>> buscarMensalidades() async {
    if (origem == OrigemPersistencia.remota) return api.buscarMensalidades();
    return local.listar();
  }

  Future<void> atualizarDaApi() async {
    final registros = await api.buscarMensalidades();
    await local.importar(registros);
  }

  Future<ResultadoCadastro> salvarMensalidade(
    MensalidadeAcademia mensalidade,
  ) async {
    if (mensalidade.aluno.length > 100 ||
        !MensalidadeAcademia.matriculaValida(mensalidade.matricula) ||
        mensalidade.mensalidadeCentavos <= 0 ||
        mensalidade.mensalidadeCentavos > 9999999999) {
      throw ArgumentError('Matrícula ou mensalidade inválida.');
    }
    if (origem == OrigemPersistencia.remota) {
      await api.salvarMensalidade(mensalidade);
      return const ResultadoCadastro(true, 'Mensalidade salva na API.');
    }
    // Persiste a fila antes do HTTP para sobreviver ao encerramento do app.
    await local.salvar(mensalidade);
    if (origem == OrigemPersistencia.local) {
      return const ResultadoCadastro(
        false,
        'Mensalidade salva neste aparelho.',
      );
    }
    try {
      await api.salvarMensalidade(mensalidade);
    } on ApiException catch (erro) {
      return ResultadoCadastro(
        false,
        'Salva neste aparelho, pendente de sincronização. ${erro.mensagem}',
      );
    }
    try {
      await local.marcarSincronizada(mensalidade.id);
    } catch (_) {
      return const ResultadoCadastro(
        false,
        'Enviada à API. Sincronize novamente para atualizar o estado local.',
      );
    }
    return const ResultadoCadastro(true, 'Mensalidade salva e sincronizada.');
  }

  // Chamadas simultâneas compartilham o mesmo envio da fila.
  Future<ResultadoSincronizacao> sincronizarPendentes() => _sincronizacao ??=
      _sincronizar().whenComplete(() => _sincronizacao = null);

  Future<ResultadoSincronizacao> _sincronizar() async {
    final pendentes = await local.listar(somentePendentes: true);
    var enviados = 0;
    String? erro;
    for (final mensalidade in pendentes) {
      try {
        await api.salvarMensalidade(mensalidade);
        await local.marcarSincronizada(mensalidade.id);
        enviados++;
      } on ApiException catch (falha) {
        erro = falha.mensagem;
      }
    }
    return ResultadoSincronizacao(
      enviados,
      (await local.listar(somentePendentes: true)).length,
      erro,
    );
  }

  Future<List<Aluno>> buscarAlunos() => local.listarAlunos();

  Future<void> salvarAluno(Aluno aluno) {
    if (aluno.nome.trim().isEmpty ||
        aluno.nome.length > 100 ||
        !MensalidadeAcademia.matriculaValida(aluno.matricula)) {
      throw ArgumentError('Nome ou matrícula inválida.');
    }
    return local.salvarAluno(aluno);
  }

  Future<String> testarConexao() => api.testarConexaoBanco();
}
