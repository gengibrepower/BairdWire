# ADR 0009 — NAT, CGNAT e redes restritivas

**Status:** aceito
**Data:** 2026-11-18

## Contexto

Toda a mídia passa pelo nó (ADR 0007). Os clientes sempre iniciam a conexão de dentro para fora, então o NAT dos clientes raramente é um problema. O que importa é: (1) o nó ser alcançável e (2) clientes em redes que bloqueiam UDP, como as de universidade e de empresa, comuns no público-alvo (ADR 0002).

No Brasil, CGNAT é comum em conexões domésticas e móveis, e com ele não dá para redirecionar porta. IPv6 resolveria, mas só se todos os clientes tiverem IPv6. Um relay público seria um servidor central, o que viola a D2.

## Opções consideradas

- **A. Nó com endereço público, porta UDP única multiplexada e fallback ICE-TCP, sem TURN.**
- **B. A mais um TURN embutido (TURN/TLS na 443).** Atravessa firewalls com inspeção, mas é um protocolo a mais para implementar.
- **C. Só UDP.** Mais simples, e provavelmente falha em rede de universidade.

## Decisão

**Opção A.**
- O nó precisa ser alcançável por endereço público, IPv4 ou IPv4 mais IPv6. **VPS é o cenário recomendado.** Nó em casa com IPv4 público e redirecionamento de porta funciona, mas não é o foco. Nó atrás de CGNAT **não é suportado no v0.1**.
- A mídia usa **uma única porta UDP** multiplexada.
- Há **fallback ICE-TCP** para clientes sem UDP.
- O TURN fica fora do v0.1. Ele é reavaliado se uma rede real bloquear o ICE-TCP.

## Consequências

- O critério de pronto ganha o item "funciona a partir da rede da faculdade" (ADR 0006).
- É preciso verificar se a `libdatachannel` com `libjuice` suporta ICE-TCP do lado do servidor, ou se é preciso usar `libnice` ou outra solução (P5, bloco 4.8).
- O firewall do host fica simples: uma porta UDP e as portas TCP do nó.
- A documentação do host explica o CGNAT e como saber se a conexão está atrás de um.
- Fica mais difícil: hospedar em casa com operadoras que usam CGNAT. Por TCP, a qualidade da mídia degrada mais quando há perda de pacotes (*head-of-line blocking*).
