# ADR 0030 — Stack do cliente web

**Status:** aceito
**Data:** 2026-11-18

## Contexto

Restrições já decididas: CSP rígido sem `unsafe-inline` nem `eval` (ADRs 0020 e 0021), poucas dependências (T10), SPA estática servida pelo nó (ADR 0015) e reaproveitada no desktop do v0.2 (ADR 0005). O autor quer uma interface **bonita, rápida e leve**. O front-end não está entre os objetivos de aprendizado, então o critério principal é produtividade. A interface tem muitas atualizações pequenas e frequentes (indicador de fala, presença, mensagens).

## Opções consideradas

- **Framework:** Svelte 5, SolidJS, React, TS puro com Web Components.
- **Estilo:** CSS-in-JS em tempo de execução (incompatível com o CSP) ou CSS gerado no build.
- **Highlight:** Shiki (gera `style` inline, incompatível com o CSP) ou highlight.js (classes).
- **Lint:** ESLint + Prettier, ou Biome.

## Decisão

- **Svelte 5** (runes, reatividade granular, runtime mínimo).
- **Tailwind CSS v4** (CSS gerado no build) + **shadcn-svelte / Bits UI**, com os componentes copiados para o repositório.
- Tema escuro por padrão, claro opcional. Layout familiar: canais, conteúdo, membros.
- **Vite** em modo SPA. **TypeScript strict.**
- **pnpm**, sem scripts de instalação por padrão e com `minimumReleaseAge` configurado.
- **Biome** para lint e formatação.
- **markdown-it** com `html: false`. **highlight.js** com classes e linguagens carregadas sob demanda.
- **APIs nativas** para WebRTC, mídia e WebCrypto, sem wrappers. Reencode de imagem com `createImageBitmap` + `OffscreenCanvas`.
- **Vitest** para testes unitários. **Playwright** (Chromium e Firefox, com mídia falsa) para testes end-to-end e de carga.
- **Práticas de performance:** lista de mensagens virtualizada; fonte variável auto-hospedada (sem Google Fonts); miniaturas com dimensões reservadas; indicador de fala via `getSynchronizationSources()`; atualização otimista.
- **CSP rígido ligado desde o primeiro dia, inclusive em desenvolvimento.**

## Consequências

- Componentes que manipulam estilo via `setAttribute('style')` ou injetam `<style>` são detectados cedo pelo CSP em desenvolvimento.
- Os componentes copiados do shadcn-svelte são código do projeto: o projeto tem controle total, e também é responsável pela manutenção.
- O build estático é o mesmo artefato servido pelo nó e embutido no desktop.
- Fica mais difícil: usar libs de UI que dependem de CSS-in-JS ou de estilos inline, e usar o Shiki.

## Adendo (2026-11-19): o Caddy serve o cliente até a fase 2

O nó só fala WebSocket até a fase 2, quando ganha HTTP com o `http.zig` (adendo do ADR 0034). Até lá:

- **O Caddy serve o build estático do cliente** (`file_server`, com fallback para o `index.html`), numa imagem própria com o `dist/` dentro.
- As imagens do nó e do Caddy saem do mesmo `Dockerfile`, a partir do mesmo commit, para que o cliente e o nó estejam sempre na mesma versão.
- **Na fase 2, os arquivos passam para o nó**, como diz a decisão acima, e o Caddy volta a só terminar o TLS (ADR 0010).
