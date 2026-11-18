# Kickoff — sessão de definição de escopo

Este arquivo inicia uma sessão de **definição de escopo e decisões**. Nesta sessão não se escreve código de produto. O resultado esperado são documentos: o escopo fechado e os registros de decisão.

---

## 1. Contexto

Sou o Felipe, estudante de Engenharia de Software (PUCPR) e dev Node.js. Já fiz projetos de sistemas antes (um simulador de exchange em Rust com motor determinístico e event sourcing, e um gateway de pagamentos em Go). Este é o meu projeto das férias, que deve continuar depois delas.

**O projeto:** um app de comunicação estilo Discord (texto, voz e compartilhamento de tela de boa qualidade), **open source e controlado pelas comunidades que o usam**.

**Motivação:**
- Ter uma ferramenta que eu e as minhas equipes usemos de verdade no dia a dia.
- Aprender redes, WebRTC, criptografia aplicada e Zig a fundo.
- Documentar o desenvolvimento numa **série no YouTube** e divulgar o projeto.

**Filosofia:** "anti empresa maligna". Nenhum ponto central que uma empresa possa controlar ou comprar. Quem usa baixa, roda e modifica como quiser. Eu não quero e não posso pagar servidor para os outros.

---

## 2. Decisões já tomadas (não reabrir sem motivo forte)

| # | Decisão | Motivo |
|---|---------|--------|
| D1 | Backend/nó em **Zig** | Aprendizado. Acompanhar os breaking changes pré-1.0 e migrar entre versões faz parte do objetivo. |
| D2 | **Sem servidor central mantido por mim** | Custo e filosofia. Cada comunidade hospeda a própria infraestrutura. |
| D3 | **Open source** | Controle pelos usuários e transparência. |
| D4 | **Começar pequeno** | O v0.1 é para o meu grupo (poucas pessoas que conheço). O crescimento vem depois. |
| D5 | Tratar como **produto real** | Segurança e conformidade com a LGPD (e com o ECA Digital, se couber) desde o design, não como remendo no final. |

---

## 3. Propostas discutidas mas NÃO decididas

São hipóteses levantadas numa conversa anterior. Cada uma precisa ser validada ou trocada nesta sessão:

- **Modelo de rede:** um "nó" por comunidade (binário único, rodando no PC de um membro, num Raspberry Pi ou numa VPS barata) que faz signaling, SFU, armazenamento e relay. Chamadas 1:1 em P2P direto. Evolução possível depois: identidade por chaves → federação entre nós → modo P2P sem nó fixo.
- **Fases do v0.1:** (1) signaling em Zig + mesh P2P no navegador → (2) chat de texto com SQLite → (3) SFU próprio → (4) compartilhamento de tela pelo SFU + simulcast.
- **WebRTC no nó:** `libdatachannel` pela API C (ICE, DTLS, SRTP), com o SFU escrito em Zig por cima.
- **Libs Zig:** `libxev` ou `std.Io` para o event loop; `http.zig` e `websocket.zig` para o signaling; SQLite via C.
- **Cliente:** web em TypeScript (o navegador faz captura, encode e AEC). Desktop depois (Tauri ou Electron, ou um módulo nativo em Zig para captura via PipeWire e encode por hardware).
- **Segurança:** no v0.1, DTLS-SRTP + TLS até o nó. E2EE depois (SFrame para mídia, MLS para texto). Não existe MLS pronto em Zig.
- **Licença:** AGPL-3.0 em vez de uma licença não comercial, porque uma licença não comercial não é open source pela definição da OSI.
- **Descoberta:** um link de convite com o endereço e a chave pública do nó, sem diretório central.

---

## 4. Perguntas a decidir nesta sessão

Siga mais ou menos esta ordem. Cada bloco termina com uma decisão registrada.

### 4.1 Produto e escopo do v0.1
- Nome do projeto (pode ser provisório).
- O que está **dentro** e o que está **fora** do v0.1. Ser explícito sobre o que fica de fora.
- Quantas pessoas por chamada e por comunidade no v0.1.
- Qualidade-alvo do compartilhamento de tela (resolução, fps, latência aceitável).
- Critério de "pronto" do v0.1: o que precisa funcionar para o meu grupo trocar o Discord por isso numa sessão real.

### 4.2 Arquitetura de rede
- Confirmar ou trocar o modelo "nó por comunidade".
- Topologia de mídia: em que ponto sai do mesh P2P e passa para o SFU.
- Estratégia de NAT/CGNAT no v0.1 (IPv6, redirecionamento de porta, TURN, relay).
- Protocolo de signaling: formato das mensagens, estados da sala, troca de SDP e ICE.

### 4.3 Identidade e contas
- No v0.1, conta no nó ou identidade por par de chaves desde o início?
- Como funciona o convite e a entrada numa comunidade.
- Permissões e cargos mínimos (dono, admin, membro).

### 4.4 Dados e armazenamento
- O que o nó guarda, por quanto tempo, e onde.
- Modelo de dados inicial (comunidade, canal, mensagem, membro).
- Exportação e exclusão de dados (direitos do titular na LGPD).

### 4.5 Segurança
- Ameaças que importam no v0.1 e as que ficam para depois (montar um threat model simples).
- Onde a criptografia acontece em cada fase.
- O que o operador de um nó consegue ou não consegue ver.

### 4.6 Conformidade
- Quem é o controlador dos dados no modelo self-hosted, e o que o software precisa oferecer para o operador cumprir a LGPD.
- Se e como o ECA Digital afeta o projeto (o app é acessível a menores?). Mecanismos de denúncia e moderação.
- Observação: isto é mapeamento técnico, não parecer jurídico.

### 4.7 Licença e governança
- AGPL-3.0, outra licença, ou não comercial (com os prós e contras).
- Política de contribuição (CONTRIBUTING, DCO ou CLA).

### 4.8 Stack e ferramentas
- Versão do Zig fixada e a estratégia de atualização.
- Confirmar `libdatachannel`, `libxev`/`std.Io` e as libs de HTTP/WS.
- Como isolar I/O e rede para que os breaking changes do Zig fiquem contidos.
- Stack do cliente web.
- Estratégia de testes (unitários, integração do protocolo, testes de rede com várias instâncias).

### 4.9 Repositório e workflow
- Estrutura do monorepo (nó, cliente, docs).
- Workflow git: branch → PR → squash merge, CI como gate, histórico linear (o mesmo dos meus outros projetos).
- O CI mínimo: `zig build test`, formatação e lint do cliente.

### 4.10 Série no YouTube
- Mapear as fases e os temas técnicos em episódios.
- O que precisa existir antes do primeiro vídeo.

---

## 5. Como quero que você (Claude) atue

- **Modo tutor.** Explique o porquê de cada opção e os trade-offs. Eu quero entender, não só receber a resposta.
- **Uma decisão por vez.** Apresente as opções com prós e contras, dê a sua recomendação, e **espere a minha decisão** antes de registrar.
- **Não decida por mim** em nada importante. Se algo depender de uma decisão anterior que ainda não tomamos, aponte isso.
- **Discorde quando achar que estou errado.** Seja direto e tecnicamente preciso.
- **Sem código de produto nesta sessão.** Trechos curtos para ilustrar um conceito estão liberados.
- Quando escrever código (agora ou em sessões futuras): **sem comentários**, exceto para explicar um comportamento inesperado ou não óbvio. O código deve se explicar por nomes e tipos.
- Responda em **português do Brasil**.

### Guardrails de git
- Antes de cada commit: um resumo do que mudou e **pedir permissão**.
- Sem trailer de co-autoria nos commits.
- **Nunca** fazer push. **Nunca** abrir PR.

---

## 6. Entregáveis desta sessão

1. **`docs/escopo.md`** — escopo fechado do v0.1: objetivo, dentro/fora, critério de pronto, fases e marcos.
2. **`docs/adr/NNNN-titulo.md`** — um ADR por decisão relevante, no formato:
   - Contexto
   - Opções consideradas
   - Decisão
   - Consequências (inclusive o que fica mais difícil)
3. **`docs/perguntas-abertas.md`** — o que ficou para decidir depois e em que momento precisa ser decidido.
4. Ao final, um **CLAUDE.md** inicial para as sessões de implementação, resumindo o escopo, a stack, as convenções e os guardrails.

Comece lendo este arquivo inteiro, confirme em poucas linhas o que entendeu, e abra pelo bloco **4.1**.
