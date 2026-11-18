# ADR 0011 — Canal de controle e formato do protocolo

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O cliente precisa de eventos em tempo real (chat, presença, SDP e ICE) e também de operações de pedido e resposta (histórico, upload de imagem, convites, exportação LGPD). O nó e o cliente evoluem de forma independente, porque cada comunidade atualiza o seu nó quando quiser. A reconexão automática é critério de pronto (ADR 0006).

## Opções consideradas

- **Canais:** tudo por WebSocket; WebSocket separado para chat e para signaling; um WebSocket para o tempo real mais REST para o resto.
- **Formato:** JSON, Protobuf, CBOR ou binário próprio.
- **Fonte da verdade:** especificação escrita mais tipos à mão nos dois lados com testes de integração, ou um schema que gera os tipos em TypeScript e Zig.

## Decisão

- **Um WebSocket por cliente**, multiplexado, para tudo que é tempo real: chat, presença e signaling.
- **HTTP/REST** para histórico paginado, upload e download de imagens, convites e exportação de dados.
- **JSON** no canal de controle. A mídia não passa por ele, então o custo do formato é irrelevante.
- **Envelope:** `v` (versão do protocolo), `t` (tipo com namespace: `chat.*`, `voice.*`, `presence.*`), `id` (pedido), `re` (resposta correlacionada) e `d` (dados). Eventos que o nó envia por iniciativa própria não têm `re`.
- **Handshake `hello`**, com negociação de versão. Versão incompatível recusa a conexão com uma mensagem clara.
- **Fonte da verdade:** `docs/protocolo.md`, com os tipos escritos à mão em Zig e TypeScript e **testes de integração do protocolo** (cliente de teste contra nó real).

## Consequências

- Há uma única reconexão de WebSocket para gerenciar.
- As imagens usam a semântica HTTP (cache, `Range`, `Content-Type`).
- O protocolo é inspecionável no DevTools e no `websocat`, o que ajuda na depuração e na série.
- Os tipos podem divergir entre Zig e TS. Os testes de integração são a defesa contra isso.
- Mudanças incompatíveis exigem subir `v`. A política de compatibilidade entre versões do cliente e do nó fica para depois (P7).
- Fica mais difícil: não há validação de schema gerada automaticamente, e cada campo novo precisa ser atualizado em três lugares (especificação, Zig e TS).
