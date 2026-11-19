# Rodar um nó

A instalação padrão é o Docker Compose com dois containers, o nó e o Caddy (ADR 0010). O Caddy termina o TLS, gera o certificado e serve o cliente web. O nó cuida do WebSocket e da mídia.

## O que você precisa

- Uma máquina com **IP público na própria interface**, como uma VPS comum. Atrás de NAT doméstico não funciona no v0.1 (ADR 0038).
- Um **domínio** (ou subdomínio) com um registro `A` (e `AAAA`, se tiver IPv6) apontando para essa máquina.
- Docker com o plugin Compose.
- No firewall, liberar:

| Porta | Para quê |
|---|---|
| 80/tcp | Emissão do certificado e redirecionamento para HTTPS |
| 443/tcp | Cliente web e WebSocket |
| 443/udp | HTTP/3 (opcional) |
| 50000/udp | Mídia (voz e tela). É a `BAIRDWIRE_RTC_UDP_PORT` |

## Subir

```sh
cd deploy
cp .env.example .env
# edite o .env: BAIRDWIRE_DOMAIN com o seu domínio
docker compose up -d --build
```

Recomendado: preencha também `BAIRDWIRE_RTC_ADDRESS` com o IP público da máquina. Sem ele, o nó anuncia na negociação da mídia todos os IPs da máquina, inclusive os das redes internas do Docker (`172.x`), que ninguém de fora alcança. A chamada funciona mesmo assim, mas o navegador perde tempo testando endereços inúteis.

Depois abra `https://<seu domínio>/`. A página de diagnóstico testa o WebSocket e o eco de áudio, e mostra se a mídia passou por UDP.

## Atualizar

```sh
git pull
docker compose up -d --build
```

O nó e o cliente saem do mesmo commit, então estão sempre na mesma versão.

## O que fica guardado

- O Caddy guarda o certificado nos volumes `caddy-data` e `caddy-config`.
- O Caddy não grava log de acesso, e o nó não grava IPs (ADR 0021).

## Segurança dos containers

Os dois containers rodam com usuário não-root, sistema de arquivos só de leitura e sem *capabilities* (S10 do ADR 0021). A única exceção é a `NET_BIND_SERVICE` do Caddy, que ele precisa para abrir as portas 80 e 443. Os dois usam a rede da máquina (`network_mode: host`) para que o nó anuncie o IP público na negociação da mídia (ADR 0038).
