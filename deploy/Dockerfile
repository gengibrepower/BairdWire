# syntax=docker/dockerfile:1

ARG ALPINE=docker.io/library/alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf
ARG NODE=docker.io/library/node:24.19.0-alpine@sha256:d32cdf619f63fe0471182d08996dd516c6275bb5fd31ae06e55a570bd9e1ad43
ARG CADDY=docker.io/library/caddy:2.11.8-alpine@sha256:f6228111e5fafa1a5238258d0858e103f10599b8d1659a146e7726681a002bb9

FROM --platform=$BUILDPLATFORM ${ALPINE} AS zig
ARG BUILDARCH
RUN apk add --no-cache curl xz
RUN set -eu; \
    case "$BUILDARCH" in \
      amd64) arch=x86_64; sum=3581863e3cbcfd0fce0efc682ce7e9e93da96668a977791d356a26d2a7e9b17a ;; \
      arm64) arch=aarch64; sum=a1546d5646eb184437918d6635ca6b762a0e889eac09cef720ee7a1ed3fe7795 ;; \
      *) echo "arquitetura de build sem suporte: $BUILDARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 5 --retry-all-errors -o /tmp/zig.tar.xz "https://ziglang.org/download/0.17.1/zig-$arch-linux-0.17.1.tar.xz"; \
    echo "$sum  /tmp/zig.tar.xz" | sha256sum -c -; \
    mkdir /opt/zig; \
    tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1; \
    rm /tmp/zig.tar.xz
ENV PATH=/opt/zig:$PATH

FROM zig AS node-build
ARG TARGETARCH
WORKDIR /src
COPY .zig-version ./
# as dependências ficam numa camada própria, que só muda com o build
COPY node/build.zig node/build.zig.zon node/
COPY node/build/ node/build/
RUN cd node && for tentativa in 1 2 3 4 5; do zig build --fetch && exit 0; sleep $((tentativa * 5)); done; exit 1
COPY node/src/ node/src/
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) target=x86_64-linux-musl ;; \
      arm64) target=aarch64-linux-musl ;; \
      *) echo "arquitetura sem suporte: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    cd node && zig build -Drelease -Dtarget="$target" --prefix /out

FROM --platform=$BUILDPLATFORM ${NODE} AS client-build
RUN npm install --global pnpm@11.9.0
WORKDIR /src
COPY pnpm-workspace.yaml pnpm-lock.yaml ./
COPY client/package.json client/
RUN pnpm install --frozen-lockfile
COPY client/ client/
RUN cd client && pnpm run build

FROM scratch AS node
COPY --from=node-build /out/bin/bairdwire-node /bairdwire-node
USER 65532:65532
ENTRYPOINT ["/bairdwire-node"]

FROM ${CADDY} AS caddy
RUN mkdir -p /data /config && chown 65532:65532 /data /config
COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY --from=client-build /src/client/dist /srv
USER 65532:65532
