---
description: Cria a nota de plano de uma issue no vault e para esperando revisão
argument-hint: "<número da issue>"
---

Plano para a issue #$ARGUMENTS.

1. Leia a issue (`gh issue view $ARGUMENTS --comments`), o `docs/escopo.md` e os ADRs que ela cita ou que regem a área.
2. O vault do autor é o diretório adicional deste projeto que contém `BairdWire/planos/` e `Modelos/plano.md`. Crie `BairdWire/planos/<issue>-<slug-do-título>.md` a partir de `Modelos/plano.md`, preenchendo: a issue de origem, os requisitos, os ADRs envolvidos, os passos numerados com status `pendente`, as perguntas de decisão (com opções e recomendação, e a resposta em branco) e os riscos.
3. Marque nos passos quais tocam áreas do autor (ADR 0040): nesses, o passo é do autor, e o seu papel é explicar e escrever testes.
4. Mostre o caminho da nota e um resumo, e **pare**. Não implemente nada antes de o autor revisar o plano e responder as perguntas.
