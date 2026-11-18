# ADR 0016 — Cargos e permissões

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O v0.1 precisa de cargos mínimos (dono, admin, membro). O ADR 0014 deixou um risco em aberto: um admin malicioso pode gerar recuperação de conta e se passar por outro usuário.

O **host** (quem roda o nó e tem acesso ao banco) é um papel diferente do **dono** (cargo dentro da comunidade). Cargos protegem contra membros, não contra o host. Como a entrada é só por convite e cada entrada gera uma conta e uma chave novas, não há identidade estável para banir.

## Opções consideradas

- Cargos fixos contra cargos customizados com permissões por canal.
- Recuperação de conta por qualquer admin contra uma recuperação hierárquica.
- Ban por identidade contra apenas remoção, com o controle feito em quem convida.

## Decisão

Três cargos fixos:

| Ação | Dono | Admin | Membro |
|---|:-:|:-:|:-:|
| Mensagens, imagens, voz, tela | ✅ | ✅ | ✅ |
| Editar e apagar as próprias mensagens | ✅ | ✅ | ✅ |
| Criar convites | ✅ | ✅ | se o dono liberar |
| Apagar mensagens e imagens de outros | ✅ | ✅ | ❌ |
| Encerrar a tela de outro e tirar alguém da voz | ✅ | ✅ | ❌ |
| Criar, renomear e apagar canais | ✅ | ✅ | ❌ |
| Remover membros | ✅ | só membros | ❌ |
| Gerar recuperação de conta | qualquer um | **só membros** | ❌ |
| Promover e rebaixar admins | ✅ | ❌ | ❌ |
| Configurar a comunidade | ✅ | ❌ | ❌ |
| Transferir o cargo de dono | ✅ | ❌ | ❌ |

- A recuperação da conta do dono só é feita pelo host, via CLI (`bairdwire recover-owner`).
- **Remover** um membro revoga todos os dispositivos e encerra as sessões. Não existe "ban" no v0.1, e a interface diz isso com clareza.
- Toda ação administrativa (remoção, recuperação, exclusão de conteúdo alheio, mudança de cargo) vai para a auditoria.

## Consequências

- Um admin não consegue escalar privilégio tomando a conta de outro admin ou do dono.
- Um removido pode voltar com um novo convite, como uma conta nova. O controle real está em quem pode convidar.
- Ficam fora do v0.1: cargos customizados, permissões por canal, canais privados, cargo de moderador e ban por identidade.
- O destino das mensagens de membros removidos é definido no bloco 4.4.
- Fica mais difícil: comunidades que precisam de canais privados ou de moderação em camadas não são atendidas.
