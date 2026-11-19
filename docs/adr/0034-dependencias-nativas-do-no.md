# ADR 0034 — Dependências nativas do nó e biblioteca de TLS

**Status:** aceito
**Data:** 2026-11-19

## Contexto

O ADR 0032 decidiu trazer a `libdatachannel` pelo gerenciador de pacotes do Zig, sem submodules, e deixou em aberto se os tarballs de release incluem as dependências (P16). O ADR 0029 deixou em aberto se `http.zig` e `websocket.zig` acompanham a versão estável do Zig (P15). O ADR 0028 manda fixar a estável vigente, confirmada na instalação.

O que foi verificado em 2026-11-19:

- **Zig:** a estável é a 0.17.1 (2026-11-02). A 0.18 ainda não saiu e não traz nenhuma mudança grande de I/O (a do `std.Io` foi na 0.16). Ela traz parênteses obrigatórios em precedências ambíguas, com `zig fmt --upgrade`, e metadados opcionais (`.version`, `.paths`) para pacotes sem `build.zig.zon`.
- **`http.zig` e `websocket.zig`:** o `master` acompanha a última estável, e existem branches `zig-0.N` para as anteriores. O `websocket.zig` migrou para a 0.17 três dias depois da release. Não há tags de versão. O `http.zig` depende do `websocket.zig`.
- **`libdatachannel` v0.24.6** (2026-09-26): não publica assets, e o tarball gerado pelo GitHub vem com `deps/` vazio. Os submodules necessários são `libjuice`, `libsrtp`, `usrsctp` e `plog`. O `nlohmann/json` só é usado nos exemplos.
- **TLS:** a `libdatachannel` exige uma biblioteca de TLS para o DTLS (OpenSSL, Mbed TLS ou GnuTLS), que não vem nos submodules, e o libsrtp usa a mesma como motor de cripto.
- **Mbed TLS:** a 3.6 LTS tem suporte até março de 2027. A 4.1 LTS, até março de 2029. A v0.24.6 só aceita a 3.x. O suporte à 4.x (PSA Crypto) entrou no master da `libdatachannel` em 2026-08-07 (PR #1599) e ainda não saiu em release.
- **`libdatachannel` 0.25:** ainda não lançada, com o master 248 commits à frente da v0.24.6. Inclui os atributos de simulcast do RFC 8851 (PR #1510), relevantes para a fase 4.

## Opções consideradas

- **Dependências da `libdatachannel`:** cada submodule como uma dependência própria no `build.zig.zon`, ou biblioteca do sistema.
- **TLS:** OpenSSL, que é o padrão da lib e o caminho mais testado, mas cujo build em Perl empurra para a lib do sistema e atrapalha o binário estático e a compilação cruzada. Mbed TLS 3, em C simples, compilável pelo `zig build`. GnuTLS, que puxa nettle e gmp e é a mais difícil de compilar pelo Zig.

## Decisão

- **Zig 0.17.1**, em `.zig-version` e `minimum_zig_version`.
- **`http.zig` e `websocket.zig`:** fixados por commit e hash no `build.zig.zon`, a partir do `master` compatível com a 0.17.
- **`libdatachannel` v0.24.6** no M0, com `libjuice`, `libsrtp`, `usrsctp` e `plog` como dependências próprias no `build.zig.zon`. Cada uma aponta para o `archive/<sha>.tar.gz` do commit que o submodule fixa naquela tag. Tudo é compilado por um `build.zig` próprio, sem CMake. Os commits da v0.24.6 são:
  - `libjuice` `b89c792e3612faf2f12cf35bcc56857313a06be3`
  - `libsrtp` `24b3bf8f19b6f5ab4cd2bcceb4f4064efca86fd5`
  - `usrsctp` `fec583d54493f879d2ae44a743423bf8a04371ab`
  - `plog` `94899e0b926ac1b0f4750bfbd495167b4a6ae9ef`
- **TLS: Mbed TLS**, compilada pelo `zig build`, também como motor de cripto do libsrtp (com GCM). Na v0.24.6, a **3.6.8 LTS**.
- **Plano B:** a OpenSSL do sistema, se o Mbed TLS travar o M0.
- **Atualização da `libdatachannel` antes da fase 4 e antes de março de 2027**, o que vier primeiro: para a 0.25 (ou um commit fixado do master, se ela não sair), junto com a **Mbed TLS 4.1 LTS**. É uma migração só, numa branch dedicada, como as do Zig (ADR 0028).

## Consequências

- O nó sai como um binário estático, com compilação cruzada para x86_64 e aarch64 pelo `zig build`, sem depender da OpenSSL do host. A P16 está resolvida.
- A P15 está resolvida. O risco das libs Zig de terceiros diminui, mas as duas são do mesmo autor e formam uma única cadeia, o que reforça o adaptador e o plano B da `std` (ADR 0029).
- A cada atualização da `libdatachannel`, os commits e hashes dos 4 submodules precisam ser atualizados à mão. O `build.zig` próprio precisa acompanhar a lista de fontes e as opções do CMake do upstream.
- Mbed TLS com `libdatachannel` é menos usado que OpenSSL. Problemas conhecidos:
  - a 3.6 só aceita ClientHello DTLS fragmentado a partir da correção de 2026-03 (o Firefox fragmenta com frequência). Por isso a versão mínima é a 3.6.6. O E2E com Firefox (ADR 0031) cobre esse caso;
  - na 4.x, sem `MBEDTLS_THREADING_C` as chamadas PSA não são thread-safe. A configuração do build precisa habilitar essa opção.
- A 3.6 perde suporte em março de 2027. A migração para a 4.1 tem prazo, não é opcional.
- Com o Zig 0.18, os metadados de pacotes nus podem reduzir e estabilizar os hashes dessas dependências. É opt-in e entra na migração da 0.18.
- A P5 (ICE-TCP no `libjuice`) continua aberta e é respondida no M0.
- Fica mais difícil: depender de um `build.zig` mantido por nós para uma lib C++ com 5 dependências C, em vez do CMake oficial.
