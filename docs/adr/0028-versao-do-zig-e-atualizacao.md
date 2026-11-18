# ADR 0028 — Versão do Zig e estratégia de atualização

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O Zig é pré-1.0 e tem breaking changes a cada release. Acompanhar essas mudanças é um objetivo declarado (D1). As bibliotecas da comunidade podem demorar a acompanhar uma release nova. Até o fim de 2025, a última estável conhecida era a 0.15.x, e a 0.16 estava prevista com a interface `std.Io`. A versão estável vigente é confirmada na instalação.

## Opções consideradas

- **Release estável:** quebras agrupadas e documentadas, e migrações que rendem episódio.
- **Master (nightly):** quebras semanais, build não reproduzível.

## Decisão

- **Fixar na versão estável mais recente**, com `minimum_zig_version` no `build.zig.zon`, um arquivo `.zig-version` na raiz (para zvm, mise ou anyzig) e o CI instalando exatamente essa versão.
- Dependências Zig fixadas por hash no `build.zig.zon`.
- **Migração:** em uma branch `zig-0.N` dedicada, nunca no meio de uma feature.
- Esperar **até 4 semanas** após a release para que as dependências acompanhem. Se uma lib essencial não acompanhar, avaliar fork ou substituição.
- **Não pular versões.**
- Cada migração é registrada em `docs/migracoes-zig.md` (o que quebrou e como foi resolvido).

## Consequências

- O build é reproduzível. As migrações viram eventos planejados e material para a série.
- O nó pode ficar até cerca de 1 mês atrás da estável mais recente.
- Libs Zig de terceiros no caminho crítico viram risco de cronograma. É um critério para escolher as bibliotecas.
- Fica mais difícil: usar features novas do master antes da release.
