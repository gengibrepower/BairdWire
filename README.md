# BairdWire

Um app de comunicação estilo Discord (texto, voz e compartilhamento de tela), open source e sem dono. Cada comunidade roda o próprio nó, e não existe servidor central que alguém possa controlar ou comprar.

Estou fazendo isso pra usar com os meus grupos (pair programming, reunião de trabalho da faculdade e jogo) e pra aprender redes, WebRTC, criptografia e Zig no caminho.

> O nome é provisório.

## Status

**Planejamento.** Ainda não tem código: por enquanto só tem o escopo do v0.1 e as decisões de arquitetura.

- [Escopo do v0.1](docs/escopo.md)
- [Decisões (ADRs)](docs/adr/README.md)
- [Perguntas abertas](docs/perguntas-abertas.md)

## Como vai funcionar (resumo)

- **Nó** em Zig: signaling, SFU próprio e armazenamento em SQLite, atrás do Caddy.
- **Cliente** web em Svelte. Um app desktop vem depois.
- Login sem senha, com chave por dispositivo.
- Os dados ficam no nó da comunidade. O app não guarda IPs, histórico de chamadas nem gravação de mídia.

## Licença

- Código: [AGPL-3.0-only](LICENSE)
- Documentação e especificação do protocolo: [CC BY 4.0](LICENSE-docs)

Veja também [CONTRIBUTING](CONTRIBUTING.md), [GOVERNANCE](GOVERNANCE.md), [SECURITY](SECURITY.md) e o [Código de Conduta](CODE_OF_CONDUCT.md).
