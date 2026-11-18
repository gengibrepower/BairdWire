# ADR 0024 — ECA Digital, denúncia e moderação

**Status:** aceito
**Data:** 2026-11-18

> Mapeamento técnico, não parecer jurídico. A incerteza é alta, porque a lei é recente.

## Contexto

A Lei nº 15.211/2025 (ECA Digital) se aplica a produtos e serviços de tecnologia direcionados a crianças e adolescentes ou de acesso provável por eles. Ela exige verificação de idade proporcional ao risco, privacidade por padrão, supervisão parental, proibição de perfilamento para publicidade, mecanismos de denúncia e remoção rápida de conteúdo violador.

Aplicabilidade em camadas: o projeto que distribui código provavelmente não está sujeito. O grupo do autor (universitários, só por convite) provavelmente também não. Um host com comunidade pública de acesso provável por menores provavelmente está.

O modelo "só por convite, sem DMs, sem descoberta pública" já elimina o principal vetor de risco: o contato de adultos desconhecidos.

## Opções consideradas

- Ignorar o ECA Digital no v0.1, implementar um mínimo honesto, ou implementar verificação de idade real e supervisão parental.
- Idade mínima fixa ou configurável.

## Decisão

- **E1.** Idade mínima configurável pelo host, com **padrão de 18 anos**. Abaixo de 18, a interface avisa que podem existir obrigações adicionais do ECA Digital.
- **E2.** Autodeclaração de idade na entrada, junto com o aceite dos termos (K3, ADR 0023). A documentação diz explicitamente que autodeclaração não é verificação.
- **E3.** Botão "Denunciar" em mensagens e imagens. Motivos: assédio, spam, conteúdo ilegal, conteúdo envolvendo menores.
- **E4.** Fila de moderação para dono e admins, com as ações remover conteúdo, remover membro ou descartar. Tudo na auditoria.
- **E5.** Denúncia de "conteúdo envolvendo menores" oculta a imagem ou mensagem de todos imediatamente, até a revisão.
- **E6.** Procedimento documentado para material de abuso sexual infantil: remover o acesso, não redistribuir, denunciar à SaferNet Brasil e à Polícia Federal. A questão de preservar ou eliminar o material exige confirmação jurídica (P14) antes de ser documentada como orientação.
- **E7.** O contato do host (K1) também recebe denúncias contra admins.
- **O v0.1 não é adequado para comunidades direcionadas a menores**, e a documentação diz isso.

Fora do v0.1: verificação de idade real, supervisão parental, modo para comunidades abertas a menores.

## Consequências

- O modelo de dados ganha uma entidade de denúncia (`report`) e um estado "oculto" para mensagens e anexos.
- Fecha a P9.
- Antes da divulgação ampla, o ECA Digital precisa de revisão jurídica junto com a P14.
- Fica mais difícil: atender comunidades de jogos com público adolescente, que é um público natural de apps estilo Discord.
