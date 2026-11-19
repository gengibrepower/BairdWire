# ADR 0035 — Handshake `hello` e negociação de versão

**Status:** aceito
**Data:** 2026-11-19

## Contexto

O ADR 0011 definiu o envelope `{v, t, id, re, d}` e um handshake `hello` com negociação de versão, sem fixar o formato. A autenticação já acontece no upgrade do WebSocket, pelo cookie de sessão (S2) e pela checagem de `Origin` (S1, ADR 0021), então o `hello` não carrega credencial. A retomada depois de uma queda usa um token de sessão (ADR 0012).

No v0.1, o cliente web é servido pelo próprio nó, e uma versão incompatível só acontece numa aba aberta antes de o host atualizar o nó. Um reload resolve. No v0.2, o app desktop não recarrega do nó (P7, P8).

O `hello` e a recusa dele são as únicas mensagens que todas as versões do nó precisam entender para conseguir recusar uma conexão com clareza. O formato delas não pode mudar depois.

## Opções consideradas

- **A. Versão única:** o cliente manda a versão que fala, e o nó aceita ou recusa. É o mais simples, mas no v0.2 um cliente desktop antigo não teria como oferecer uma versão anterior sem mudar o próprio `hello`.
- **B. Lista de versões:** o cliente manda as versões que fala, e o nó escolhe a maior em comum e responde qual escolheu.
- **C. O nó fala primeiro:** o nó anuncia as versões ao abrir a conexão, e o cliente escolhe. Acrescenta uma ida e volta e inverte a correlação por `re`.

## Decisão

**Opção B.**

- O cliente envia `session.hello` com `versions` (as versões que fala), `client` (informativo) e `resume` (token de retomada ou `null`).
- O nó responde `session.welcome` com a versão escolhida, a maior em comum, ou `session.error` com `version_incompatible` e as versões que aceita, e fecha a conexão.
- **O formato de `session.hello`, `session.welcome` e `session.error` fica congelado** em todas as versões do protocolo. Campos novos nelas só entram como opcionais.
- No v0.1 o nó aceita só a versão 1. Quantas versões ele aceita ao mesmo tempo continua sendo a P7.

**Padrões:**

- A primeira mensagem precisa ser um `session.hello` e chegar em até **5 segundos**. Caso contrário, o nó fecha a conexão.
- **4 KiB** de tamanho máximo antes do `hello`, e **64 KiB** depois dele.
- Códigos de fechamento da aplicação na faixa **4000–4999** (RFC 6455), sempre precedidos de um `session.error` com o motivo, quando der para enviá-lo.
- O campo `client` é só para diagnóstico: o nó não decide nada com base nele.
- O namespace `session.*` fica para o ciclo de vida da conexão.

A especificação está em `docs/protocolo.md`.

## Consequências

- O cliente desktop do v0.2 consegue oferecer versões antigas sem mudar o `hello`.
- Uma aba desatualizada no v0.1 recebe `version_incompatible` e pode recarregar sozinha.
- Conexões que não completam o handshake não ocupam o nó por mais de 5 segundos.
- O limite de 64 KiB vale para todas as mensagens depois do `hello`. Se o chat ou o signaling precisarem de mais, o limite muda por um novo ADR.
- Fica mais difícil: mudar o formato do handshake. Qualquer mudança incompatível nele exige um mecanismo de transição próprio.
