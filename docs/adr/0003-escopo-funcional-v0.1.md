# ADR 0003 — Escopo funcional do v0.1

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O v0.1 tem que permitir que o grupo do autor faça uma sessão real (pair programming, reunião e jogo) sem abrir o Discord (D4, ADR 0002). Cada feature a mais custa código, superfície de ataque e obrigações de LGPD e moderação (D5).

Restrição técnica relevante: a maior parte do grupo usa Linux. No Linux, o navegador não captura o áudio do sistema no compartilhamento de tela, e só o Chrome captura o áudio de uma aba. Um app desktop também não resolve: o Electron só faz loopback de áudio no Windows e no macOS, e o Tauri usa o WebKitGTK, com WebRTC fraco. A solução real é captura nativa via PipeWire.

## Opções consideradas

- **Áudio do jogo no Linux:** (A) só web, sem áudio do jogo no Linux, com a captura nativa no v0.2; (B) módulo nativo PipeWire já no v0.1.
- **Imagens no chat:** entram com limites, ou ficam fora para evitar a carga de moderação e LGPD de conteúdo enviado por usuários.
- **Câmera:** entra, fica fora, ou entra como opcional.
- **DMs, notificações, threads, reações e afins:** avaliados um a um. Ver a lista "Fora".

## Decisão

**Dentro:**
- 1 nó = 1 comunidade.
- Texto: histórico persistido, editar e apagar as próprias mensagens, Markdown, blocos de código com syntax highlight, menções com notificação local do navegador.
- **Imagens no chat**: só imagens, com limite de tamanho, retenção configurável pelo host e remoção pela moderação.
- Voz: entrar e sair, mute e deafen, indicador de quem fala, detecção de voz, com supressão de ruído e cancelamento de eco do navegador.
- Tela: um compartilhamento por canal de voz por vez, com os perfis *detalhe* e *movimento*. O áudio do jogo vai onde o navegador permitir (Chrome no Windows).
- Convite, entrada na comunidade e cargos mínimos.
- Cliente web: Chromium como alvo principal, Firefox suportado no que ele permitir.

**Opcional (se sobrar tempo):** câmera.

**Fora:** áudio do jogo no Linux e captura nativa via PipeWire (alvo: v0.2), app desktop, mobile, E2EE, federação, DMs, bots e webhooks, threads, reações, busca, gravação, push-to-talk, mais de uma tela simultânea por canal e modo P2P sem nó.

## Consequências

- O critério de pronto tem que aceitar explicitamente o compartilhamento de gameplay sem o áudio do jogo no Linux.
- O contorno (sink virtual do PipeWire exposto como entrada de microfone) precisa ser testado e documentado.
- As imagens trazem para o v0.1: armazenamento em disco no nó, cota, política de retenção, exclusão a pedido do titular (LGPD), remoção pela moderação e o risco de conteúdo ilegal no disco do host. Isso tem que entrar no modelo de dados (4.4), no threat model (4.5) e na conformidade (4.6).
- A captura nativa via PipeWire vira o marco principal do v0.2 e um arco da série.
- Fica mais difícil: convencer quem compartilha gameplay no Linux, que continua dependendo de outro app para o áudio.
