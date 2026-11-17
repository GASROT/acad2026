# Academia — Mensalidades

- **Temática:** 7. Academia.
- **Estudante:** GUILHERME DE ARAUJO SILVA.
- **Repositório:** https://github.com/GASROT/acad2026
- **Repositório da API:** https://github.com/GASROT/acad2026-api
- **Entidade principal:** `MensalidadeAcademia`.
- **Valor:** mensalidade, em reais.
- **Identificador do aluno:** matrícula (texto, preservando zeros à esquerda).
- **Ícone:** `Icons.fitness_center`.
- **Link da API publicada:** pendente de publicação. Substituir este campo pela URL HTTPS real após implantar a API.
- **Descrição:** aplicativo Flutter para cadastrar e consultar mensalidades de academia, manter alunos no aparelho e sincronizar mensalidades pendentes com uma API própria Node.js/Express e PostgreSQL.

Evolução do projeto Bank do primeiro bimestre, conforme o [enunciado do segundo bimestre](https://amused-limpet-3f8.notion.site/Projeto-Avaliativo-2-Bimestre-41889db569608064a76ff0380528fb19) e a [referência de offline-first](https://amused-limpet-3f8.notion.site/5-Persist-ncia-Offline-first-com-SQLite-e-sincroniza-o-com-API-36689db569608015a287d5ca4646a35c).

## Organização

Este repositório contém somente o aplicativo Flutter. A API Node.js/Express e o PostgreSQL são mantidos no [repositório separado acad2026-api](https://github.com/GASROT/acad2026-api), na branch `main`. O contrato de integração está em [docs/api-contract.md](docs/api-contract.md).

```text
lib/
  components/    Campos de formulário e estado de sincronização
  models/        MensalidadeAcademia e Aluno
  screens/       Dashboard, alunos e mensalidades
  database/      SQLite
  services/      HTTP e contrato da API
  repository/    Estratégias local, remota e offline-first
  main.dart      Configuração e inicialização
test/            Modelos, SQLite, repository, HTTP e navegação Flutter
docs/            Contrato HTTP entre o aplicativo e a API
```

Esta versão 1.1.0 evolui a Academia do primeiro bimestre: preserva o pacote Dart `academia`, os identificadores nativos, o nome do aluno por mensalidade e as capturas originais em `evidencias/`. Acrescenta persistência local, API e sincronização. A versão anterior mantinha registros somente em memória, portanto não havia um banco persistido a importar. O banco local é `academia.db`; sua migração para a versão 2 adiciona o nome do aluno sem apagar registros criados pela primeira versão do schema. Um eventual `bank.db` do projeto-base é preservado e não convertido.

## Executar o aplicativo

Para reproduzir o lockfile atual, use Flutter 3.47.5 / Dart 3.13.4, versões utilizadas na validação. As dependências resolvidas exigem Dart >=3.13.0 e Flutter >=3.44.0; o projeto-base declarava Dart `^3.10.8`.

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=https://SUA-API.onrender.com
```

Substitua o endereço de exemplo pela API publicada. Sem `API_BASE_URL`, o aplicativo continua cadastrando localmente e informa que a API não foi configurada. A antiga API bancária não é utilizada.

O destino principal é Android/iOS. Windows/Linux usam SQLite FFI; macOS usa o plugin nativo. Para compilar Windows são necessários Visual Studio com C++ e suporte a links simbólicos. O scaffold web foi herdado, mas esta versão não implementa SQLite no navegador.

O APK Android precisa da permissão `INTERNET`, já declarada no manifesto principal. Use HTTPS para a API publicada. Não foi habilitado tráfego HTTP irrestrito no Android/iOS.

```sh
flutter build apk --release --dart-define=API_BASE_URL=https://SUA-API.onrender.com
```

O template Android mantém assinatura de depuração para testes acadêmicos. Para distribuição em loja, configure uma chave de assinatura própria fora do repositório.

### Modos de persistência

O modo padrão é `offlineFirst`. Os outros modos podem ser usados para estudar as fontes separadamente:

```sh
flutter run --dart-define=PERSISTENCIA=local
flutter run --dart-define=PERSISTENCIA=remota --dart-define=API_BASE_URL=https://SUA-API.onrender.com
```

| Modo | Cadastro | Listagem |
| --- | --- | --- |
| `local` | SQLite, sem envio automático | SQLite |
| `remota` | API; uma falha é informada ao usuário | API |
| `offlineFirst` | Fila durável no SQLite, tentativa imediata na API, confirmação local | SQLite, disponível sem rede |

Em offline-first, **Buscar da API** importa registros remotos sem excluir os locais. A lista não depende de uma conexão para abrir. **Sincronizar pendentes** envia explicitamente a fila local. Alunos são uma agenda local de apoio, adaptada dos contatos do projeto original; tocar em um aluno abre uma mensalidade com sua matrícula preenchida. A entidade sincronizada com a API é a mensalidade.

## Fluxo offline-first

1. Validar nome do aluno, matrícula e valor. Nomes aceitam até 100 caracteres; matrículas aceitam de 1 a 30 letras, números ou hífens; valores positivos aceitam até duas casas decimais.
2. Criar um UUID por mensalidade e salvar no SQLite com `sincronizado = 0` antes do HTTP. Essa precaução também protege o cadastro caso o app encerre durante a requisição.
3. Tentar `POST /mensalidades` com timeout de 10 segundos.
4. Confirmar a resposta da API e marcar `sincronizado = 1`. Se a API falhar, manter o registro pendente e informar o usuário.
5. Ao tocar em **Sincronizar pendentes**, enviar cada pendência e marcar somente as confirmadas. Falhas parciais não eliminam registros.

O UUID é diferente da matrícula: um mesmo aluno pode ter várias mensalidades. O UUID identifica uma operação e é reutilizado nas tentativas de envio. A API impede duplicar a mesma operação quando uma resposta se perde. Sincronização simultânea compartilha a mesma fila em execução. Não há sincronização automática em segundo plano, autenticação, edição ou exclusão sincronizadas, conforme o escopo da avaliação.

Os valores usam inteiros em centavos no SQLite e `NUMERIC(10,2)` no PostgreSQL. A API transmite valores decimais como texto, por exemplo `"129.90"`.

## API e implantação

Consulte o [README da API](https://github.com/GASROT/acad2026-api/blob/main/README.md) para configuração do banco, rotas, exemplos e implantação no Render. O `render.yaml` fica na raiz daquele repositório. Nenhuma credencial deve ser incluída no código ou no Git.

## Validação

```sh
flutter analyze
flutter test
```

No checkout separado da API, execute `npm ci`, `npm run check` e `npm test`. O teste com PostgreSQL real usa uma URL de banco **de teste**, cria um schema temporário exclusivo e o remove ao terminar:

```powershell
$env:TEST_DATABASE_URL = 'postgresql://usuario:senha@localhost:5432/academia_teste'
npm run test:integration
```

Sem `TEST_DATABASE_URL`, esse teste é marcado como ignorado; isso não significa validação do PostgreSQL. Os demais testes da API usam um banco simulado para validar o contrato HTTP. Os testes de repository e de interface Flutter usam SQLite real.

### Cenários exigidos para a demonstração

| Cenário | Procedimento | Evidência |
| --- | --- | --- |
| API disponível | Cadastrar uma mensalidade com URL válida | Estado sincronizada, GET da API e linha no PostgreSQL |
| API indisponível | Executar com URL inválida; cadastrar outra mensalidade | Estado pendente; registro continua após fechar e abrir o app |
| API restaurada | Executar novamente com URL válida; tocar em Sincronizar pendentes | Estado sincronizada; GET e PostgreSQL contêm o registro |

Para simular a indisponibilidade, use `--dart-define=API_BASE_URL=https://academia.invalid`. Restaure a URL no próximo `flutter run`, sem desinstalar o aplicativo ou limpar seus dados. Se o serviço estiver retomando após inatividade, o primeiro envio pode exceder o timeout: o cadastro continuará pendente e poderá ser sincronizado novamente.

## Entrega acadêmica

- Informar o link deste repositório e a URL pública real da API; atualizar o campo no início deste README.
- Manter o repositório acessível ao professor. Se privado, adicionar `@adrianoprof` como colaborador.
- Entregar também o link do repositório separado da API. As rotas principais estão descritas em `docs/api-contract.md` e no README daquele repositório.
- Gravar vídeo obrigatório de **até 5 minutos**: abrir o app, mostrar o tema, listar mensalidades, cadastrar online e comprovar no banco/API, cadastrar com falha de conexão, reabrir para comprovar a persistência e restaurar a API para sincronizar.
- Enviar os links e o vídeo pela tarefa correspondente no Teams. O enunciado informa que a ausência do vídeo desconsidera a entrega.

Publicação na hospedagem, URL pública, compartilhamento com o professor e gravação/envio do vídeo são etapas externas; o código e a configuração de implantação não comprovam que elas foram realizadas.
