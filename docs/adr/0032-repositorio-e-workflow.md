# ADR 0032 — Repositório, workflow e CI

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O projeto tem um nó em Zig, um cliente Svelte, testes em várias camadas (ADR 0031), artefatos de deploy (Caddy, Docker) e documentação. O autor usa nos outros projetos o fluxo branch → PR → squash merge, com o CI como gate e histórico linear. A `libdatachannel` depende de submodules próprios (`libjuice`, `libsrtp`, `usrsctp`, `plog`).

## Opções consideradas

- **`libdatachannel`:** gerenciador de pacotes do Zig, git submodule, ou biblioteca do sistema.
- **Versionamento:** versões separadas para o nó e o cliente, ou uma versão única.

## Decisão

**Estrutura:**
```
node/ (src/core, src/adapters, src/cli, migrations, vendor, sim)
client/
tests/ (protocol, e2e)
deploy/ (Dockerfile, docker-compose.yml, Caddyfile)
docs/ (escopo, adr, protocolo, perguntas-abertas, migracoes-zig)
.github/workflows/
LICENSE, LICENSE-docs, README, CONTRIBUTING, CODE_OF_CONDUCT, GOVERNANCE, SECURITY
.zig-version, pnpm-workspace.yaml, CLAUDE.md
```

**`libdatachannel`:** pelo gerenciador do Zig (URL e hash no `build.zig.zon`, compilada por um `build.zig` próprio). Atalho temporário: a biblioteca do sistema, se o build travar no M0. Sem submodules (P16).

**Workflow:**
- `main` protegida. Mudanças só por PR, com o CI verde, por squash merge, histórico linear.
- Branches `feat/`, `fix/`, `docs/`, `chore/`, `zig-0.N`.
- Conventional Commits. O título do PR vira o commit do squash.
- Sem trailer de co-autoria e sem `Signed-off-by` (CLA, ADR 0026).

**Versionamento:**
- O **produto** (nó e cliente juntos) usa SemVer `0.MINOR.PATCH`. **`v0.1.0` = M5.** Os marcos intermediários são pré-releases (`0.1.0-alpha.N`).
- Versões independentes, cada uma com a sua função: protocolo (`v`, ADR 0011), schema do banco (`PRAGMA user_version`, ADR 0018), formato de exportação (`dados.json`, ADR 0019) e domínio de assinatura (`bairdwire-auth-v1`, ADR 0021).

**CI por PR:**
- node: `zig fmt --check`, `zig build test`, build `ReleaseSafe` x86_64 e aarch64;
- client: `pnpm install --frozen-lockfile`, `biome ci`, `svelte-check`, `vitest`, `vite build`;
- protocol: nó e camada 4.

Noturno: camadas 2, 3 e 6 estendidas. Semanal ou manual: camada 7.

A lista vale conforme cada camada entra: revisado pelo [ADR 0041](0041-ativacao-das-camadas-de-teste.md).

**Dependências:** Renovate com espera mínima de 7 dias. Dependências Zig atualizadas à mão (ADR 0028).

~~**Guardrails do assistente:** pedir permissão antes de cada commit, com um resumo. Nunca fazer push. Nunca abrir PR.~~ Revisado pelo [ADR 0039](0039-guardrails-do-assistente.md).

## Consequências

- O nó e o cliente são lançados juntos, o que evita a matriz de compatibilidade entre eles. A compatibilidade com clientes antigos abertos em abas é tratada pela versão do protocolo (P7).
- Cada número de versão muda por um motivo próprio, e um não obriga a mexer no outro.
- Fica mais difícil: lançar um conserto só do cliente sem subir a versão do nó, já que tudo sai junto.
