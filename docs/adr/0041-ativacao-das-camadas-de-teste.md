# ADR 0041 — Ativação das camadas de teste por fase

**Status:** aceito
**Data:** 2026-11-20
**Revisa:** a frequência das camadas no ADR 0031 e a lista de CI por PR no ADR 0032

## Contexto

O ADR 0031 define 8 camadas de teste, cada uma com uma frequência, como se todas existissem desde o início. O ADR 0032 lista os testes do protocolo (camada 4) na CI de cada PR. No fim do M0, existem só a camada 1 (unitário do núcleo, além dos smoke tests das bibliotecas nativas) e a camada 5 sem o corpus de XSS, porque o Markdown ainda não existe. A camada 4 não existe, e as camadas 2, 3, 6, 7 e 8 também não.

Escrever agora a simulação e o fuzzing do núcleo seria testar um código que vai ser reescrito à mão (ADR 0040). E documentos que descrevem uma CI que não existe confundem quem lê e quem automatiza.

## Opções consideradas

- **Construir todas as camadas já:** muito trabalho em infraestrutura de teste para um núcleo que vai ser reescrito.
- **Deixar o ADR 0031 como está e ignorar a diferença:** o documento continua descrevendo uma CI que não existe.
- **Manter as 8 camadas como meta e definir quando cada uma entra.**

## Decisão

As 8 camadas continuam sendo a meta. Cada uma entra quando a fase precisa dela:

| Camada | Entra |
|---|---|
| 1. Unitário do núcleo | Já |
| 5. Cliente unitário | Já; o corpus de XSS entra com o Markdown, na fase 2 |
| 4. Integração do protocolo | Fase 1 |
| 2. Simulação determinística e 3. Fuzzing | Quando o núcleo reescrito tiver a máquina de estados |
| 6. End-to-end no navegador | Fase 2 |
| 7. Rede e carga | Fase 4 |
| 8. Soak de 7 dias | Fase 5 |

- A CI de cada PR roda as camadas que já existem. A lista de CI do ADR 0032 passa a valer conforme as camadas entram.
- Uma camada só entra quando já vem na CI, com a frequência do ADR 0031.
- A regra do teste de regressão do ADR 0031 vale desde já, na camada mais barata que exista.

## Consequências

- Os documentos passam a descrever a CI real.
- Antes de cada fase, quem planeja confere quais camadas ela traz.
- A simulação e o fuzzing nascem junto com o núcleo escrito pelo autor, e não sobre o código que vai ser reescrito.
- Fica mais difícil: pegar cedo os bugs de concorrência e de parser. Até a simulação e o fuzzing entrarem, eles dependem dos testes unitários e da integração.
