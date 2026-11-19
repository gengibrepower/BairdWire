# Protocolo do BairdWire

A especificação do canal de tempo real entre o cliente e o nó. É a fonte da verdade: os tipos em Zig (`node/src/core`) e em TypeScript (`client/`) seguem este documento, e os testes de integração do protocolo verificam os dois (ADR 0011).

**Versão atual do protocolo: 1.**

## Transporte

- Um WebSocket por cliente, em `wss://<nó>/api/ws`, atrás do Caddy (ADR 0010).
- O upgrade só é aceito com o cabeçalho `Origin` igual à origem do nó (S1, ADR 0021). Caso contrário, o nó responde `403` e não abre o WebSocket.
- A sessão viaja no cookie `HttpOnly` (S2). Nenhuma mensagem do protocolo carrega credencial.
- Cada mensagem é um frame de texto com um objeto JSON em UTF-8. Frames binários são um erro de protocolo.

## Envelope

```jsonc
{ "v": 1, "t": "namespace.tipo", "id": "…", "re": "…", "d": { } }
```

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `v` | inteiro | sim | Versão do protocolo da mensagem. Antes do `welcome`, o cliente usa a maior versão que oferece |
| `t` | string | sim | Tipo, com namespace: `session.*`, `chat.*`, `voice.*`, `presence.*` |
| `id` | string, até 64 bytes | em pedidos | Identificador escolhido por quem pede, único na conexão |
| `re` | string | em respostas | O `id` do pedido que esta mensagem responde |
| `d` | objeto | sim | Os dados do tipo. `{}` quando não há dados |

Eventos que o nó envia por iniciativa própria não têm `re`.

## Limites

| Limite | Valor |
|---|---|
| Tempo até o `session.hello` | 5 s |
| Tamanho de mensagem antes do `session.hello` | 4 KiB |
| Tamanho de mensagem depois do `session.welcome` | 64 KiB |

## Handshake

O formato de `session.hello`, `session.welcome` e `session.error` é **congelado**: vale para todas as versões do protocolo, e campos novos nelas só entram como opcionais (ADR 0035).

### `session.hello` (cliente → nó)

A primeira mensagem da conexão. Qualquer outra primeira mensagem é um erro de protocolo.

| Campo de `d` | Tipo | Significado |
|---|---|---|
| `versions` | array de inteiros, não vazio | As versões que o cliente fala |
| `client` | string, até 64 bytes | Identificação do cliente, como `web/0.1.0`. Só para diagnóstico |
| `resume` | string ou `null` | Token de retomada da sessão anterior (ADR 0012). `null` numa conexão nova |

```json
{ "v": 1, "t": "session.hello", "id": "1", "d": { "versions": [1], "client": "web/0.1.0", "resume": null } }
```

### `session.welcome` (nó → cliente)

O handshake foi aceito. A partir daqui, todas as mensagens usam `version` em `v`.

| Campo de `d` | Tipo | Significado |
|---|---|---|
| `version` | inteiro | A versão escolhida: a maior em comum |
| `node` | string | A versão do nó |
| `resumed` | booleano | Se a sessão anterior foi retomada. Sempre `false` até a fase 3 |

```json
{ "v": 1, "t": "session.welcome", "re": "1", "d": { "version": 1, "node": "0.1.0-dev", "resumed": false } }
```

### `session.error` (nó → cliente)

Um erro. Quando o erro encerra a conexão, o nó envia esta mensagem e em seguida fecha o WebSocket com o código da tabela.

| Campo de `d` | Tipo | Significado |
|---|---|---|
| `code` | string | O motivo, da tabela abaixo |
| `supported` | array de inteiros | Só em `version_incompatible`: as versões que o nó aceita |

```json
{ "v": 1, "t": "session.error", "re": "1", "d": { "code": "version_incompatible", "supported": [1] } }
```

`re` aparece quando o erro responde a um pedido com `id` válido.

## Códigos

| `code` | Fechamento | Quando |
|---|---|---|
| `protocol_error` | 4000 | JSON ou envelope inválido, frame binário, primeira mensagem que não é `session.hello`, `session.hello` repetido |
| `version_incompatible` | 4001 | Nenhuma versão em comum |
| `hello_timeout` | 4002 | O `session.hello` não chegou em 5 s |
| `message_too_large` | 1009 | Mensagem acima do limite |
