# ADR 0020 — Threat model do v0.1

**Status:** aceito
**Data:** 2026-11-18

## Contexto

A D5 exige segurança desde o design. O nó fica exposto à internet, escrito em Zig (que não é memory-safe em `ReleaseFast`) e com a `libdatachannel` e o OpenSSL (C/C++) tratando DTLS e SRTP de qualquer origem. O cliente web é servido pelo nó (ADR 0015), e a chave do dispositivo é não-extraível mas utilizável por qualquer script que rode na página (ADR 0014). O SFU decifra o SRTP para repassar a mídia.

## Opções consideradas

Cada ameaça foi classificada como **dentro** (com defesa no v0.1) ou **fora** (risco aceito e documentado).

## Decisão

**Dentro do v0.1:**

| # | Atacante | Ameaça | Defesa |
|---|---|---|---|
| T1 | Rede | Interceptação ou alteração | TLS (Caddy) e DTLS-SRTP |
| T2 | Internet contra o nó | Bug de memória nos parsers (JSON, SDP, RTP, RTCP, STUN) | Produção em `ReleaseSafe`, fuzzing dos parsers, arenas por requisição e por conexão, dependências C/C++ atualizadas |
| T3 | Internet contra o nó | Esgotar recursos | Limites de tamanho de mensagem, conexões por IP (em memória), rate limiting por conta, cota de upload |
| T4 | Membro | XSS por Markdown ou nome (equivale a sequestro de conta) | Renderizador sem HTML bruto e CSP rígido, só com scripts do próprio nó e sem `unsafe-inline` |
| T5 | Membro | Imagem maliciosa (SVG, poliglota, bomba de descompressão) | Só PNG, JPEG, WebP e GIF, com magic bytes conferidos. `Content-Type` fixo e `nosniff`. Nunca SVG. O nó não decodifica imagens. |
| T6 | Membro descuidado | Vazamento de localização por EXIF | O cliente reencoda a imagem antes do upload (best-effort) |
| T7 | Membro | Flood e spam | Rate limiting por conta e remoção pelo admin |
| T8 | Admin | Tomar a conta de outros | Recuperação hierárquica e auditoria (ADR 0016) |
| T9 | Dispositivo roubado | Uso da sessão | Revogação de dispositivo e expiração de sessão |
| T10 | Cadeia de suprimentos | Dependência comprometida | Poucas dependências, lockfile, versões fixas, revisão antes de atualizar |

**Fora do v0.1 (risco aceito):**
- **Host malicioso:** lê o banco e, modificando o nó, pode gravar chamadas, porque o SFU decifra o SRTP. Só o E2EE (SFrame e MLS) resolve. A interface avisa: "o host deste nó tem acesso técnico às suas mensagens e chamadas".
- **Domínio ou TLS do nó comprometidos:** o atacante serve o JavaScript que quiser.
- **Análise de tráfego e metadados.**
- **DDoS volumétrico:** responsabilidade do provedor.
- **Malware no dispositivo do usuário.**
- **Atacante com recursos de Estado.**

## Consequências

- O build de produção é `ReleaseSafe`, e o fuzzing dos parsers faz parte da estratégia de testes (4.8).
- O renderizador de Markdown e o CSP são requisitos de segurança, não detalhe de UI.
- O aviso sobre o host é parte obrigatória da interface e da página "Seus dados neste nó".
- O E2EE é a evolução natural para reduzir os riscos que ficaram fora.
- Fica mais difícil: usar bibliotecas de front-end que exijam `unsafe-inline` ou `eval`, e aceitar formatos de imagem além dos quatro permitidos.
