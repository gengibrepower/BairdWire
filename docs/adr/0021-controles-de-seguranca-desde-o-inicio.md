# ADR 0021 — Controles de segurança desde o início

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O threat model (ADR 0020) deixou de fora controles que são baratos no começo e caros depois. Também ficou implícita uma decisão: como a sessão viaja. Imagens carregadas por `<img src>` não enviam o cabeçalho `Authorization`. E o WebSocket não segue CORS.

## Opções consideradas

- Sessão por **cabeçalho `Authorization`** (exige URLs assinadas para imagens) ou por **cookie `HttpOnly` + `SameSite=Strict`**.
- Incluir cada controle agora ou depois. Também foram considerados o aviso de atualização (que consulta um ponto central e conflita com a D2) e builds reprodutíveis.

## Decisão

Entram no v0.1:

- **S1.** O upgrade do WebSocket só é aceito com `Origin` igual ao do próprio nó (contra Cross-Site WebSocket Hijacking).
- **S2.** Sessão em **cookie `HttpOnly`, `Secure`, `SameSite=Strict`**.
- **S3.** Assinaturas com separação de domínio: `"bairdwire-auth-v1" ‖ origem ‖ nonce`. Nonces de uso único e curta validade. Todo token comparado em tempo constante.
- **S4.** Logging estruturado com redação de campos sensíveis. Nunca logar SDP, credenciais ICE, fingerprints DTLS, tokens ou IPs.
- **S5.** Cabeçalhos de segurança no `Caddyfile` padrão: CSP rígido, HSTS, `frame-ancestors 'none'`, `Referrer-Policy: no-referrer`, `Permissions-Policy` restrita ao próprio nó, `Cross-Origin-Opener-Policy`.
- **S6.** Notificar o titular quando um dispositivo novo for vinculado à conta e quando um link de recuperação for gerado para ela (contra o T8).
- **S7.** Reconfirmação com assinatura nova do dispositivo para ações sensíveis: excluir a conta, gerar recuperação, transferir o cargo de dono, mudar cargos.
- **S8.** Compartilhamento de tela seguro por padrão: janela como padrão (`displaySurface: "window"`), aviso explícito ao compartilhar a tela inteira e indicador permanente de compartilhamento ativo.
- **S9.** `SECURITY.md` e o canal privado de relato de vulnerabilidades do GitHub.
- **S10.** Container com usuário não-root, sistema de arquivos só de leitura (exceto o diretório de dados) e sem *capabilities*, já no `docker-compose.yml` padrão.

Ficam fora: aviso de atualização automático (P11) e builds reprodutíveis (P12).

## Consequências

- Com S1 e S2, o CSRF e o CSWSH ficam cobertos sem tokens extras. Um XSS consegue usar a sessão, mas não roubar o token.
- O formato de assinatura vira parte versionada do protocolo.
- As notificações de segurança exigem um canal de notificação dentro do app (mensagem de sistema).
- O compartilhamento de tela exige mais cuidado de UX do que o padrão do navegador.
- Fica mais difícil: depurar com `curl` (o cookie e o `Origin` precisam ser enviados) e investigar problemas sem SDP nos logs. É preciso um modo de diagnóstico local que não vá para produção.
