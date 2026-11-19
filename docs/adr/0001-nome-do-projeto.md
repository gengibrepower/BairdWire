# ADR 0001 — Nome do projeto

**Status:** aceito. Nome confirmado como definitivo no ADR 0037
**Data:** 2026-11-18

## Contexto

O projeto precisa de um nome estável para os documentos, o repositório, o namespace do módulo Zig, o pacote do cliente e o binário do nó. O nome público também vai para a série no YouTube, e trocá-lo depois da divulgação custa caro.

O diretório de trabalho já se chama **BairdWire**, uma referência a John Logie Baird, autor da primeira transmissão de TV. O critério de preferência é um nome em inglês que faça referência a um inventor ou a um monumento.

## Opções consideradas

- **BairdWire.** É distinto e já está em uso. Problemas: "Wire" coincide com o Wire, um mensageiro E2EE da mesma categoria. A pronúncia é difícil em português. A TV é uma metáfora de broadcast centralizado, o oposto do modelo do projeto.
- **Nomes em português** (Mutirão, Roda, Taba, Varanda). Descartados por preferência do autor.
- **Baran** (Paul Baran, redes distribuídas). É o que mais combina com a filosofia, e o diagrama centralizado/descentralizado/distribuído explica a arquitetura.
- **Meucci** (inventor do telefone a quem Bell tirou o crédito). Tem uma narrativa "anti empresa".
- **Engelbart** (Mother of All Demos, com videoconferência e tela compartilhada). É longo para o CLI.
- **Lamarr, Pnyx, Pharos.** Têm risco de colisão ou são difíceis de pronunciar.
- **Agora.** Descartado: colide com a Agora.io, uma empresa de RTC.

## Decisão

Manter **BairdWire** como nome provisório. O identificador técnico é `bairdwire`.

## Consequências

- Documentos, repositório e código usam `bairdwire` desde já.
- O nome público definitivo continua em aberto (ver `perguntas-abertas.md`). Baran e Meucci são os candidatos preferidos caso haja troca.
- Para facilitar uma troca, o nome não deve ficar espalhado em formatos de protocolo, chaves de armazenamento ou identificadores persistidos. Ele fica centralizado em configuração de build e metadados.
- Fica mais difícil: se o nome mudar depois de vídeos publicados, perde-se reconhecimento e é preciso redirecionar repositório, pacote e domínio.
