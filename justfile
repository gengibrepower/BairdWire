set shell := ["bash", "-euo", "pipefail", "-c"]

cliente := "pnpm --filter @bairdwire/client"

default:
    @just --list

# formata o nó e o cliente
fmt:
    cd node && zig fmt build.zig build src
    {{cliente}} exec biome format --write .

# testes do nó e do cliente
test:
    cd node && zig build test --summary all
    {{cliente}} test

# o mesmo que a CI roda (ci.yml), na mesma ordem
check: check-hooks check-no check-cliente check-deploy

# testes do hook que lê o docs/dominio.json (ADR 0042)
check-hooks:
    node --test .claude/hooks/dominio.test.mjs

check-no:
    cd node && zig fmt --check build.zig build src
    cd node && for alvo in native x86_64-linux-musl; do \
        zig build test -Dtarget=$alvo --summary all; \
        zig build test -Dtarget=$alvo -Drelease --summary all; \
    done
    cd node && for alvo in x86_64-linux-musl aarch64-linux-musl; do zig build -Dtarget=$alvo -Drelease; done

check-cliente:
    pnpm install --frozen-lockfile
    {{cliente}} run lint
    {{cliente}} run check
    {{cliente}} test
    {{cliente}} run build

# o BAIRDWIRE_DOMAIN do ambiente vence o deploy/.env, que fica intocado
check-deploy:
    #!/usr/bin/env bash
    set -euo pipefail
    cd deploy
    export BAIRDWIRE_DOMAIN=localhost
    trap 'docker compose down -v' EXIT
    docker compose build
    docker compose up -d
    ./smoke.sh localhost || { docker compose logs --no-color; exit 1; }

# nó e cliente em modo de desenvolvimento (Ctrl+C encerra os dois)
dev:
    #!/usr/bin/env bash
    set -euo pipefail
    trap 'kill 0' EXIT
    (cd node && BAIRDWIRE_ORIGIN=http://localhost:5173 zig build run) &
    {{cliente}} run dev
