# ADR 0004 — Limites de tamanho do v0.1

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O SFU repassa mídia sem transcodificar. Cada participante envia um stream e recebe N−1, então o upload do nó cresce com N·(N−1) para a voz e N−1 para a tela. Estimativas de upload do nó com 10 pessoas: voz ~3,6 Mbps; tela *detalhe* +~13,5 Mbps; tela *movimento* 1080p60 +~45 Mbps. Uma sessão de 2 horas com gameplay transmitido gasta ~45 GB.

O grupo real tem de 4 a 5 pessoas, e o máximo que já entrou numa chamada foi 6.

## Opções consideradas

- **A. Pequeno:** 6 por chamada e 20 membros. Sem folga em relação ao uso real (6).
- **B. Médio:** 10 por chamada e 50 membros. Folga para reuniões maiores. Exige VPS, Pi com boa conexão, ou PC com upload bom e limite de bitrate.
- **C. Grande:** 25 ou mais. Exige simulcast afinado, controle de congestionamento e testes de carga. Fora do v0.1.

## Decisão

**Opção B.** O limite **testado e garantido** é de **10 participantes por chamada** e **50 membros por comunidade**. Os dois valores são configuráveis pelo host, com padrão em 10 e 50. Acima disso não há bloqueio, mas também não há garantia.

## Consequências

- Os testes de rede e de carga precisam cobrir 10 participantes simultâneos com uma tela compartilhada em cada perfil.
- A documentação do host informa o upload necessário. O PC de casa só é recomendado com bitrate limitado.
- O mesh P2P puro não comporta esse limite com tela, então o SFU é obrigatório para a tela (detalhes no bloco 4.2).
- Fica mais difícil: rodar o nó em conexões domésticas fracas no cenário máximo.
