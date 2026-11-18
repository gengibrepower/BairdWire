# ADR 0015 — Convite e entrada na comunidade

**Status:** aceito
**Data:** 2026-11-18

## Contexto

A entrada numa comunidade só acontece por convite (não há diretório central, D2). A identidade é uma conta no nó com chave por dispositivo (ADR 0014). A proposta anterior colocava no convite o endereço e a chave pública do nó.

No v0.1 o cliente web é servido pelo próprio nó. Quem controla o domínio ou o TLS do nó controla o JavaScript que faria a verificação dessa chave, então pinning da chave do nó dentro do cliente web não adiciona proteção.

## Opções consideradas

- Convite com **endereço e chave do nó** contra **só o endereço e o token**.
- Cliente web **servido pelo nó** contra **hospedado centralmente**. A segunda opção viola a D2.
- Token no **caminho ou query** da URL contra **no fragmento (`#`)**.
- Criação do dono: **link de setup de uso único** contra **credencial em arquivo de configuração**.

## Decisão

- **Cada nó serve o próprio cliente web.**
- **Setup do dono:** na primeira execução o nó imprime um link de setup de uso único (ou o host roda `bairdwire setup`). Quem abre o link vira o dono.
- **Link de convite:** `https://<nó>/join#t=<token>`. O token vai no **fragmento**, que não chega aos logs do servidor nem ao `Referer`, e é enviado no corpo de um POST.
- **Token:** 128 bits aleatórios. O nó guarda só o hash SHA-256.
- **Propriedades:** validade padrão de 7 dias, 1 uso por padrão (configurável para N), revogável. Criado pelo dono e pelos admins, e pelos membros se o dono liberar. Quem criou e quem usou ficam em auditoria.
- **Entrada:** ver a comunidade e quem convidou → escolher nome de usuário (único no nó) e nome de exibição → gerar a chave Ed25519 → `POST /api/join` (token, chave pública, assinatura de desafio) → conta, dispositivo e sessão.
- **Mesmo mecanismo, outros tipos de token:** vinculação de dispositivo (10 minutos, uso único, amarrado à conta) e recuperação (gerado pelo admin, 24 horas, uso único).
- **Sem a chave do nó no convite do v0.1.**

## Consequências

- Os tokens não aparecem em logs do Caddy nem em histórico de proxies. Um vazamento do banco não expõe convites ativos.
- A versão do cliente sempre corresponde à do nó.
- A confiança no nó, no v0.1, é a confiança no TLS e no domínio dele. A chave do nó (pinning e assinatura) volta quando houver cliente fora do nó (app desktop, v0.2) ou federação (P8).
- A tela de entrada é o lugar natural para a declaração de idade e o aceite dos termos do host, a definir no bloco 4.6 (P9).
- Fica mais difícil: o link de setup é um ponto sensível. Se vazar antes do uso, outra pessoa vira dona. Ele precisa de validade curta e só pode aparecer no terminal do host.
