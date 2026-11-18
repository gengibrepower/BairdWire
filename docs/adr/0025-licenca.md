# ADR 0025 — Licença

**Status:** aceito
**Data:** 2026-11-18

## Contexto

A filosofia "anti empresa maligna" e a D3 pedem que ninguém consiga fechar o código e vendê-lo como serviço. Uma licença não comercial não é open source pela definição da OSI e usa um conceito ambíguo de "comercial". Em 2023 o Element trocou Apache-2.0 por AGPL-3.0 justamente por causa de SaaS fechados construídos sobre o código.

Compatibilidade das dependências planejadas com AGPL-3.0: `libdatachannel` e `libjuice` (MPL-2.0) ✅, OpenSSL 3 (Apache-2.0) ✅, `libsrtp` (BSD) ✅, SQLite (domínio público) ✅, `libxev`, `http.zig` e `websocket.zig` (MIT) ✅.

## Opções consideradas

- **MIT / Apache-2.0:** permite forks fechados.
- **GPL-3.0:** deixa aberta a brecha do SaaS (rodar como serviço não é distribuir).
- **AGPL-3.0:** fecha a brecha do SaaS.
- **Não comercial:** viola a D3.
- **AGPL-3.0-only** contra **-or-later**.

## Decisão

- **Código do nó e do cliente: AGPL-3.0-only.**
- **Especificação do protocolo e documentação: CC BY 4.0**, para que implementações alternativas (clientes, nós, bots) possam existir com qualquer licença.
- O cliente mostra um link **"Código-fonte"** que aponta para a versão em execução. A URL é configurável no build, para hosts que modificam o nó.

## Consequências

- Quem oferece um nó modificado pela rede precisa disponibilizar o código modificado aos usuários.
- Empresas com política anti-AGPL não vão usar nem contribuir.
- O protocolo pode sobreviver ao código e permite um ecossistema de implementações.
- Cada nova dependência precisa ser compatível com AGPL-3.0. A compatibilidade é conferida de novo ao fixar a stack (4.8).
- Licenciamento comercial duplo só seria possível com CLA (ver o ADR de contribuição).
- Fica mais difícil: adoção corporativa, e incorporar código de projetos com licenças incompatíveis (por exemplo, GPL-2.0-only).
