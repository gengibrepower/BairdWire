# ADR 0039 — Guardrails do assistente: commits livres na branch, push e PR bloqueados

**Status:** aceito
**Data:** 2026-11-20
**Revisa:** os guardrails do assistente no ADR 0032

## Contexto

O ADR 0032 manda o assistente pedir permissão antes de cada commit, com um resumo. Desde o PR #8, o `CLAUDE.md` libera os commits pequenos e rotineiros, mas ele também diz que a decisão de um ADR vale como está escrita. O assistente recebe as duas ordens ao mesmo tempo.

Pedir permissão a cada commit também empurra o assistente para commits grandes, o que vai contra os commits atômicos do próprio `CLAUDE.md`. E a proteção que importa, não publicar nada sem o autor, já vem de nunca fazer push nem abrir PR. Hoje essa proteção é só texto.

## Opções consideradas

- **Manter o ADR 0032 e voltar o `CLAUDE.md`:** permissão a cada commit. Gera histórico pior e muita interrupção.
- **Liberar todos os commits:** perde o momento de revisar as mudanças de decisão antes que entrem no histórico.
- **Commits livres na branch, com permissão só para os importantes e push e PR bloqueados por configuração.**

## Decisão

- Dentro da branch de trabalho, o assistente faz **commits atômicos livremente**.
- Ele **pede permissão, com um resumo, só para os commits importantes:** ADRs, regras do `CLAUDE.md`, dependências novas ou atualizadas e mudanças no `docs/protocolo.md`.
- **Push e abertura de PR ficam bloqueados por configuração do assistente, versionada no repositório**, e não só por texto. Push, PR e merge são do autor.
- **A revisão séria acontece no PR**, depois de uma revisão automática do diff contra os ADRs e o `CLAUDE.md`.

## Consequências

- O `CLAUDE.md` e os ADRs deixam de se contradizer sobre commits.
- O histórico da branch fica granular, e o squash merge mantém a `main` linear (ADR 0032).
- O bloqueio de push e PR depende da configuração do assistente estar no repositório e ativa. Sem ela, a regra volta a ser só texto.
- Fica mais difícil: acompanhar a branch commit a commit. O autor passa a revisar o conjunto, no PR.
