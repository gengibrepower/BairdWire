# ADR 0007 — Modelo de rede: um nó por comunidade

**Status:** aceito
**Data:** 2026-11-18

## Contexto

Não há servidor central (D2). Os requisitos do v0.1 são: 10 participantes com tela (ADR 0004), histórico persistido disponível com todo mundo offline (ADR 0003) e um host que é dev (ADR 0006). A proposta anterior incluía chamadas 1:1 em P2P direto.

## Opções consideradas

- **A. Um nó por comunidade.** Um binário único com signaling, SFU, armazenamento e convites, rodando numa VPS, num Pi ou num PC. É simples de operar e depurar, e o controlador dos dados é claro.
- **B. P2P puro.** O mesh não comporta 10 pessoas com tela. O histórico depende de alguém estar online. O NAT vira problema de todos os pares, e ainda é preciso um ponto de encontro para o signaling.
- **C. Federação desde o início.** A replicação de estado e a resolução de conflitos são complexas demais para o v0.1.
- **Sub-opção: chamadas 1:1 em P2P direto.** As DMs estão fora do v0.1. O P2P expõe o IP dos participantes uns aos outros. Dois caminhos de mídia dobram código e testes, e exigem migrar a chamada para o SFU quando entra a terceira pessoa.

## Decisão

**Opção A.** Um nó por comunidade, num binário único. **No v0.1, toda a mídia passa pelo nó**, sem P2P direto entre clientes.

Evolução prevista, não comprometida: identidade por chaves → federação entre nós → modo P2P sem nó.

## Consequências

- Cada cliente só vê o IP do nó, nunca o dos outros participantes.
- Um único caminho de mídia (SFU) para testar e depurar.
- O nó é o ponto único de falha da comunidade. A disponibilidade depende do host.
- O nó precisa compilar para x86_64 e aarch64 (VPS e Raspberry Pi). Com o cross-compile do Zig, isso é barato.
- O P2P direto volta à discussão junto com as DMs ou com o modo sem nó, depois do v0.1.
- Fica mais difícil: comunidades sem ninguém disposto a hospedar ou pagar uma VPS não conseguem usar o BairdWire.
