# ADR 0013 — Fases e marcos do v0.1

**Status:** aceito
**Data:** 2026-11-18

## Contexto

A topologia está definida (ADRs 0007 a 0012). O maior risco técnico inicial é integrar o Zig com a `libdatachannel` (C++): build pelo `zig build`, API C, convivência do event loop com as threads da lib. A D5 exige que segurança e LGPD sejam feitas desde o design, não num remendo no final.

## Opções consideradas

- **Ordem original:** signaling e mesh → texto → SFU → tela.
- **Risco primeiro:** uma fase 0 com teste de eco WebRTC no nó antes de tudo.
- **SFU antes do texto**, contra **texto antes do SFU**. O texto constrói identidade, sessões, token de reconexão, persistência e WebSocket robusto, de que o SFU depende, e dá uso real mais cedo.
- **Com datas** ou **só com marcos**.

## Decisão

| Fase | Entrega | Marco |
|---|---|---|
| 0. Fundação | Monorepo, CI, `zig build` com `libdatachannel`, Caddy e Compose, WebSocket com `hello`, teste de eco de áudio pelo nó | **M0:** o nó em Zig fala WebRTC |
| 1. Spike mesh (≤ 2 semanas, descartável) | Voz entre 2 e 3 navegadores, nó só como relay de signaling | **M1:** primeira chamada |
| 2. Comunidade e texto | Identidade e convite, canais, mensagens em SQLite, Markdown e código, menções, imagens com retenção e exclusão, cargos | **M2:** o grupo usa o chat de verdade |
| 3. SFU de voz | Duas PeerConnections, repasse de RTP, NACK e PLI, estados, reconexão. Começa a contagem da contingência de 6 semanas (ADR 0008) | **M3:** voz pelo SFU com 3 ou mais pessoas |
| 4. Tela | Perfis *detalhe* e *movimento*, simulcast, camada temporal, TWCC, tela sob demanda | **M4:** pair programming e gameplay pelo SFU |
| 5. Aceitação | Carga com 10 pessoas, 7 dias de estabilidade, rede da faculdade, documentação do host, auditoria de LGPD, 3 sessões reais (ADR 0006) | **M5:** v0.1 aceito |
| Opcional | Câmera | — |

**Sem datas**: o progresso é medido só pelos marcos.

## Consequências

- O M0 responde cedo à P5 (ICE-TCP) e expõe os problemas de build e de FFI.
- Cada fase entrega a parte de segurança e LGPD que lhe cabe. A fase 5 verifica, não implementa.
- Entre o M2 e o M3, o grupo pode usar o chat do BairdWire junto com a voz do Discord, o que gera feedback real cedo.
- Sem datas, o risco é o escopo crescer sem ninguém perceber. A defesa é o ADR 0003 e a regra de que entrar algo novo no v0.1 exige um novo ADR.
- Fica mais difícil: prever quando o v0.1 fica pronto, para a série ou para o grupo.
