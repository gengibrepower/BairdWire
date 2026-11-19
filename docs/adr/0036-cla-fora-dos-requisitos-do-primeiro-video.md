# ADR 0036 — CLA Assistant fora dos requisitos do primeiro vídeo

**Status:** aceito
**Data:** 2026-11-19
**Revisa:** o item V3 do ADR 0033

## Contexto

O ADR 0033 lista o **V3, CLA Assistant configurado**, entre o que precisa existir antes do primeiro vídeo. O ADR 0026 decidiu um CLA de licença, coletado de forma automatizada no PR, **desde o primeiro contribuidor externo**.

Hoje não existe texto de CLA: o rascunho foi removido no commit `b2f8d83`, e o texto depende da revisão jurídica (P14). O `CONTRIBUTING.md` diz que, por enquanto, PRs de código de fora não são aceitas. O CLA Assistant só cobra um texto que exista, e só faz diferença quando houver contribuidor externo.

## Opções consideradas

- **Manter o V3:** escrever o texto do CLA e passar pela revisão jurídica antes do primeiro vídeo.
- **Tirar o V3 dos requisitos do primeiro vídeo:** configurar o CLA Assistant junto com a abertura das contribuições externas.

## Decisão

- **O V3 sai dos requisitos do primeiro vídeo.**
- O CLA Assistant, ou equivalente, é configurado **antes de aceitar o primeiro PR de código externo**, com o texto do CLA revisado (P14). O check dele entra no ruleset da `main` nessa hora.
- Até lá, o `CONTRIBUTING.md` continua dizendo que PRs de código de fora não são aceitas. A decisão do ADR 0026 (CLA de licença desde o primeiro contribuidor externo) não muda.

## Consequências

- O primeiro vídeo não depende da revisão jurídica do CLA.
- Abrir as contribuições externas passa a ter três pré-requisitos: o texto do CLA revisado, o CLA Assistant configurado e o check dele no ruleset.
- Quem assistir aos primeiros vídeos e quiser contribuir com código vai encontrar as contribuições externas ainda fechadas. Issues e discussões continuam abertas.
- Fica mais difícil: aceitar uma contribuição de código boa que apareça cedo. Ela precisa esperar o CLA.
