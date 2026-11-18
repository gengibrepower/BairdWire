# ADR 0031 — Estratégia de testes

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O núcleo do nó é sans-IO (ADR 0029), o que permite simulação determinística barata, na linha do VOPR do TigerBeetle (Zig) e do motor determinístico do autor. Os parsers expostos precisam de fuzzing (T2). O critério de pronto (ADR 0006) exige carga com 10 participantes, metas de qualidade (ADR 0005), reconexão e 7 dias de estabilidade. Os tipos do protocolo são escritos à mão em Zig e TS e precisam de testes de integração (ADR 0011).

## Opções consideradas

- Testes só com sockets e navegadores reais (lentos e caros).
- Pirâmide com simulação determinística na base e testes reais no topo.

## Decisão

| # | Camada | Ferramenta | Frequência |
|---|---|---|---|
| 1 | Unitário do núcleo | `zig build test` | Todo PR |
| 2 | Simulação determinística (relógio falso, N clientes, perda, reconexão, corridas). Falhas imprimem a seed. | Harness próprio no `zig build test` | PR: centenas de seeds. Noturno: milhares. |
| 3 | Fuzzing de parsers (envelope, SDP, RTP/RTCP, STUN) e do núcleo por eventos | Fuzzer nativo do Zig (AFL++ como alternativa) | PR: ~1 min. Noturno: longo. |
| 4 | Integração do protocolo: nó real × cliente de teste TS por WebSocket real, inclusive S1 e S5 | Vitest + `WebSocket` do Node | Todo PR |
| 5 | Cliente unitário, com corpus de XSS contra o Markdown | Vitest | Todo PR |
| 6 | End-to-end no navegador, com mídia conferida via `getStats()` | Playwright com mídia falsa | Noturno |
| 7 | Rede e carga: 10 navegadores, `tc netem`, metas do ADR 0005, latência por vídeo com contador | Playwright + Docker + `netem` | Semanal e antes de cada marco |
| 8 | Soak de 7 dias com bots, monitorando memória e descritores | Playwright + métricas do nó | Antes do M5 |

- Todos os testes Zig usam `std.testing.allocator`, que falha se houver vazamento.
- **Todo bug corrigido ganha um teste de regressão** na camada mais barata que o reproduza.
- "Várias instâncias" no v0.1 significa vários clientes contra um nó. Simulação com N nós fica para a federação.

## Consequências

- A maior parte dos bugs de rede é reproduzível por seed, sem infraestrutura.
- O harness de simulação é um componente de primeira classe do nó e precisa ser mantido junto com o núcleo.
- As camadas 7 e 8 exigem infraestrutura própria (Docker com `netem`, VPS para o soak).
- Fica mais difícil: manter os testes determinísticos fiéis ao comportamento real das libs. O que a simulação não modela é coberto nas camadas 6 e 7.
