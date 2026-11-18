# ADR 0022 — Criptografia por fase, visibilidade do host e preparação para E2EE

**Status:** aceito
**Data:** 2026-11-18

## Contexto

No v0.1 a criptografia é por salto: TLS até o nó e DTLS-SRTP entre cada cliente e o SFU. O nó decifra a mídia para repassá-la, e o texto fica em claro no banco. O E2EE futuro usa SFrame para a mídia e MLS para o texto e as chaves de grupo.

Com SFrame, o payload do frame fica cifrado. Um SFU que lê o payload do codec (descritor VP8, NAL units H.264) para achar keyframes e camadas deixa de funcionar. A extensão RTP **Dependency Descriptor** leva essas informações no cabeçalho.

## Opções consideradas

- **A.** O SFU pode ler o payload do codec. É mais fácil no v0.1, mas obriga a reescrever a seleção de camadas quando vier o E2EE.
- **B.** O SFU decide só por cabeçalho RTP e extensões. Dá um pouco mais de trabalho e depende do suporte dos navegadores.

## Decisão

**Criptografia por fase:**

| Fase | Texto e API | Mídia | Em repouso |
|---|---|---|---|
| 0. Eco | TLS | DTLS-SRTP navegador ↔ nó | — |
| 1. Spike mesh | TLS | DTLS-SRTP navegador ↔ navegador | — |
| 2. Texto | TLS, login Ed25519 | — | Texto e imagens em claro |
| 3 e 4. SFU | TLS | DTLS-SRTP por salto (o nó decifra e cifra de novo) | Mídia nunca gravada |
| Futuro | MLS | SFrame sobre SRTP | Texto cifrado |

**Visibilidade do host no v0.1** (texto oficial para a página "Seus dados neste nó"):
- **Consegue:** ler mensagens e imagens; ver metadados de presença e chamadas; gravar chamadas e registrar IPs se modificar o nó; vincular um dispositivo falso a qualquer conta (o nó é a autoridade das contas).
- **Não consegue:** obter as chaves privadas dos dispositivos, ver chamadas passadas não gravadas, forjar assinaturas de usuários.
- As chaves por dispositivo protegem contra vazamento de banco e phishing. **Não protegem contra o host.** Isso só virá com E2EE e verificação de chaves entre membros.

**Regras de preparação para E2EE:**
1. **O SFU decide só por cabeçalho RTP e extensões** (opção B). Usa Dependency Descriptor onde o navegador suporta. Qualquer leitura de payload é uma exceção documentada, por codec.
2. **O nó não depende do corpo das mensagens** para funcionar. Os metadados necessários vão em campos próprios (por exemplo, `mentions: [ids]`).

## Consequências

- O SFU fica pronto para o SFrame sem reescrever a seleção de camadas.
- É preciso verificar o suporte a Dependency Descriptor por codec e navegador (P13). Se o H.264 não tiver suporte, ou ele vira uma exceção documentada, ou o perfil *movimento* reconsidera VP9 ou AV1.
- O protocolo de mensagens tem campos de metadados separados do corpo.
- Fica mais difícil: usar exemplos e código de SFUs que fazem parsing de payload. E o nó não pode "consertar" menções malformadas lendo o texto.
