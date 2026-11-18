# Escopo do v0.1 — BairdWire

> Documento vivo durante a sessão de definição de escopo. Seções marcadas *(pendente)* ainda não foram decididas.

## Objetivo

Voz, tela e chat para grupos pequenos que trabalham e jogam juntos, com foco em quem programa (ADR 0002). O v0.1 serve ao grupo do autor, universitários e devs, e substitui o Discord em sessões de pair programming, reuniões de projeto e jogo.

Sem servidor central: cada comunidade roda o próprio nó (D2).

## Dentro do v0.1

Ver o ADR 0003.

- 1 nó = 1 comunidade
- Texto: histórico, editar e apagar, Markdown, blocos de código com highlight, menções com notificação local
- Imagens no chat, com limite de tamanho, retenção configurável e remoção pela moderação
- Voz com detecção de voz, mute e deafen, indicador de fala
- Compartilhamento de tela, um por canal de voz, com os perfis *detalhe* e *movimento*
- Convite, entrada e cargos mínimos
- Cliente web (Chromium principal, Firefox no que ele permitir)

**Opcional:** câmera, se sobrar tempo.

## Fora do v0.1

Áudio do jogo no Linux e captura nativa via PipeWire (v0.2), app desktop, mobile, E2EE, federação, DMs, bots e webhooks, threads, reações, busca, gravação, push-to-talk, várias telas simultâneas e modo P2P sem nó.

## Limites de tamanho

Ver o ADR 0004. **Testado e garantido:** 10 participantes por chamada e 50 membros por comunidade, configuráveis pelo host. O uso real hoje é de 4 a 6 pessoas por chamada.

## Qualidade-alvo do compartilhamento de tela

Ver o ADR 0005.

- **Detalhe:** nativa até 1440p, 5 a 15 fps, VP9 ou AV1, mantém a resolução.
- **Movimento:** 1080p, **30 fps garantido** (60 opcional), H.264, mantém o fps.
- **Latência:** voz < 200 ms, tela < 400 ms, diferença entre áudio e vídeo ≤ 100 ms.
- Encode por hardware garantido e 60 fps ficam para o app desktop do v0.2.

## Critério de pronto

Ver o ADR 0006.

- **3 sessões reais em semanas diferentes** (reunião, pair programming e jogo) sem abrir o Discord, com o nó numa VPS.
- Nó estável por 7 dias, teste de carga com 10 participantes dentro das metas, reconexão automática depois de queda de até 30 segundos.
- Outro dev sobe um nó em menos de 30 minutos só com a documentação.
- Funciona a partir da rede da faculdade.
- Convite de ponta a ponta. Exportação e exclusão de dados (LGPD).

## Fases e marcos

Ver o ADR 0013. Sem datas: o progresso é medido pelos marcos.

| Fase | Marco |
|---|---|
| 0. Fundação, com eco WebRTC no nó em Zig | M0: o nó em Zig fala WebRTC |
| 1. Spike mesh (≤ 2 semanas, descartável) | M1: primeira chamada |
| 2. Comunidade e texto | M2: o grupo usa o chat de verdade |
| 3. SFU de voz (contingência de 6 semanas) | M3: voz pelo SFU com 3 ou mais pessoas |
| 4. Tela | M4: pair programming e gameplay pelo SFU |
| 5. Aceitação | M5: v0.1 aceito |

Cada fase entrega a sua parte de segurança e LGPD (D5). Qualquer adição ao escopo do v0.1 exige um novo ADR.
