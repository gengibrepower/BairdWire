---
description: Lista o que falta para o próximo marco
---

1. Leia `docs/escopo.md`, o ADR 0013 (fases e marcos) e o ADR 0041 (camadas de teste por fase).
2. Descubra o marco atual: o último marco cumprido e o próximo. Use os ADRs, o histórico de PRs (`git log --oneline main`) e as issues.
3. Liste o que o próximo marco exige e, para cada item, o estado: feito (com o PR ou commit), em andamento (com a issue ou branch) ou faltando. Inclua as camadas de teste que a fase traz.
4. Cruze com as issues abertas do milestone: `gh issue list --milestone "<marco>" --state open`. Aponte o que falta e não tem issue, e as issues que não correspondem a nada do escopo. Se o milestone não existir, diga isso.
5. Termine com as perguntas abertas (`docs/perguntas-abertas.md`) que bloqueiam o marco.

Só leitura: não crie issues nem mude arquivos.
