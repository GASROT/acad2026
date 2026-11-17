# Contrato HTTP v1 — Academia

- Aplicativo: https://github.com/GASROT/acad2026 (`main`).
- API: https://github.com/GASROT/acad2026-api (`main`).
- Base URL: informada ao Flutter por `--dart-define=API_BASE_URL=https://URL-REAL`.
- A URL de hospedagem ainda precisa ser configurada após a implantação; o endereço do GitHub não é uma URL de API.

| Método e rota | Resposta | Finalidade |
| --- | --- | --- |
| `GET /health` | 200 ou 503 | Verifica acesso ao PostgreSQL |
| `GET /mensalidades` | 200, array JSON | Lista mensalidades remotas |
| `POST /mensalidades` | 201; 200 em reenvio idêntico | Cadastra uma mensalidade |

Corpo de cadastro:

```json
{
  "id": "9c0359a2-f9d2-4cf6-a317-271e4a7bfbb7",
  "aluno": "Aluno teste",
  "matricula": "0007",
  "mensalidade": "129.90"
}
```

A resposta contém os mesmos campos mais `criado_em` em ISO 8601. `id` é o UUID da operação, reutilizado em todas as tentativas; a matrícula identifica o aluno e pode aparecer em várias mensalidades. Nomes têm até 100 caracteres; matrículas, de 1 a 30 letras/números/hífens; valores positivos têm até duas casas decimais e limite de `99999999.99`.

O nome do aluno é obrigatório no formulário. A API e o modelo aceitam registros legados sem o campo, representados por texto vazio. O SQLite usa centavos inteiros e `sincronizado` (0 ou 1); esses dois campos locais não são enviados à API.

Reenvios idênticos não duplicam o cadastro. Um UUID repetido com dados diferentes retorna 409. Erros seguem `{"erro":{"codigo":"...","mensagem":"..."}}`; outros códigos são 400, 404, 413 e 503.

O aplicativo somente marca uma mensalidade como sincronizada depois de conferir a resposta do POST. Falhas de conexão deixam o cadastro pendente no SQLite. **Buscar da API** importa registros sem apagar pendências locais; **Sincronizar pendentes** reenvia a fila manualmente.

Mudanças incompatíveis em nomes, tipos, validações ou respostas exigem atualização coordenada dos dois repositórios e dos testes. A API usa migrações SQL idempotentes e o aplicativo usa versionamento do schema SQLite.
