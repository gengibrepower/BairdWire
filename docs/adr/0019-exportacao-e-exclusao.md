# ADR 0019 — Exportação e exclusão de dados (direitos do titular)

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O art. 18 da LGPD garante ao titular confirmação, acesso, correção, eliminação, portabilidade e informação. O art. 19, II dá até 15 dias para a resposta completa. Pelo art. 12, um dado anonimizado deixa de ser pessoal só se a reidentificação não for razoavelmente possível. As mensagens podem identificar o autor pelo próprio conteúdo. Membros removidos perdem o acesso ao cliente.

## Opções consideradas

- Exclusão de conta: **(A)** anonimizar as mensagens, **(B)** apagar tudo, **(C)** o titular escolhe.
- Exportação self-service contra exportação por pedido ao host.
- Membro removido: apagar na hora, manter para sempre, ou um prazo de carência.

## Decisão

- **Exportação self-service e imediata:** um ZIP com `dados.json` (formato documentado) e `imagens/`. Inclui perfil, dispositivos, mensagens e imagens de autoria do titular, convites criados e eventos de auditoria em que é ator ou alvo. Não inclui conteúdo de terceiros.
- **Correção:** editar o nome de exibição e as próprias mensagens.
- **Exclusão da própria conta, opção C:** o titular escolhe entre anonimizar as mensagens (padrão, autor `NULL`, exibido como "ex-membro") e apagar também todas as mensagens e imagens. A interface avisa que mensagens anonimizadas podem continuar identificando o autor pelo conteúdo.
- **Membro removido por admin:** os dispositivos são revogados e a autoria é anonimizada. A conta fica 30 dias no estado `removido` e depois é apagada. Nesse prazo, e para qualquer pedido de titular que chegue pelo contato do host, existem os comandos `bairdwire export --member <id>` e `bairdwire purge --member <id>`.
- **Transparência:** a página "Seus dados neste nó" (K1, ADR 0023) informa as retenções, que os backups mantêm dados até serem rotacionados, e que cópias ou prints feitos por outros membros estão fora do controle do nó.

## Consequências

- O formato de `dados.json` é um contrato público e versionado.
- O estado `removido` exige um job de expiração (ADR 0017).
- O host precisa de um canal de contato para os titulares (K1, ADR 0023).
- Fica mais difícil: garantir a eliminação completa, por causa de backups, cópias nos clientes e conteúdo de terceiros que menciona o titular.
