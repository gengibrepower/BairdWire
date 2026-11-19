# ADR 0033 — Série no YouTube

**Status:** aceito
**Data:** 2026-11-18

## Contexto

A série documenta o desenvolvimento e divulga o projeto. O autor gosta de falar de detalhes da linguagem e dos aspectos técnicos, mas **não quer fazer vídeos didáticos** (ensinar Zig, ensinar LGPD). O progresso é medido por marcos, sem datas (ADR 0013).

## Opções consideradas

- **Episódios por tema (didáticos):** boa descoberta por busca, mas viram aula. Rejeitado.
- **Devlog cronológico:** fácil de produzir, mas envelhece rápido e cria pressão de cadência.
- **Devlog por arco:** cada episódio conta um problema, as tentativas e a solução, com a profundidade técnica dentro da história.

## Decisão

- **Devlog por arco.** A profundidade técnica aparece como comentário de quem está construindo, sem tutoriais. Shorts opcionais para momentos isolados.
- **Cadência pelos arcos, não pelo calendário.** Folga de 2 a 3 episódios gravados antes de publicar.
- **Português do Brasil**, com legendas em inglês depois.
- **Tom caseiro:** é o autor contando para o mundo o que está aprendendo, sem roteiro polido nem cara de produto. Os títulos são simples, do jeito que ele falaria, sem fórmulas de engajamento. O mapa abaixo é provisório, e os títulos são só exemplos de tom:

| # | Arco | Marco | Exemplo de título |
|---|---|---|---|
| 0 | O plano e as decisões | — | "comecei a fazer meu próprio discord" |
| 1 | Build da `libdatachannel` até o primeiro eco | M0 | "tentando fazer webrtc funcionar em zig" |
| 2 | Primeira chamada e por que não escala | M1 | "fiz minha primeira chamada p2p" |
| 3 | Comunidade, chaves e tentar hackear o próprio app | M2 | "fiz o chat e tentei hackear ele" |
| 4 | SFU do zero | M3 | "escrevendo um sfu do zero" |
| 5 | Os dois perfis de tela | M4 | "compartilhamento de tela pra código e pra jogo" |
| 6 | Rede da faculdade, carga e rede ruim | — | "testei na rede da faculdade" |
| 7 | As 3 sessões reais | M5 | "usamos meu app no lugar do discord" |
| ∞ | Migração de versão do Zig (recorrente) | — | "atualizando pro zig 0.N" |

Arcos grandes podem virar mais de um episódio.

**Antes do primeiro vídeo:**
- ~~**V1.** Nome definitivo, com colisões checadas (P1).~~ Cumprido no ADR 0037: BairdWire.
- **V2.** Repositório público com `LICENSE`, `README`, `CONTRIBUTING`, `CODE_OF_CONDUCT`, `GOVERNANCE`, `SECURITY`.
- ~~**V3.** CLA Assistant configurado.~~ Saiu dos requisitos do primeiro vídeo no ADR 0036: entra antes do primeiro PR de código externo.
- **V4.** Documentos desta sessão revisados e públicos.
- **V5.** 2 a 3 episódios gravados.
- **V6.** Higiene de tela: perfil de navegador limpo, VPS e domínio de demonstração separados do nó do grupo, nenhum segredo na tela, notificações desligadas.
- **V7.** Dados do grupo fora dos vídeos (contas de teste ou consentimento).

## Consequências

- A descoberta por busca é menor que a de episódios didáticos e que a de títulos otimizados. É uma troca aceita pela autenticidade.
- Os títulos são do autor, escritos na hora, refletindo o que de fato aconteceu em cada arco.
- O episódio 0 pode ser gravado antes do M0. Os episódios 1 e 2 dependem dele.
- Fica mais difícil: manter o canal ativo durante fases longas sem progresso visível. A defesa é a folga de episódios.
