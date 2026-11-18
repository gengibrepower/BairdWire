# Governança

## Quem decide

Por enquanto, o projeto tem um mantenedor ([@gengibrepower](https://github.com/gengibrepower)), que toma as decisões finais (modelo BDFL). Com um mantenedor só, qualquer outra coisa seria teatro. A ideia é passar para um modelo com mais mantenedores quando houver contribuidores recorrentes, sem data prometida.

As decisões de arquitetura e de escopo são registradas como ADRs em `docs/adr/`. Uma mudança relevante precisa de um ADR novo.

## Controle sobre a rede e sobre o código

- **A rede não tem dono:** cada comunidade roda o próprio nó, e o projeto não mantém nenhum servidor central.
- **O código é AGPL-3.0-only:** qualquer pessoa pode fazer um fork, e quem oferecer uma versão modificada pela rede precisa disponibilizar o código.

## Sobre o CLA (transparência)

Contribuições externas exigem um CLA de licença: quem contribui **continua dono do seu código**, mas concede ao mantenedor uma licença ampla, que inclui o direito de relicenciar. Na prática, isso deixa em aberto a possibilidade de o projeto ser vendido ou licenciado comercialmente no futuro.

O que isso **não** muda: **toda versão já publicada sob a AGPL-3.0 continua AGPL-3.0 para sempre**, e qualquer pessoa pode continuar a partir dela. Isso não é uma promessa, é como as licenças funcionam.
