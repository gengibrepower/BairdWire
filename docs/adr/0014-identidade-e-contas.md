# ADR 0014 — Identidade e contas: conta no nó com chave por dispositivo

**Status:** aceito
**Data:** 2026-11-18

## Contexto

O v0.1 precisa de login, de acesso por mais de um dispositivo e de recuperação. A evolução prevista (ADR 0007) e o E2EE com MLS precisam de chaves por dispositivo. O Ed25519 está disponível no WebCrypto de todos os navegadores atuais, inclusive como chave não-extraível, e no `std.crypto.sign.Ed25519` do Zig.

Não há servidor de e-mail, e o nó não deve depender de um.

## Opções consideradas

- **A. Conta com senha (Argon2id).** Familiar, mas tem hash atacável se o banco vazar, é vulnerável a phishing e exige migrar tudo quando vierem a federação e o MLS.
- **B. Só par de chaves.** É a identidade mais "do usuário", mas sem recuperação: perder o navegador significa perder a identidade, e o segundo dispositivo exige exportar a chave.
- **C. Conta local no nó com uma chave Ed25519 por dispositivo.** Login por desafio e resposta, vinculação de dispositivo e recuperação pelo admin.
- **WebAuthn e passkeys.** É o padrão do mercado com sincronização pelo SO, mas fica amarrado ao domínio do nó e é mais trabalhoso no servidor (CBOR, COSE, attestation).

## Decisão

**Opção C.**
- A conta existe só no nó da comunidade.
- Cada dispositivo gera um par **Ed25519 não-extraível** no WebCrypto, guardado no IndexedDB. O nó guarda só as chaves públicas associadas à conta.
- **Login por desafio e resposta:** o nó envia um nonce de uso único e o dispositivo assina.
- **Novo dispositivo:** um dispositivo já logado gera um link de vinculação de uso único e curta validade.
- **Recuperação:** um admin gera um link de recuperação para a conta, com a opção de revogar os dispositivos antigos.
- Não há senhas no v0.1.

## Consequências

- Se o banco vazar, não há credenciais para quebrar offline. Phishing de senha não existe.
- Cada dispositivo já tem a chave de que o MLS vai precisar.
- Caminho futuro: a conta pode passar a ser assinada por uma chave-raiz do usuário (identidade portátil, opção B) sem migrar a base.
- Limpar os dados do navegador desloga aquele dispositivo. Se era o único, o usuário depende do admin. A interface precisa deixar isso claro e incentivar vincular um segundo dispositivo.
- Admin comprometido ou malicioso consegue gerar recuperação para qualquer conta e se passar por ela. Mitigado pela recuperação hierárquica, pela auditoria (ADR 0016) e pelo aviso ao titular (S6, ADR 0021).
- WebAuthn fica como método de login adicional possível depois.
- Fica mais difícil: o fluxo de vinculação de dispositivos é UX nova para os usuários, e não há "esqueci a senha" self-service.
