# ADR 0005 — Qualidade-alvo do compartilhamento de tela e latência

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O ADR 0002 definiu dois perfis de compartilhamento: *detalhe* (código e documentos) e *movimento* (gameplay). Cada perfil degrada de um jeito diferente quando a rede aperta e prefere um codec diferente.

No navegador, o encode por hardware não é controlado pela aplicação. O cliente só pede o codec. O Chrome no Windows costuma usar a GPU. No Linux, o encode por hardware no WebRTC (VA-API) é experimental e cai para software na maioria das máquinas, o que compete por CPU com o jogo.

## Opções consideradas

- *Movimento* a **30 fps garantido, 60 opcional**: ~25 Mbps de upload do nó com 10 pessoas. Viável com encode por software no Linux.
- *Movimento* a **60 fps como meta**: ~45 Mbps de upload do nó. Pouco realista sem encode por hardware garantido, ou seja, sem um módulo nativo.

## Decisão

| | Detalhe | Movimento |
|---|---|---|
| Resolução | Nativa até 1440p | 1080p, podendo cair para 720p |
| fps | 5 a 15 | **30 garantido**, 60 opcional sem garantia |
| Bitrate típico | 1 a 2,5 Mbps | 3 a 6 Mbps |
| Codec preferido | VP9 ou AV1 | H.264 (para usar o hardware quando o navegador permitir) |
| `degradationPreference` | `maintain-resolution` | `maintain-framerate` |
| Adaptação por espectador | Escalabilidade temporal (SVC L1T3) | Simulcast por resolução |

Latência: voz **< 200 ms** de ponta a ponta. Tela **< 400 ms**. Diferença entre áudio e vídeo **≤ 100 ms**.

Condição de teste: 10 participantes, rede doméstica comum, nó numa VPS.

## Consequências

- A fase do SFU precisa de escalabilidade temporal para o *detalhe*, não só de simulcast.
- O SFU precisa aceitar codecs diferentes por perfil. Todos os navegadores-alvo decodificam H.264, VP8, VP9 e AV1.
- Encode por hardware garantido, 60 fps fluido e áudio do jogo no Linux ficam para o **app desktop do v0.2**, com captura e encode nativos (PipeWire e VA-API ou NVENC).
- Fica mais difícil: no v0.1, quem transmite jogo no Linux sente a CPU pesar e pode precisar baixar para 720p30.
