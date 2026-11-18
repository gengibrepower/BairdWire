# ADR 0018 — Modelo de dados inicial

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O inventário de dados está no ADR 0017. O modelo precisa de paginação de histórico, de autoria anonimizável (para saída ou exclusão de membros), de identificadores que não colidam numa federação futura (ADR 0007) e de migrações que não exijam ferramenta externa (critério dos 30 minutos, ADR 0006).

## Opções consideradas

- **IDs:** inteiro autoincremento (expõe contagens e colide na federação), UUIDv4 (não ordenável), UUIDv7 (único e ordenado por tempo).
- **Tempo:** texto ISO 8601 contra inteiro em milissegundos UTC.
- **Migrações:** ferramenta externa contra SQL embutido no binário. Com ou sem *down migrations*.

## Decisão

**Entidades:**
- `community`: uma linha (retenção, cota, `members_can_invite`).
- `member`: `username` único, `display_name`, `role`, `invited_by`, `joined_at`.
- `device`: chave pública, rótulo, `created_at`, `last_seen_at`.
- `session`: hash do token, dispositivo, validade.
- `channel`: `kind` (`text` ou `voice`), `name`, `position`.
- `message`: `channel_id`, `author_id` **anulável**, `body`, `created_at`, `edited_at`.
- `attachment`: `message_id`, `mime`, `bytes`, dimensões, `expires_at`, arquivo em `media/<id>`.
- `token`: hash, `kind` (`setup`, `invite`, `device_link`, `recovery`), `created_by`, `target_member`, `max_uses`, `uses`, `expires_at`.
- `audit_event`: ator, ação, alvo, momento, detalhes.

**Identificadores:** UUIDv7 em `BLOB(16)` para toda entidade exposta pela API. A paginação usa o id (`WHERE id < ? ORDER BY id DESC`).

**Tempo:** inteiro em milissegundos Unix, UTC.

**Migrações:** arquivos SQL embutidos no binário (`@embedFile`), aplicados na inicialização com o controle de `PRAGMA user_version`. Só para frente. **Backup automático antes de migrar.**

O estado das chamadas nunca é persistido.

## Consequências

- Os IDs não revelam contagens e servem para a federação sem migração.
- É preciso um gerador de UUIDv7 no nó, simples de implementar.
- Voltar a uma versão anterior do nó significa restaurar o backup. A documentação precisa dizer isso.
- O `author_id` anulável permite anonimizar a autoria, cuja política sai na próxima decisão.
- Fica mais difícil: depurar o banco à mão, porque IDs em BLOB não são legíveis no `sqlite3` sem `hex()`.
