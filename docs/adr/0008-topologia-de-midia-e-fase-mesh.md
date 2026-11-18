# ADR 0008 — Topologia de mídia, spike mesh e contingência do SFU

**Status:** aceito
**Data:** 2026-11-18

## Contexto

No v0.1, toda a mídia passa pelo nó (ADR 0007), ou seja, por um SFU. A `libdatachannel` entrega o transporte (ICE, DTLS, SRTP). O resto da lógica do SFU é escrito pelo projeto: roteamento de RTP com reescrita de SSRC, sequência e timestamp; RTCP (NACK, PLI/FIR, SR/RR); estimativa de banda por espectador (TWCC/REMB); e seleção de camada (simulcast no *movimento*, temporal no *detalhe*, ADR 0005). É a parte mais educativa do projeto e também o maior risco de cronograma.

Glossário rápido: **mesh**, cada cliente envia uma cópia para cada outro (escala até 3 ou 4 pessoas). **SFU**, cada cliente envia uma vez para o servidor, que repassa sem decodificar. **MCU**, o servidor decodifica, mistura e recodifica (CPU alta).

## Opções consideradas

- **A. SFU direto.** Não joga nada fora, mas mistura o aprendizado do WebRTC do navegador com o do SFU em Zig, o que dificulta isolar bugs.
- **B. Spike mesh descartável antes do SFU.** Isola o aprendizado do lado do navegador (SDP, ICE, offer/answer, `chrome://webrtc-internals`) e sai cedo uma demo para a série. O código do signaling mesh é jogado fora.
- **C. SFU pronto temporário** (mediasoup, LiveKit). Usável cedo, mas a integração é descartável e vai contra o objetivo de aprendizado.

## Decisão

**Opção B.** Um spike mesh de **no máximo 2 semanas**: o nó só faz relay de signaling, e a chamada é de voz no navegador com 2 a 3 pessoas. Ele é **explicitamente descartável** e não entra em nenhum release. Em seguida, o SFU próprio em Zig substitui o mesh.

**Contingência:** se o SFU próprio não tiver **voz funcionando entre 3 ou mais participantes em 6 semanas** a partir do início da fase do SFU, reavaliar o uso de um SFU pronto (opção C) como ponte. O objetivo da ponte é o grupo começar a usar o produto enquanto o SFU próprio continua sendo desenvolvido.

## Consequências

- O spike mesh expõe os IPs entre os participantes. Por isso ele fica restrito a testes do autor e nunca vai para usuários (ADR 0007).
- O cliente precisa isolar a camada de transporte de mídia, para que trocar o mesh pelo SFU, ou o SFU próprio por um pronto, não afete a interface.
- O protocolo de signaling do produto é desenhado para o SFU desde o início. O do mesh é provisório.
- Se a contingência for acionada, abrir um novo ADR registrando qual SFU foi escolhido e o plano de retorno ao SFU próprio.
- Fica mais difícil: o código do spike vai para o lixo, e a contingência cria a tentação de manter a ponte para sempre.
