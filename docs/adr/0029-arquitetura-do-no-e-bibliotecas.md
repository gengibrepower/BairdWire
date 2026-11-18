# ADR 0029 — Arquitetura do nó, isolamento de I/O e bibliotecas

**Status:** aceito
**Data:** 2026-11-18

## Contexto

As breaking changes do Zig (ADR 0028) se concentram em I/O e rede (`std.Io`). A `libdatachannel` chama callbacks a partir das próprias threads (ADR 0027). Os testes de rede com vários participantes, reconexão e glare (ADRs 0006 e 0012) são caros se dependerem de sockets reais. Os parsers expostos à internet precisam de fuzzing (ADR 0020). Libs Zig de terceiros são risco de cronograma.

O autor já construiu um motor determinístico com event sourcing (o simulador de exchange em Rust).

## Opções consideradas

- **Arquitetura:** lógica acoplada às libs de I/O, ou **núcleo sans-IO** (eventos entram, efeitos saem) com adaptadores finos.
- **Concorrência:** estado compartilhado com locks, ou **um ator** com fila MPSC.
- **Event loop:** `libxev`, `std.Io`, ou nenhum (as libs já trazem o próprio modelo de threads).
- **HTTP e WebSocket:** `http.zig` e `websocket.zig`, ou o `std.http.Server` da `std`.
- **SQLite:** lib Zig de terceiros, ou amalgamação com wrapper próprio.

## Decisão

- **Núcleo sans-IO em Zig puro:** protocolo, sessões, permissões, chat, salas, máquinas de estado e decisões de roteamento do SFU. Recebe eventos (`ws_message`, `rtp_packet`, `ice_state_changed`, `tick(now)`…) e devolve efeitos (`send_ws`, `forward_rtp`, `db_write`, `request_keyframe`…). Tempo e aleatoriedade são entradas.
- **Adaptadores finos:** HTTP/WS, WebRTC, SQLite, relógio e RNG.
- **Um ator:** o núcleo roda numa única thread e consome uma fila MPSC. As threads das libs só enfileiram eventos.
- **Nenhum event loop no v0.1.** A `libxev` sai do plano. O `std.Io` entra nos adaptadores quando fizer sentido.
- **Bibliotecas:**
  - WebRTC: `libdatachannel` pela API C (`rtc.h`) com binding próprio;
  - HTTP e WebSocket: `http.zig` e `websocket.zig` atrás de adaptador. Plano B: `std.http.Server` com WebSocket da `std`;
  - SQLite: amalgamação compilada pelo `zig build`, com wrapper próprio;
  - JSON: `std.json`. Cripto: `std.crypto`. UUIDv7: implementação própria.
- **Só duas libs Zig de terceiros**, ambas atrás de adaptador.

## Consequências

- As mudanças de I/O do Zig e as trocas de lib ficam restritas aos adaptadores.
- Testes determinísticos de rede (relógio falso, perda simulada, N participantes) rodam no `zig build test` sem sockets. O núcleo pode ser fuzzado com eventos.
- Não há locks no domínio, e os callbacks da `libdatachannel` só enfileiram.
- O RTP passa pelo ator. O teste de carga mede, e se virar gargalo um plano de mídia separado pode ser extraído sem mudar o modelo de eventos e efeitos.
- É preciso verificar se `http.zig` e `websocket.zig` acompanham as releases estáveis do Zig (P15).
- Fica mais difícil: o desenho de eventos e efeitos é mais verboso que chamar I/O direto, e exige disciplina para não vazar I/O para dentro do núcleo.
