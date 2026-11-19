# ADR 0038 — Rede do container do nó no v0.1

**Status:** aceito, **só para o v0.1**
**Data:** 2026-11-19

## Contexto

O ICE do nó anuncia como candidatos os IPs das interfaces que ele enxerga (ADR 0012: os candidatos do nó vão no SDP). Numa rede *bridge* do Docker, o container só enxerga o próprio IP interno, que o navegador não alcança. O eco do M0 funcionou com o nó rodando direto na máquina.

O ADR 0010 define a instalação padrão como Docker Compose com o Caddy e o nó, e o S10 do ADR 0021 pede container sem root, com sistema de arquivos só de leitura e sem *capabilities*.

## Opções consideradas

- **A. `network_mode: host`** no nó e no Caddy. O nó anuncia o IP da máquina. É a configuração recomendada pela documentação de SFUs como LiveKit e Jitsi.
- **B. Rede bridge com IP público configurado.** O núcleo troca o IP dos candidatos no SDP por um IP informado pelo host, e a porta UDP é publicada 1:1. Mantém o isolamento de rede e funciona atrás de NAT com redirecionamento de porta, mas exige mexer no SDP e configurar o IP.
- **C. Rede bridge com STUN.** O nó descobre o IP público num servidor STUN de terceiros, que passa a saber o IP do nó e os horários de uso (contra o ADR 0017).

## Decisão

**Opção A, no v0.1.** O nó e o Caddy rodam com `network_mode: host` no `docker-compose.yml` padrão. O S10 continua valendo: usuário não-root, sistema de arquivos só de leitura e `cap_drop: [ALL]`.

**Revisar antes de sair do v0.1**, ou antes, se aparecer um host que precise rodar atrás de NAT. A opção B é a candidata para esse caso.

## Consequências

- O host precisa de uma máquina com IP público na interface, como uma VPS comum. Uma máquina atrás de NAT doméstico não funciona com o Compose padrão.
- O nó e o Caddy escutam direto nas portas da máquina: 80 e 443 (TCP) para o Caddy, e a porta UDP da mídia (`BAIRDWIRE_RTC_UDP_PORT`) para o nó. O WebSocket do nó escuta só em `127.0.0.1`, atrás do Caddy.
- O firewall da máquina precisa liberar 80/tcp, 443/tcp e a porta UDP da mídia.
- Fica mais difícil: rodar dois nós na mesma máquina, porque as portas são da máquina e não do container.
