# ADR 0006 — Critério de pronto do v0.1

**Status:** aceito
**Data:** 2026-11-18

## Contexto

Um critério vago ("funciona bem") deixa o v0.1 sem fim. O objetivo é que o grupo do autor substitua o Discord em sessões reais (ADR 0002, ADR 0003), e que hospedar um nó não dependa do autor (D2).

## Opções consideradas

- **Uma única sessão de aceitação.** Mais leve, mas pode passar por sorte.
- **Três sessões em semanas diferentes, mais requisitos mensuráveis.** Mostram que o uso real é sustentável.
- **Critério subjetivo** ("o grupo gostou"). Descartado por não ser verificável.

## Decisão

**1. Sessão de aceitação**, feita **3 vezes, em semanas diferentes**. O grupo (4 a 6 pessoas, misturando Linux e Windows) usa o BairdWire sem abrir o Discord, com o nó numa VPS:
- reunião de ~1 hora com Google Docs ou Slides compartilhados no perfil *detalhe*;
- pair programming de ~30 minutos com código legível na tela, e código e prints colados no chat;
- ~1 hora de jogo com gameplay transmitido no perfil *movimento* a 30 fps, sem atrapalhar o jogo de quem joga.

**2. Requisitos mensuráveis:**
- O nó roda 7 dias seguidos sem reiniciar e sem vazamento de memória.
- O teste automatizado de carga com 10 participantes e uma tela compartilhada atinge as metas do ADR 0005.
- Depois de uma queda de rede de até 30 segundos, o cliente se reconecta sozinho e volta para o canal de voz.
- Um dev do grupo que não seja o autor sobe um nó novo só com a documentação, em menos de 30 minutos.
- O convite funciona de ponta a ponta para quem nunca usou o BairdWire.
- Pelo menos uma sessão (ou um teste de voz e tela) funciona **a partir da rede da faculdade** (incluído pelo ADR 0009).
- A exportação e a exclusão de dados do titular (LGPD) funcionam.

**3. Não é critério:** áudio do jogo no Linux, 60 fps, câmera, desempenho acima de 10 participantes.

## Consequências

- O host-alvo do nó é **um dev**: simples de subir para quem programa, sem exigir conhecimento de redes ou de sysadmin. Usuário leigo como host fica para depois.
- A documentação de instalação do nó é um entregável do v0.1, não um extra.
- É preciso ter infraestrutura de teste de carga com 10 clientes simulados e a medição das metas de latência, fps e sincronia.
- Reconexão automática e estabilidade em execução longa entram no design desde cedo.
- Fica mais difícil: o v0.1 leva no mínimo 3 semanas de uso real depois que estiver com todas as features.
