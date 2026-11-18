# ADR 0026 — Contribuição e governança

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O código é AGPL-3.0-only (ADR 0025). O autor quer manter a possibilidade de vender o projeto. Com DCO, o código de terceiros continua sob a AGPL e não pode ser relicenciado sem a permissão de cada contribuidor. Trocar DCO por CLA depois não cobre o código que já entrou. Em qualquer modelo, as versões já publicadas em AGPL continuam AGPL para sempre e podem ser forkadas (casos OpenTofu, Valkey, OpenSearch). Numa venda, a marca costuma ser o ativo mais valioso.

O projeto vai ganhar exposição pela série no YouTube, e contribuições assistidas por IA são esperadas.

## Opções consideradas

- **A. DCO mais a marca registrada:** baixo atrito, coerente com o discurso, mas relicenciar fica mais difícil conforme entram contribuições.
- **B. CLA de licença** (modelo Apache ICLA): o contribuidor mantém o copyright e concede uma licença ampla, com direito de sublicenciar e relicenciar.
- **C. CLA de cessão de direitos:** controle máximo e atrito máximo.

## Decisão

- **CLA de licença (opção B)**, desde o primeiro contribuidor externo, coletado de forma automatizada no PR (CLA Assistant ou equivalente).
- **Transparência no `GOVERNANCE.md`:** o que o CLA permite, e a afirmação de que todas as versões publicadas continuam AGPL-3.0 para sempre.
- **Marca:** registrar o nome definitivo quando ele for escolhido (P1).
- **Política de IA:** o uso é permitido. Quem contribui é responsável pelo código (entender, testar, garantir que não há código com licença incompatível). PRs sem revisão humana evidente podem ser fechados sem análise.
- **Governança:** BDFL (o autor), documentado no `GOVERNANCE.md`, com a intenção de migrar para um modelo de mais mantenedores quando houver contribuidores recorrentes.
- **Mudanças de arquitetura exigem um ADR.**
- **Arquivos:** `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `GOVERNANCE.md`, `SECURITY.md` (ADR 0021).

## Consequências

- O autor mantém a opção de relicenciar e vender o projeto, inclusive com código de terceiros.
- Há mais atrito para contribuir, e o projeto fica sujeito a críticas de incoerência com a filosofia. A defesa é a transparência no `GOVERNANCE.md`.
- O texto do CLA precisa de revisão jurídica junto com a P14.
- Os commits do autor não levam trailer de co-autoria.
- Fica mais difícil: atrair contribuidores que recusam CLA por princípio.
