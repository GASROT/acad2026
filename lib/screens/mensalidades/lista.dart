import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../components/estado_sincronizacao.dart';
import '../../models/mensalidade_academia.dart';
import '../../repository/academia_repository.dart';
import '../../services/api_service.dart';
import 'formulario.dart';

class ListaMensalidades extends StatefulWidget {
  final AcademiaRepository repository;
  const ListaMensalidades({super.key, required this.repository});
  @override
  State<ListaMensalidades> createState() => _ListaMensalidadesState();
}

class _ListaMensalidadesState extends State<ListaMensalidades> {
  List<MensalidadeAcademia> _registros = [];
  bool _carregando = true;
  bool _ocupado = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final registros = await widget.repository.buscarMensalidades();
      if (mounted) {
        setState(() {
          _registros = registros;
          _erro = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível carregar as mensalidades.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } on ApiException catch (erro) {
      _avisar(erro.mensagem);
    } catch (_) {
      _avisar(
        'Não foi possível concluir. Seus registros locais foram preservados.',
      );
    } finally {
      await _carregar();
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _sincronizar() => _executar(() async {
    final resultado = await widget.repository.sincronizarPendentes();
    _avisar(
      '${resultado.enviados} enviada(s); ${resultado.pendentes} pendente(s).'
      '${resultado.erro == null ? '' : ' ${resultado.erro}'}',
    );
  });

  Future<void> _atualizar() => _executar(() async {
    await widget.repository.atualizarDaApi();
    _avisar('Mensalidades atualizadas.');
  });

  Future<void> _nova() async {
    final resultado = await Navigator.of(context).push<ResultadoCadastro>(
      MaterialPageRoute(
        builder: (_) => FormularioMensalidade(repository: widget.repository),
      ),
    );
    if (!mounted) return;
    if (resultado != null) _avisar(resultado.mensagem);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _registros.where((r) => !r.sincronizado).length;
    final moeda = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensalidades'),
        actions: [
          IconButton(
            tooltip: 'Testar conexão',
            icon: const Icon(Icons.wifi_tethering),
            onPressed: _ocupado
                ? null
                : () => _executar(() async {
                    _avisar(await widget.repository.testarConexao());
                  }),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_registros.length} mensalidade(s) • $pendentes pendente(s)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _ocupado || _carregando
                                ? null
                                : _sincronizar,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sincronizar pendentes'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _ocupado || _carregando
                                ? null
                                : _atualizar,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('Buscar da API'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_ocupado) const LinearProgressIndicator(),
                Expanded(
                  child: _carregando
                      ? const Center(child: CircularProgressIndicator())
                      : _erro != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_erro!),
                              TextButton(
                                onPressed: _carregar,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : _registros.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhuma mensalidade por aqui.\nCadastre a primeira ou busque os registros da API.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _atualizar,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _registros.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (_, index) {
                              final item = _registros[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.fitness_center,
                                  color: Color(0xFF2346B4),
                                ),
                                title: Text(
                                  item.aluno.isEmpty
                                      ? moeda.format(
                                          item.mensalidadeCentavos / 100,
                                        )
                                      : item.aluno,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.aluno.isNotEmpty)
                                      Text(
                                        moeda.format(
                                          item.mensalidadeCentavos / 100,
                                        ),
                                      ),
                                    Text('Matrícula: ${item.matricula}'),
                                    const SizedBox(height: 6),
                                    EstadoSincronizacao(
                                      sincronizado: item.sincronizado,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ocupado ? null : _nova,
        icon: const Icon(Icons.add),
        label: const Text('Nova mensalidade'),
      ),
    );
  }
}
