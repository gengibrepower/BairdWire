# ADR 0023 — Papéis na LGPD e kit de conformidade do host

**Status:** aceito
**Data:** 2026-11-18
**Vigência:** os papéis e o termo *host* valem já; o kit K1 a K7 entra a partir da fase 2 e é auditado no M5 (ADR 0013)

> Mapeamento técnico, não parecer jurídico. Os pontos marcados como "provavelmente" precisam de confirmação jurídica antes de virarem promessa pública.

## Contexto

Não há servidor central (D2): cada comunidade roda o próprio nó. A D5 pede conformidade com a LGPD desde o design. Até aqui, os ADRs chamavam de "operador" quem roda o nó, mas na LGPD "operador" (art. 5º, VII) é quem trata dados em nome do controlador, o que gera confusão nos documentos de conformidade.

O art. 4º, I exclui da LGPD o tratamento feito por pessoa natural para fins exclusivamente particulares e não econômicos. A Resolução CD/ANPD nº 2/2022 simplifica as obrigações de agentes de pequeno porte.

## Opções consideradas

- **Papéis:** o projeto como controlador ou operador, contra o host como controlador.
- **Terminologia:** manter "operador" ou renomear para "host".
- **Kit de conformidade:** completo no v0.1 ou parcial (adiando o relatório do art. 37 e o apoio a incidentes).

## Decisão

**Papéis:**
- **Controlador:** o **host do nó**, a pessoa ou organização que decide rodar o nó, configura a retenção e aceita membros.
- **Operador (LGPD):** o provedor de infraestrutura (VPS).
- **Titular:** cada membro.
- **Projeto BairdWire e autor:** nenhum papel. Distribuem software e não tratam dados de usuários.

**Terminologia:** quem roda o nó passa a se chamar **host**. Os ADRs anteriores foram ajustados. "Operador" fica reservado ao sentido da LGPD.

**Aplicabilidade:** um nó rodado por uma pessoa para um grupo de amigos, sem fim econômico, provavelmente está fora da LGPD (art. 4º, I). O software ainda assim oferece as ferramentas para hosts sujeitos à lei.

**Kit de conformidade no v0.1:**
- **K1.** Página "Seus dados neste nó", gerada a partir da configuração real (retenções, dados guardados, visibilidade do host do ADR 0022), com campos que o host preenche (controlador, contato, finalidade).
- **K2.** Modelos de termos de uso e de política de privacidade em português, marcados como modelo e não como aconselhamento jurídico. Base legal sugerida: execução de contrato (art. 7º, V). O host pode alterar.
- **K3.** Aceite dos termos na entrada (com a declaração de idade do ADR 0024).
- **K4.** Ferramentas de direitos do titular (ADR 0019).
- **K5.** `bairdwire compliance report`: registro das operações de tratamento (art. 37) gerado a partir da configuração.
- **K6.** Apoio a incidentes (art. 48): comando para enviar um aviso a todos os membros e checklist com prazos e o que comunicar à ANPD.
- **K7.** Documentação sobre transferência internacional (art. 33) quando a VPS fica fora do Brasil.

## Consequências

- O projeto não assume obrigações de controlador ou de operador. Um benefício jurídico direto da D2.
- Os documentos do usuário e do host usam "host". A CLI não muda.
- Os modelos jurídicos (K2) precisam de revisão por um advogado antes da divulgação ampla (P14).
- K5 e K6 adicionam comandos de CLI e documentação ao escopo da fase 5.
- Fica mais difícil: manter os modelos e a checklist atualizados com a regulamentação da ANPD.
