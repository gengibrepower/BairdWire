# Perguntas abertas

O que ficou para decidir depois e em que momento precisa ser decidido.

| # | Pergunta | Quando precisa estar decidida | Contexto |
|---|----------|-------------------------------|----------|
| P1 | Nome público definitivo (manter BairdWire ou trocar; candidatos: Baran, Meucci) | Antes do primeiro vídeo publicado | ADR 0001. Antes de decidir, checar colisões no GitHub, no npm, em domínios e na marca (INPI/USPTO). Depois de escolher, registrar a marca (ADR 0026). |
| P2 | O contorno para o áudio do jogo no Linux (sink virtual do PipeWire como entrada de microfone) funciona no Chrome e no Firefox? | Antes de fechar a fase de compartilhamento de tela | ADR 0003. Se funcionar, documentar para os usuários. |
| ~~P3~~ | ~~Valores padrão de tamanho máximo de imagem, cota e retenção~~ | **Resolvida no ADR 0017**: 10 MB, 5 GB e 90 dias | ADR 0003. |
| P4 | Casca do app desktop do v0.2: Electron (Chromium com flags controladas), Tauri (WebKitGTK no Linux, WebRTC fraco) ou cliente nativo, sempre com o módulo nativo em Zig para captura e encode | Antes de começar o v0.2 | ADR 0005. A casca sozinha não resolve: o ganho vem do módulo nativo. |
| P5 | A `libdatachannel` com `libjuice` suporta ICE-TCP do lado do servidor? Se não, usar `libnice` ou outra solução? | **Primeira parte respondida em 2026-11-19: não.** O `libjuice` só tem ICE-TCP ativo (`JUICE_ICE_TCP_MODE_ACTIVE`, como cliente), na v0.24.6 e no master (issue #211 aberta). Falta escolher o substituto (TURN sobre TLS, `libnice` ou ICE-TCP passivo no `libjuice`), num ADR novo, com os dados da P6 | ADR 0009. O eco do M0 funciona por UDP. |
| P6 | O que a rede da faculdade (PUCPR) bloqueia: UDP passa? Quais portas TCP passam além da 443? | Assim que for possível testar no campus, e antes da fase de compartilhamento de tela | ADR 0010. Se passar só a 443, a multiplexação na 443 dentro do nó entra no v0.1. |
| P7 | Política de compatibilidade de versões entre cliente e nó (quantas versões o nó aceita, como o cliente avisa que precisa atualizar) | Antes do primeiro release usado por mais de um grupo | ADR 0011. |
| P8 | Chave pública do nó: pinning e assinatura do convite quando houver cliente fora do nó | Antes do app desktop (v0.2) ou da federação | ADR 0015. No cliente web servido pelo nó, ela não protege nada. |
| ~~P9~~ | ~~Declaração de idade e aceite dos termos do host na tela de entrada~~ | **Resolvida nos ADRs 0023 e 0024** | ADR 0015. |
| ~~P10~~ | ~~Revisitar a escolha de linguagem do nó (D1), a pedido do autor~~ **Resolvida no ADR 0027: Zig mantido** | No bloco 4.8 (stack), antes de fechar esta sessão | Levantado durante o 4.4. Reabrir a D1 exige motivo forte: comparar Zig e alternativas com tudo o que já foi decidido. |
| P11 | Aviso de atualização disponível no nó (consulta um ponto central, o que conflita com a D2 e com a privacidade). Se existir, só opt-in | Depois do v0.1 | ADR 0021. |
| P12 | Builds reprodutíveis e verificáveis do nó e do cliente | Depois do v0.1, antes de divulgação ampla | ADR 0021. |
| P13 | Suporte a Dependency Descriptor por codec (H.264, VP8, VP9, AV1) no Chrome e no Firefox | Antes de implementar a seleção de camadas (fase 4) | ADR 0022. Se o H.264 não tiver suporte: exceção documentada ou VP9/AV1 no perfil *movimento*. |
| P14 | Revisão jurídica dos modelos (termos, política, checklist de incidentes, texto do CLA) e dos pontos "provavelmente" dos ADRs 0023 e 0024, incluindo a aplicabilidade do ECA Digital e o procedimento para material de abuso infantil (preservar ou eliminar) | Antes da divulgação ampla (e de qualquer comunidade além do grupo do autor) | Mapeamento técnico, não parecer jurídico. |
| ~~P15~~ | ~~`http.zig` e `websocket.zig` mantêm suporte à versão estável fixada do Zig (branches ou tags por versão)?~~ | **Resolvida no ADR 0034**: o `master` acompanha a estável e há branches `zig-0.N`; fixar por commit | ADR 0029. |
| ~~P16~~ | ~~Trazer a `libdatachannel` pelo gerenciador de pacotes do Zig: os tarballs de release incluem as dependências que ela puxa como submodules?~~ | **Resolvida no ADR 0034**: não incluem; cada submodule entra como dependência própria, com Mbed TLS para o DTLS | ADR 0032. |
