# BairdWire

App de comunicação estilo Discord (texto, voz e compartilhamento de tela), open source e controlado pelas comunidades que o usam. Cada comunidade roda o próprio **nó**, e não existe servidor central.

Responda sempre em **português do Brasil**.

## Onde está cada coisa

- `docs/escopo.md`: o escopo fechado do v0.1 (dentro e fora, critério de pronto, fases e marcos). **Leia antes de implementar.**
- `docs/adr/`: um ADR por decisão. A decisão vale como está escrita lá. Quando um ADR é revisado por outro, vale o mais novo. Uma mudança de arquitetura ou de escopo exige um ADR novo.
- `docs/perguntas-abertas.md`: o que ainda não foi decidido e quando precisa ser decidido. Ao resolver uma pergunta, marque como resolvida e aponte o ADR.
- `docs/protocolo.md`: a especificação do protocolo (fonte da verdade). Mantenha em sincronia com os tipos em Zig e em TS.
- `docs/migracoes-zig.md`: o registro de cada migração de versão do Zig.

## Escopo do v0.1, em uma linha

Uma comunidade por nó. Texto (Markdown, código e imagens), voz e uma tela por canal, com os perfis *detalhe* e *movimento* (30 fps). Até 10 pessoas por chamada e 50 membros por comunidade. Só cliente web. Desktop, E2EE, federação e DMs ficam **fora**. Ver o ADR 0003.

## Arquitetura

- **Nó (Zig):** um binário com signaling, SFU, armazenamento e convites. Toda a mídia passa pelo nó, sem P2P (ADR 0007). Fica atrás do **Caddy**, que faz o TLS (ADR 0010).
- **Núcleo sans-IO** (`node/src/core`): Zig puro, sem I/O. Eventos entram e efeitos saem, e o tempo e a aleatoriedade são entradas. Roda como **um ator** numa thread, com uma fila MPSC. **Nunca coloque I/O dentro do núcleo.** (ADR 0029)
- **Adaptadores** (`node/src/adapters`): HTTP/WS (`http.zig`, `websocket.zig`), WebRTC (`libdatachannel` pela API C), SQLite (amalgamação) e relógio/RNG. As threads das libs só enfileiram eventos.
- **Protocolo:** um WebSocket por cliente para o tempo real, REST para o resto, JSON com o envelope `{v, t, id, re, d}` (ADR 0011). Duas PeerConnections por cliente, publish e subscribe (ADR 0012).
- **Identidade:** uma conta no nó com uma chave Ed25519 não-extraível por dispositivo, login por desafio e resposta, sem senhas (ADR 0014).
- **SFU:** decide só por cabeçalho RTP e extensões, sem ler o payload, para preparar o E2EE (ADR 0022).

## Stack

- **Zig:** a versão estável fixada em `.zig-version` e `minimum_zig_version`. Nunca o master (ADR 0028).
- **Cliente:** Svelte 5, Vite (SPA), TypeScript strict, Tailwind v4, shadcn-svelte/Bits UI, markdown-it (`html: false`), highlight.js (ADR 0030).
- **Ferramentas:** pnpm (com `minimumReleaseAge`), Biome, Vitest, Playwright.

## Convenções de código

- **Sem comentários**, a não ser para explicar um comportamento inesperado ou não óbvio. O código deve se explicar pelos nomes e pelos tipos.
- **Zig:** build de produção em `ReleaseSafe`. Arenas por requisição e por conexão. Nos testes, `std.testing.allocator`, que detecta vazamento. Tokens são comparados em tempo constante.
- **Cliente:** o **CSP rígido fica ligado também em desenvolvimento**. Nada de `unsafe-inline`, `eval`, CSS-in-JS em tempo de execução, `setAttribute('style')` ou HTML bruto no Markdown. Use as APIs nativas de WebRTC, mídia e WebCrypto, sem wrappers.
- **IDs** em UUIDv7 (`BLOB(16)`). **Tempo** em milissegundos UTC. **Migrações** só para frente, embutidas no binário (ADR 0018).
- **Nunca logar** SDP, credenciais ICE, fingerprints DTLS, tokens ou IPs (ADR 0021).
- **Minimização:** não guardar IPs, histórico de chamadas nem mídia. Apagar é hard delete (ADR 0017).
- Quem roda o nó se chama **host**. "Operador" é só o termo da LGPD (ADR 0023).

## Testes

As camadas estão no ADR 0031: unitário do núcleo, simulação determinística por seed, fuzzing, integração do protocolo (TS contra o nó real), unitário do cliente (com corpus de XSS), end-to-end com Playwright, carga com `netem` e soak. **Todo bug corrigido ganha um teste de regressão** na camada mais barata que consiga reproduzi-lo.

Cada camada entra numa fase (ADR 0041). A CI de cada PR roda as que já existem: hoje são `zig fmt --check`, `zig build test`, o build `ReleaseSafe` para x86_64 e aarch64, `biome ci`, `svelte-check`, `vitest`, `vite build` e o smoke test do deploy. Os testes do protocolo entram na fase 1.

## Workflow de git

- Branch (`feat/`, `fix/`, `docs/`, `chore/`, `zig-0.N`) → PR → CI verde → squash merge. Histórico linear. Conventional Commits.
- **Commits atômicos:** o menor possível, uma mudança por commit, e cada um compilando e passando nos testes, para facilitar o rollback e o `git bisect`.
- **Dentro da branch, os commits são livres.** Só os **importantes** pedem permissão, com um resumo antes: ADRs, regras deste arquivo, dependências e mudanças em `docs/protocolo.md` (ADR 0039).
- **Sem trailer de co-autoria e sem `Signed-off-by`.** O projeto vai usar um CLA quando abrir as contribuições externas (ADRs 0026 e 0036).
- **Nunca** fazer push. **Nunca** abrir PR. Push, PR e merge são do autor.
- O bloqueio de push, PR e `git reset --hard` está em `.claude/settings.json`. Os hooks em `.claude/hooks/` bloqueiam a implementação nas áreas do autor, formatam o que foi editado e rodam os testes da parte que mudou antes de encerrar uma tarefa. Se um hook bloquear, corrija a causa; não contorne o hook.

## Como atuar

- **Modo tutor:** explicar o porquê de cada opção e os trade-offs.
- **Uma decisão por vez:** apresentar as opções, dar uma recomendação e **esperar a decisão** antes de registrar.
- **Discordar quando for o caso**, de forma direta e tecnicamente precisa.
- Se uma tarefa depender de uma pergunta aberta (`docs/perguntas-abertas.md`), avisar antes de seguir.

## Quem escreve o quê

Ver o ADR 0040.

- **O autor escreve** `node/src/core/`, `node/src/runtime.zig`, `node/src/adapters/` e `node/src/main.zig`. Nessas áreas, explique, revise e escreva testes (`*_test.zig`), mas **não escreva a implementação**, nem quando o autor pedir só um trecho. Mostre o caminho e deixe o autor escrever.
- **Livre:** `node/build/`, `build.zig`, `deploy/`, `.github/`, `client/` e os testes de integração em TypeScript.
- **Contrato:** mudanças em `docs/protocolo.md` passam pelo autor antes. Implemente a partir do contrato, sem mudá-lo sozinho.

## Plano antes do código

Para tarefas grandes (mais de um commit, ou qualquer coisa que toque o protocolo ou uma área do autor), escreva primeiro um plano com os requisitos, os ADRs envolvidos, os passos e as perguntas de decisão, e espere a revisão do autor antes de implementar. O plano fica fora do repositório, numa nota do vault do autor.

## Ferramentas do assistente

- **Antes de usar qualquer API da std do Zig, consulte o MCP `zig-docs`** (zig-mcp, com a documentação da std instalada). A std muda entre versões, e a memória do modelo erra. Para Svelte 5, Tailwind v4 e Bits UI, consulte o MCP `context7`.
- **Comandos:** `/adr` (rascunha um ADR e só grava com aprovação), `/pergunta` (leva uma pergunta aberta até a decisão), `/fase` (o que falta para o próximo marco), `/plano <issue>` (nota de plano no vault, antes de implementar) e `/revisar` (subagente revisor no diff da branch).
- **`just`:** `just test` roda os testes, `just check` roda o mesmo que a CI e `just dev` sobe o nó e o cliente. O pre-commit (lefthook) confere a formatação.
