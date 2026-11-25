# ADR 0042 — Domínio por área

**Status:** aceito
**Data:** 2026-11-24
**Revisa:** ADR 0040

## Contexto

O ADR 0040 dividiu o repositório entre o autor e o assistente de forma fixa: o nó em Zig com o autor; build, deploy, CI e cliente com o assistente. A divisão serve ao objetivo de aprender Zig, mas não diz quando muda. Se o autor passar a dominar uma área, ele continua escrevendo o que já sabe; se o assistente escrever algo que o autor não entende, nada registra isso.

O objetivo é mais específico: **o assistente só escreve o que o autor já saberia escrever.** Uma área passa para o assistente quando o autor prova que a domina, e volta para o autor se ele deixar de conseguir explicá-la. As exceções são as áreas que o autor decidiu conscientemente não aprender, e essas ficam registradas.

## Opções consideradas

- **Manter a divisão fixa do ADR 0040:** simples, mas não acompanha o aprendizado e esconde o que o autor deixou de aprender.
- **Revisar o ADR 0040 a cada mudança, com a lista no texto:** a lista fica espalhada entre ADRs, e o hook continua com as áreas fixas no código.
- **Estados por área num arquivo de dados versionado, lido pelo hook, com cada mudança de estado registrada num ADR curto.**

## Decisão

**Estados.** Cada área está num destes estados:

| Estado | Quem escreve | O que o assistente faz |
|---|---|---|
| `aprendendo` | o autor | explica, dá dicas, revisa e escreve testes (`*_test.zig`). Não escreve a implementação, nem quando o autor pede só um trecho. |
| `em-prova` | o autor, do arquivo vazio, sem a versão de referência e sem pedir código | não dá dicas de design; só aponta erros de API depois de o autor terminar. |
| `delegada` | o assistente | escreve; o autor revisa linha por linha, como o PR de um júnior. |
| `divida` | o assistente | escreve, mas o autor não domina a área e pretende aprender. Fica no backlog de dívidas (`docs/dividas.md`). |
| `fora-do-objetivo` | o assistente | escreve; o autor não pretende aprender, até dizer o contrário. |

**Promoção.** Uma área sai de `aprendendo`, passa por `em-prova` e chega a `delegada` quando as notas do autor mostram:
1. pelo menos um módulo da área escrito do arquivo vazio, sem a referência e sem pedir código;
2. o `/revisar` sem achados graves nesse módulo;
3. o tempo por módulo caindo e as dicas pedidas mudando de design para detalhe de API;
4. o autor explicando cada linha sem consultar nada (o episódio da série sobre a área, ADR 0033, serve como teste).

**Rebaixamento.** Se, revisando uma área `delegada`, o autor não souber explicar uma linha, a área pode voltar para `aprendendo`.

**Granularidade.** Um estado vale para um prefixo de pasta ou para um arquivo, e o caminho mais específico vence. Um módulo de `core/` pode ser promovido sozinho.

**Fonte da verdade.** A tabela de estados fica em `docs/dominio.json`, uma lista de `{ "caminho", "estado", "adr" }`. O hook do assistente lê esse arquivo e bloqueia a escrita da implementação nas áreas `aprendendo` e `em-prova`, exceto `*_test.zig`. O hook falha fechado: um caminho em `node/src/` sem cobertura conta como `aprendendo`, e um arquivo ausente ou inválido bloqueia a escrita em `node/src/`. O `docs/dominio.md` explica os estados e mostra a tabela, mas quem vale é o JSON.

**Mudança de estado.** Promover, rebaixar ou mudar o estado de uma área exige um ADR curto que revisa o anterior, junto com a mudança no `docs/dominio.json`. Mudar o `docs/dominio.json` é um commit importante, que pede permissão com resumo (estende a lista do ADR 0039).

**Testes do hook.** A lógica de decisão do hook tem testes próprios, que rodam no `just check` e na CI quando o hook ou o `docs/dominio.json` mudam. Não são uma das camadas do ADR 0031: testam a ferramenta, não o produto.

**Estado inicial**, que mantém a divisão do ADR 0040 e nomeia as exceções:

| Área | Estado |
|---|---|
| `node/src/core/`, `node/src/runtime.zig`, `node/src/adapters/`, `node/src/main.zig` | `aprendendo` |
| `node/build.zig`, `node/build/` | `divida`: o autor escolheu não aprender agora porque seria demais para o momento |
| `client/` | `fora-do-objetivo` até o fim do projeto |
| `deploy/`, `.github/` | `fora-do-objetivo` |
| `.claude/` (hooks, subagentes, comandos, `SKILL.md`) e, no futuro, `.agents/` e `AGENTS.md` | `fora-do-objetivo` |
| Testes de integração em TypeScript | `fora-do-objetivo` |

Nenhuma área é promovida agora. O conteúdo das decisões (ADRs, regras do `CLAUDE.md`, `docs/protocolo.md`) continua passando pelo autor (ADR 0039), em qualquer estado. O contrato do ADR 0040 sobre o `docs/protocolo.md` continua valendo.

## Consequências

- A divisão acompanha o aprendizado: o assistente ganha área conforme o autor prova domínio, e não por conveniência.
- O que o autor não sabe e pretende aprender fica visível no `docs/dividas.md`, em vez de sumir no que o assistente escreveu.
- O hook e o revisor deixam de ter as áreas fixas no código. Mudar um estado é uma linha de dados, junto com o ADR.
- A mesma lógica de decisão e o mesmo `docs/dominio.json` servem para um segundo assistente (P17).
- Fica mais difícil: promover uma área exige evidência nas notas e um ADR a cada vez; um erro no `docs/dominio.json` trava toda a escrita em `node/src/` até ser corrigido; e o `em-prova` tira do autor a ajuda de design justamente no módulo mais difícil, porque essa é a prova.
