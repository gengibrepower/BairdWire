# Protocolo do BairdWire

A especificação do canal de tempo real entre o cliente e o nó. É a fonte da verdade: os tipos em Zig (`node/src/core/protocol.zig`) e em TypeScript (`client/src/lib/protocol.ts`) seguem este documento, e os testes de integração do protocolo verificam os dois (ADR 0011).

**Versão atual do protocolo: 1.**

## Transporte

- Um WebSocket por cliente, em `wss://<nó>/api/ws`, atrás do Caddy (ADR 0010).
- O upgrade só é aceito em `/api/ws` e com o cabeçalho `Origin` igual à origem do nó (S1, ADR 0021). Caso contrário, o nó recusa o handshake com HTTP `400` e não abre o WebSocket.
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

O envelope do `session.hello` precisa ter `id`.

| Campo de `d` | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `versions` | array de inteiros positivos, não vazio | sim | As versões que o cliente fala |
| `client` | string, até 64 bytes | não | Identificação do cliente, como `web/0.1.0`. Só para diagnóstico |
| `resume` | string de até 256 bytes, ou `null` | não | Token de retomada da sessão anterior (ADR 0012). Ausente ou `null` numa conexão nova |

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

## Mídia (`rtc.*`)

Cada cliente usa duas PeerConnections (ADR 0012). Na **publish**, o cliente oferece e envia a sua mídia. Na **subscribe**, o nó oferece e envia a mídia dos outros. Cada uma tem um lado só que oferece, então não há *glare*. O trickle ICE vai só do cliente para o nó: os candidatos do nó já vêm no SDP, que o nó só envia depois de juntar todos.

O fluxo do eco (M0):

1. O cliente envia `rtc.offer` com `pc: "publish"`.
2. O nó responde `rtc.answer` com `re` igual ao `id` da oferta.
3. Quando a track de áudio Opus do publish chega, o nó envia `rtc.offer` com `pc: "subscribe"`, com um `id` próprio.
4. O cliente responde `rtc.answer` com `re` igual a esse `id`.
5. Os dois lados enviam `rtc.candidate` para o nó à medida que encontram candidatos. Os do subscribe só valem depois do passo 4.

O nó repassa o RTP Opus do publish para o subscribe trocando só o SSRC, sem ler o payload (ADR 0022). RTCP e outros payload types não são repassados no M0.

### `rtc.offer`

| Campo de `d` | Tipo | Significado |
|---|---|---|
| `pc` | `"publish"` ou `"subscribe"` | Do cliente, sempre `publish`. Do nó, sempre `subscribe` |
| `sdp` | string não vazia | A oferta |

Do cliente, `id` é obrigatório.

```json
{ "v": 1, "t": "rtc.offer", "id": "o1", "d": { "pc": "publish", "sdp": "v=0..." } }
```

### `rtc.answer`

Os mesmos campos de `rtc.offer`. Do cliente, `pc` é sempre `subscribe` e `re` é obrigatório. Do nó, `pc` é sempre `publish`.

```json
{ "v": 1, "t": "rtc.answer", "re": "subscribe-2", "d": { "pc": "subscribe", "sdp": "v=0..." } }
```

### `rtc.candidate` (cliente → nó)

| Campo de `d` | Tipo | Significado |
|---|---|---|
| `pc` | `"publish"` ou `"subscribe"` | A PeerConnection do candidato |
| `candidate` | string, até 1024 bytes | A linha `candidate:` do navegador. Vazia indica o fim dos candidatos e é ignorada |
| `mid` | string, de 1 a 32 bytes | O `sdpMid` do candidato |

```json
{ "v": 1, "t": "rtc.candidate", "d": { "pc": "publish", "candidate": "candidate:1 1 udp ...", "mid": "0" } }
```

## Códigos

| `code` | Fechamento | Quando |
|---|---|---|
| `protocol_error` | 4000 | JSON ou envelope inválido, frame binário, primeira mensagem que não é `session.hello`, `session.hello` repetido, `d` inválido numa mensagem `rtc.*`, oferta do cliente fora do publish ou sem `id`, resposta do cliente fora do subscribe ou sem `re` |
| `version_incompatible` | 4001 | Nenhuma versão em comum |
| `hello_timeout` | 4002 | O `session.hello` não chegou em 5 s |
| `message_too_large` | 1009 | Mensagem acima do limite |
| `unknown_type` | — (não fecha) | Depois do `session.welcome`, um `t` que o nó não conhece |
| `invalid_state` | — (não fecha) | Uma mensagem `rtc.*` válida fora de hora: segunda oferta de publish, resposta antes da oferta do nó ou com `re` errado, candidato de uma PeerConnection que ainda não existe |

Campos desconhecidos no envelope são ignorados, para que campos opcionais novos não quebrem nós antigos. Chaves duplicadas num mesmo objeto são `protocol_error`.
