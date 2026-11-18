# Segurança

## Reportar uma vulnerabilidade

**Não abra issue pública.** Use o canal privado do GitHub: aba **Security** → **Report a vulnerability** neste repositório.

Inclua o que for possível: o que você encontrou, como reproduzir e qual o impacto. Vou responder assim que der. É um projeto pessoal, então não existe prazo garantido, mas relatos de segurança têm prioridade.

## Escopo

O projeto ainda está em planejamento e não tem código publicado. O threat model do v0.1 está em [`docs/adr/0020-threat-model-v0.1.md`](docs/adr/0020-threat-model-v0.1.md).

## Aviso

No v0.1, quem hospeda um nó (o *host*) tem acesso técnico às mensagens e às chamadas que passam por ele. Isso é uma limitação conhecida, não uma vulnerabilidade. O E2EE está planejado para depois.
