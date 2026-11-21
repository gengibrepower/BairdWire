---
description: Rascunha um ADR no formato do repo e só grava depois da aprovação
argument-hint: "<assunto da decisão>"
---

Rascunhe um ADR sobre: $ARGUMENTS

1. Leia `docs/adr/README.md` e use o próximo número livre.
2. Siga o formato dos ADRs existentes: título `# ADR NNNN — <título>`, `**Status:**`, `**Data:**` (hoje), `**Revisa:**` quando revisar outro ADR, e as seções Contexto, Opções consideradas, Decisão e Consequências. A última consequência começa com "Fica mais difícil:".
3. Antes de mostrar, procure conflitos com os ADRs aceitos e com o `CLAUDE.md`. Liste cada conflito com o ADR e o trecho. Se a decisão revisa outro ADR, diga qual trecho e proponha a linha "Revisado pelo ADR NNNN" para ele.
4. Mostre o texto completo e **pare**. Não grave nada antes da aprovação do autor.
5. Aprovado: grave o arquivo, adicione a linha no `docs/adr/README.md`, aplique as referências nos ADRs revisados e, se o ADR resolver uma pergunta de `docs/perguntas-abertas.md`, marque como resolvida apontando o ADR. Um commit `docs(adr): NNNN ...`.
