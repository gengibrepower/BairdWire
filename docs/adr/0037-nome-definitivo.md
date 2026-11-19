# ADR 0037 — Nome definitivo: BairdWire

**Status:** aceito
**Data:** 2026-11-19
**Resolve:** P1. **Completa:** ADR 0001

## Contexto

O ADR 0001 adotou "BairdWire" como nome provisório e deixou o nome público para antes do primeiro vídeo (P1, V1 do ADR 0033), com a exigência de checar colisões no GitHub, no npm, em domínios e em marca.

Checagem feita em 2026-11-19:

- **Baird:** o npm está ocupado, assim como `github.com/baird` e os domínios `.com`, `.dev`, `.app`, `.org` e `.com.br`. Existe a marca BAIRD da Robert W. Baird & Co. no USPTO desde 1986 (classe 36, serviços financeiros) e uma marca BAIRD da Baird Valve and Regulator que cobre a classe 9 (software). Um sobrenome puro também tende a ser recusado pelo USPTO (Seção 2(e)(4)).
- **Baran:** o usuário do GitHub e todos os domínios estão ocupados, e há cerca de 17 mil repositórios com o nome.
- **Meucci:** o npm, o usuário do GitHub, o `.com` e o `.org` estão ocupados.
- **Palavras em português** (Fogueira, Alpendre, Coreto, Mutirão, Sarau): o npm está livre e há domínios livres, mas são mais difíceis de pronunciar e de buscar para quem não fala português.
- **BairdWire:** livres o npm, o usuário do GitHub e os domínios `.com`, `.app`, `.dev`, `.chat` e `.org`. Há um único repositório com o nome, que é este, e nenhum registro de marca encontrado.

## Opções consideradas

Baird, Baran, Meucci, as palavras em português acima, e manter BairdWire.

## Decisão

- **O nome público é BairdWire.** O identificador técnico continua `bairdwire`.
- O registro da marca (ADR 0026) parte de uma busca direta no INPI e no USPTO, por grafia exata e por variantes. A marca BAIRD na classe 9 é o ponto a avaliar com a revisão jurídica (P14).

## Consequências

- O V1 do ADR 0033 está cumprido.
- A regra do ADR 0001 de não espalhar o nome em formatos e identificadores persistidos perde a urgência, mas continua sendo boa prática.
- Os domínios livres podem ser registrados por quem vai manter o projeto. Até lá, qualquer pessoa pode registrá-los.
- Fica mais difícil: trocar de nome depois dos primeiros vídeos.
