# ADR 0012 — Negociação de mídia e estados da sala

**Status:** aceito
**Data:** 2026-11-18

## Contexto

Mudar a mídia (entrar alguém, começar a compartilhar a tela) exige renegociar o SDP. Se os dois lados fizerem offer ao mesmo tempo acontece o *glare*, que os navegadores resolvem com *perfect negotiation* (rollback). Implementar rollback do lado do nó depende de suporte da `libdatachannel` que não foi verificado. A reconexão em até 30 segundos é critério de pronto (ADR 0006), e só pode haver um compartilhamento de tela por canal (ADR 0003).

## Opções consideradas

- **Uma PeerConnection por cliente:** um handshake só, mas com risco de glare e dependência de rollback no nó.
- **Duas PeerConnections por cliente (publish e subscribe):** cada uma com um único lado que oferece, sem glare. Custa um handshake ICE e DTLS a mais.
- **Tela recebida por todos automaticamente** ou **sob demanda**.

## Decisão

- **Duas PeerConnections por cliente:** *publish* (o cliente sempre oferece) e *subscribe* (o nó sempre oferece).
- **ICE:** trickle do cliente para o nó, pelo WebSocket. Os candidatos do nó vão direto no SDP, porque o nó tem IP e portas fixos.
- **Assinaturas:** o áudio é recebido automaticamente por todos no canal. A **tela é sob demanda**: o espectador escolhe assistir.
- **Estados do participante:** `idle → joining → connecting → connected ⇄ reconnecting → left`, com `failed` depois de 30 segundos em `reconnecting`. O nó guarda a vaga por **30 segundos**. Se cair o ICE, o cliente faz ICE restart. Se cair o WebSocket, retoma com um **token de sessão**.
- **Estado da sala no nó:** participantes, publicações (áudio de cada um e a tela com o perfil) e assinaturas.
- **Trava da tela:** `screen.start` é recusado se já houver alguém compartilhando. Vence o primeiro pedido que chega ao nó. Quem compartilha pode liberar, e um admin pode encerrar.

## Consequências

- Não há glare por construção, e o nó não precisa de rollback de SDP.
- O signaling do nó tem duas máquinas de offer/answer simples em vez de uma complexa.
- A tela sob demanda reduz o upload real do nó em relação às estimativas do ADR 0004, que supunham todos assistindo.
- O token de sessão precisa de validade curta e ficar amarrado à identidade (ADRs 0014 e 0021).
- O detalhe das mensagens vai para `docs/protocolo.md` na implementação.
- Fica mais difícil: são dois handshakes por entrada e dois objetos de conexão para gerenciar no cliente e no nó.
