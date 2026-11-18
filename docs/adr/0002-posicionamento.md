# ADR 0002 — Posicionamento do produto

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O autor usa o Discord para três coisas: pair programming, reuniões de projetos da faculdade (com Google Docs e Slides compartilhados na tela) e jogos, normalmente logo depois das reuniões. Os primeiros usuários são universitários, a maioria dev. O grupo inicial é misto: a maior parte usa Linux e o resto usa Windows. Todos usam detecção de voz, não push-to-talk.

Surgiu a dúvida se o produto deveria ser focado em devs, "estilo Slack descentralizado".

## Opções consideradas

1. **Genérico, estilo Discord**, sem foco declarado. O público é amplo, mas não há critério para priorizar features.
2. **Grupos pequenos de dev e estudo, tempo real primeiro.** Voz, tela e chat, com o chat amigável para devs.
3. **Estilo Slack para devs.** Texto e trabalho assíncrono primeiro: threads, busca, integrações e retenção longa. Puxa o escopo para longe dos usos reais (todos síncronos) e aumenta o peso de LGPD com histórico longo e integrações.

## Decisão

**Opção 2.** "Voz, tela e chat para grupos pequenos que trabalham e jogam juntos, com foco em quem programa." O público inicial são universitários. Isso não quer dizer que instituições hospedem o nó: o nó é do próprio grupo.

## Consequências

- O compartilhamento de tela tem **dois perfis**: *detalhe* (texto nítido, resolução nativa, fps baixo, para código e documentos) e *movimento* (30 a 60 fps, para gameplay).
- O chat ganha blocos de código com syntax highlight e Markdown como itens do núcleo.
- Ficam fora do foco: threads, busca avançada, integrações e webhooks, workspaces grandes e SSO institucional.
- Linux e Windows são plataformas de primeira classe para o cliente.
- O nó não deve competir com o jogo pelo upload. Isso pesa na decisão de onde o nó roda (bloco 4.2).
- Fica mais difícil: atrair usuários fora do nicho dev e estudo e usar o produto como ferramenta de trabalho assíncrono.
