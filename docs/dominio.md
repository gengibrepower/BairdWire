# Domínio por área

O assistente só escreve o que o autor já saberia escrever ([ADR 0042](adr/0042-dominio-por-area.md)). Cada área do repositório tem um estado, e o estado diz quem escreve.

**A fonte da verdade é o [`dominio.json`](dominio.json).** O hook do assistente e o subagente revisor leem esse arquivo. A tabela abaixo é uma cópia para leitura; se ela divergir do JSON, vale o JSON.

## Estados

| Estado | Quem escreve | O que o assistente faz |
|---|---|---|
| `aprendendo` | o autor | explica, dá dicas, revisa e escreve testes (`*_test.zig`); não escreve a implementação, nem um trecho |
| `em-prova` | o autor, do arquivo vazio, sem referência e sem pedir código | não dá dicas de design; só aponta erros de API depois de o autor terminar |
| `delegada` | o assistente | escreve; o autor revisa linha por linha |
| `divida` | o assistente | escreve; o autor pretende aprender (ver [`dividas.md`](dividas.md)) |
| `fora-do-objetivo` | o assistente | escreve; o autor não pretende aprender, até dizer o contrário |

## Como o caminho é resolvido

- `caminho` é um prefixo de pasta (termina em `/`) ou um arquivo. Vence a entrada mais específica, então um módulo de `node/src/core/` pode ter um estado diferente da pasta.
- Um caminho em `node/src/` sem entrada conta como `aprendendo`.
- Um caminho fora de `node/src/` sem entrada é livre.
- Se o JSON estiver ausente ou inválido, a escrita em `node/src/` fica bloqueada.

## Promoção

`aprendendo` → `em-prova` → `delegada`, quando as notas do autor mostram:

1. pelo menos um módulo da área escrito do arquivo vazio, sem a referência e sem pedir código;
2. o `/revisar` sem achados graves nesse módulo;
3. o tempo por módulo caindo e as dicas pedidas mudando de design para detalhe de API;
4. o autor explicando cada linha sem consultar nada (o episódio da série sobre a área serve como teste).

## Rebaixamento

Se, revisando uma área `delegada`, o autor não souber explicar uma linha, ela pode voltar para `aprendendo`.

## Como mudar um estado

Um ADR curto, que revisa o anterior, mais a mudança na entrada do `dominio.json`, com o número do ADR novo em `adr`. Mudar o `dominio.json` é um commit importante e pede permissão (ADRs 0039 e 0042).

## Estado atual

| Caminho | Estado | ADR |
|---|---|---|
| `node/src/core/` | `aprendendo` | [0042](adr/0042-dominio-por-area.md) |
| `node/src/runtime.zig` | `aprendendo` | [0042](adr/0042-dominio-por-area.md) |
| `node/src/adapters/` | `aprendendo` | [0042](adr/0042-dominio-por-area.md) |
| `node/src/main.zig` | `aprendendo` | [0042](adr/0042-dominio-por-area.md) |
| `node/build.zig`, `node/build.zig.zon`, `node/build/` | `divida` | [0042](adr/0042-dominio-por-area.md) |
| `client/` | `fora-do-objetivo` | [0042](adr/0042-dominio-por-area.md) |
| `deploy/`, `.github/` | `fora-do-objetivo` | [0042](adr/0042-dominio-por-area.md) |
| `.claude/`, `.agents/`, `AGENTS.md` | `fora-do-objetivo` | [0042](adr/0042-dominio-por-area.md) |

Os testes de integração em TypeScript também são `fora-do-objetivo`, mas a pasta ainda não existe. Quando ela for criada, na fase 1, ganha uma entrada no JSON.
