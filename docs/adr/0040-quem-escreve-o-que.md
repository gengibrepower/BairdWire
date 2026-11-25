# ADR 0040 — Quem escreve o quê

**Status:** aceito
**Data:** 2026-11-20

## Contexto

Um dos objetivos do projeto é o autor aprender Zig, e esse aprendizado alimenta a série (ADR 0033). A fase 0 inteira saiu em cerca de 5 horas, escrita pelo assistente. O M0 foi cumprido, mas o autor não escreveu o núcleo nem o runtime, que são justamente a parte que mais ensina Zig e a que a série quer mostrar.

Ao mesmo tempo, build, deploy, CI e cliente são trabalho necessário que não serve a esse objetivo. Deixar tudo com o autor atrasaria os marcos sem ganho de aprendizado.

## Opções consideradas

- **O assistente escreve tudo, e o autor revisa:** é o mais rápido, mas o autor não aprende Zig escrevendo, e a série perde o assunto principal.
- **O autor escreve tudo:** é lento, e o assistente vira só um tira-dúvidas.
- **Dividir por área:** o autor escreve o que ensina Zig e sustenta o projeto, e o assistente fica com o resto.

## Decisão

~~**O autor escreve:**~~
- ~~`node/src/core/`;~~
- ~~`node/src/runtime.zig`;~~
- ~~`node/src/adapters/`, onde o Zig conversa com as bibliotecas em C (callbacks, threads e filas);~~
- ~~`node/src/main.zig`.~~

~~Nessas áreas, o assistente explica, revisa e escreve testes (`*_test.zig`), mas **não escreve a implementação**.~~

~~**O assistente fica livre** em:~~
- ~~`node/build/` e no `build.zig`, incluindo o build das bibliotecas nativas;~~
- ~~`deploy/` e `.github/`;~~
- ~~`client/`;~~
- ~~testes de integração em TypeScript.~~

Revisado pelo [ADR 0042](0042-dominio-por-area.md): as áreas passam a ter estados, em `docs/dominio.json`, e a divisão acima vira o estado inicial.

**Contrato:** mudanças em `docs/protocolo.md` passam pelo autor antes. O assistente implementa a partir do contrato, mas não muda o contrato sozinho.

~~**Bloqueio:** a escrita do assistente nas áreas do autor fica bloqueada por configuração versionada no repositório, com exceção dos arquivos de teste.~~ Revisado pelo [ADR 0042](0042-dominio-por-area.md): o bloqueio passa a ler `docs/dominio.json`.

## Consequências

- O nó em Zig, do núcleo aos adaptadores, passa a ser escrito à mão, módulo por módulo, usando os testes atuais como especificação. A versão escrita pelo assistente fica guardada como referência para comparar depois.
- Os marcos que dependem do nó andam no ritmo do autor.
- O assistente continua útil no nó como tutor, revisor e autor de testes. Ele aponta as lacunas de teste antes da reescrita.
- Fica mais difícil: corrigir rápido um bug no nó. A correção espera o autor, mesmo quando o assistente já sabe qual é.
