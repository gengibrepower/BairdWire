# ADR 0027 — Revisão da linguagem do nó (D1 mantida)

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O autor pediu para revisitar a D1 (nó em Zig) depois de três incômodos que surgiram na sessão: as migrações, a quantidade de dependências em C/C++ e o cronograma.

Análise de cada um:
- **Migrações:** não dependem da linguagem (`@embedFile`, `embed.FS`, `include_str!`).
- **C/C++:** o SQLite é trivial no `zig build`. A dor real está na `libdatachannel`: um build C++ com CMake e várias dependências, callbacks vindos de threads internas que precisam de uma fila para o loop do nó, e o suporte a ICE-TCP ainda não verificado (P5).
- **Cronograma:** o Zig é o caminho mais longo, e a parte de rede da `std` está mudando (`std.Io`).

## Opções consideradas

- **A. Zig no nó**, como está.
- **B. Zig com o M0 como portão de 3 semanas** e a via híbrida como plano B.
- **C. Via híbrida:** Go e Pion no nó (com SFU próprio sobre o transporte do Pion) e Zig no módulo nativo do v0.2 (PipeWire, VA-API/NVENC).
- **D. Go ou Rust puro.** Rust com str0m (sans-IO) seria a opção mais robusta para testes determinísticos. Odin foi descartado por ter ecossistema de rede fraco e cross-compile limitado.

## Decisão

**Opção A: a D1 é mantida.** O nó continua em Zig, sem portão formal. O autor já tem base em C, e o custo de integração é aceito como parte do aprendizado.

## Consequências

- O M0 continua sendo a primeira fase e expõe cedo os riscos de build, threads e P5. Se ele se arrastar, a via híbrida (opção C) é a alternativa já analisada. Trocá-la exige um novo ADR.
- A contingência do SFU (ADR 0008) continua valendo.
- O isolamento das mudanças do Zig e da `libdatachannel` fica a cargo da arquitetura do nó (próximos ADRs do 4.8).
- Fecha a P10.
- Fica mais difícil: o cronograma, e o tempo gasto em build e FFI que não vira feature.
