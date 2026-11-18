# ADR 0010 — TLS, certificado e a porta 443

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O navegador só libera microfone e captura de tela em contexto seguro (HTTPS), e o signaling precisa de `wss://`. Logo, o nó precisa de um domínio e de um certificado TLS válido.

A biblioteca padrão do Zig não tem servidor TLS, e as libs `http.zig` e `websocket.zig` recomendam ficar atrás de um proxy reverso. O fallback ICE-TCP (ADR 0009) e o HTTPS disputam a porta 443, que é a que mais passa em redes restritivas. Dá para multiplexar pelos primeiros bytes da conexão: `0x16` é TLS, e o ICE-TCP segue o framing da RFC 4571 com uma mensagem STUN.

Na mesma discussão surgiu se Go (`crypto/tls`, `autocert`, Pion) não resolveria tudo isso. Resolveria, mas a D1 foi **mantida**: o Zig é um objetivo de aprendizado, não uma escolha só técnica.

## Opções consideradas

- **A. Caddy na frente**, com TLS e certificado automático, e ICE-TCP numa porta separada. Simples e robusto, mas o ICE-TCP fora da 443 pode falhar em rede restritiva.
- **B. O nó termina o TLS** (OpenSSL ou mbedTLS via C) **e multiplexa a 443.** Um binário só, máxima compatibilidade de rede, bem mais trabalho e mais risco de segurança.
- **C. A agora, B depois se a rede real exigir.**

## Decisão

**Opção C.** No v0.1, o **Caddy** termina o TLS e gera o certificado automaticamente, repassando para o nó por HTTP local. O ICE-TCP fica numa porta TCP separada. O listener do nó é desenhado para que um multiplexador na 443 (opção B) possa ser adicionado sem reescrever o resto.

## Consequências

- A instalação padrão do host é Docker Compose com o Caddy e o nó, ou o Caddy instalado à parte com um `Caddyfile` fornecido.
- O host precisa de um domínio. A documentação deve citar opções gratuitas de subdomínio.
- Testar a rede da faculdade (P6) decide se a opção B vira trabalho do v0.1.
- O nó não tem código de TLS no v0.1. O DTLS da mídia continua na `libdatachannel`.
- O nó confia no proxy local para o IP do cliente (cabeçalho `X-Forwarded-For`). Isso precisa entrar no threat model (4.5).
- Fica mais difícil: o "binário único" deixa de ser autossuficiente no v0.1, porque depende do Caddy.
