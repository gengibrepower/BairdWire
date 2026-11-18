# Contribuindo

Valeu pelo interesse! O projeto está no começo, então ainda não tem código para mexer. Por enquanto, a melhor forma de ajudar é **abrir uma issue** para discutir o escopo, as decisões ou uma ideia.

## Antes de mandar código

- **Discuta antes numa issue.** Mudanças de arquitetura ou de escopo precisam de um ADR (`docs/adr/`).
- **CLA:** contribuições externas exigem a assinatura de um [Contributor License Agreement](CLA.md). Ele ainda está em rascunho e a coleta automatizada ainda não está ativa, então **PRs externos com código ficam em espera** até isso ficar pronto. O motivo está explicado no [GOVERNANCE](GOVERNANCE.md).

## Fluxo

1. Uma branch a partir da `main`: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
2. Commits no formato [Conventional Commits](https://www.conventionalcommits.org/) (`feat(node): …`, `fix(client): …`).
3. Um PR com o CI verde. O merge é por squash e o histórico é linear.
4. Todo bug corrigido vem com um teste de regressão.

## Estilo

- Sem comentários no código, a não ser para explicar um comportamento inesperado ou não óbvio. O código deve se explicar pelos nomes e pelos tipos.
- Zig: `zig fmt`. Cliente: Biome.

## Uso de IA

Pode usar. Mas **quem abre o PR é responsável pelo código**: precisa entender o que está mandando, ter testado, e garantir que não tem código copiado com licença incompatível. PRs claramente gerados sem revisão humana podem ser fechados sem análise.

## Conduta

Este projeto segue o [Código de Conduta](CODE_OF_CONDUCT.md).
