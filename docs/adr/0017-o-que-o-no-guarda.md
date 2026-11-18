# ADR 0017 — O que o nó guarda, por quanto tempo e onde

**Status:** aceito
**Data:** 2026-11-18

## Contexto

Os princípios de necessidade e de minimização da LGPD (art. 6º) pedem que só se guarde o que for preciso e só pelo tempo preciso. Cada dado guardado precisa ser justificado, protegido, exportável e apagável (D5). O Marco Civil da Internet (art. 15) obriga a guardar logs de acesso por 6 meses apenas provedores de aplicação que sejam pessoa jurídica com fins econômicos.

## Opções consideradas

- Retenção de texto **indefinida** contra **365 dias** por padrão.
- **Soft delete** contra **hard delete**.
- Imagens **deduplicadas por hash** contra **um arquivo por id**.
- Guardar **histórico de chamadas e IPs** contra **não guardar**.

## Decisão

| Dado | Retenção padrão |
|---|---|
| Conta (id, usuário, nome de exibição, cargo, quem convidou, data de entrada) | Enquanto for membro |
| Dispositivos (chave pública, rótulo resumido, criado em, último uso). Sem o User-Agent completo | Até ser revogado |
| Sessões (hash do token, validade) | Até expirar |
| Mensagens | **Indefinida**, configurável pelo dono (30, 90, 365 dias ou indefinida) |
| Imagens: até **10 MB**, **cota de 5 GB** por comunidade | **90 dias**, configurável |
| Convites e links de vinculação ou recuperação (só o hash) | Até expirar, mais 30 dias |
| Auditoria de ações administrativas | **180 dias** |
| Mídia de voz e tela | **Nunca guardada** |
| Histórico de chamadas | **Não guardado**: a presença fica só em memória |
| Endereços IP | **Não guardados por padrão**: rate limiting só em memória, log de acesso do Caddy desligado ou anonimizado no `Caddyfile` padrão. Registro de logs opcional para hosts que precisem (ADR 0023) |

- **Hard delete:** apagar uma mensagem remove a linha. Editar sobrescreve, sem histórico. SQLite com `PRAGMA secure_delete = ON`.
- **Armazenamento:** um único diretório de dados com `bairdwire.db` (SQLite em modo WAL) e `media/` (um arquivo por imagem, nomeado por id aleatório, sem deduplicação).
- **`bairdwire backup`**, usando a API de backup online do SQLite.
- Sem criptografia em disco no v0.1. A recomendação é criptografia de disco na VPS.

## Consequências

- O host tem pouco dado pessoal para proteger, e o mapeamento LGPD fica mais simples.
- Os backups mantêm dados já apagados até serem rotacionados. A documentação recomenda uma rotação compatível com a retenção configurada.
- O nó precisa de um job periódico de expiração: mensagens, imagens, tokens, auditoria.
- A cota de 5 GB e o limite de 10 MB precisam ser aplicados no upload, não depois.
- Sem logs de IP, investigar abuso depende só da auditoria e do conteúdo.
- Fica mais difícil: recuperar conteúdo apagado por engano, que é impossível, e responder a requisições legais que peçam logs de acesso.
