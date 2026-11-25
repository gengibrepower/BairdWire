# Dívidas de aprendizado

Áreas em estado `divida` ([ADR 0042](adr/0042-dominio-por-area.md)): o assistente escreve, mas o autor não domina a área e pretende aprender. Cada entrada diz o que exatamente o autor está devendo e quando a dívida pode virar `aprendendo`. O estado de cada caminho fica em [`dominio.json`](dominio.json).

## Build do nó: `node/build.zig`, `node/build.zig.zon`, `node/build/`

**Por que virou dívida e quando:** em 2026-11-24, no ADR 0042, o autor escolheu não aprender o build agora porque seria demais para o momento: o núcleo e os adaptadores já são o foco. O build continua com o assistente até lá.

**Tópicos, em ordem de estudo**, cada um ligado ao código atual:

1. **O grafo de passos do `std.Build`.** O `build()` não compila nada. Ele declara passos (`addExecutable`, `addTest`, `addRunArtifact`) e liga as dependências entre eles (`dependOn`). Os passos com nome são o `b.step("run", ...)` e o `b.step("test", ...)` do `build.zig`. O `install` é implícito (`b.installArtifact(exe)`).
2. **Módulos e imports.** O `b.addModule("core", ...)` cria um módulo público, e o `b.createModule(...)` cria um privado. O `.imports` dá nome a cada módulo (`"core"`, `"websocket"`, `"rtc_c"`). O núcleo é testado sozinho (`addTest(.{ .root_module = core })`) e também pelo módulo do executável.
3. **Target e otimização.** O `b.standardTargetOptions` gera o `-Dtarget`. O `b.standardOptimizeOption(.{ .preferred_optimize_mode = .safe })` faz o `-Drelease` virar `ReleaseSafe`, que é o build de produção do `CLAUDE.md`. O `optimize` desce para cada biblioteca, e o `libjuice.zig` usa esse valor para definir o `RELEASE`.
4. **Dependências no `build.zig.zon`.** Os campos `.url` e `.hash`: o hash é do conteúdo do pacote, e não do tarball. O `zig fetch --save <url>` preenche os dois. Também entram o `.fingerprint`, o `.minimum_zig_version` (ADR 0028) e o `.paths`. Algumas URLs apontam para tags (`mbedtls-3.6.8`, `v0.24.6`) e outras para commits fixos, e o motivo está no ADR 0034. O `b.dependency("x", .{})` devolve o `Dependency`, e o `upstream.path(...)` aponta para arquivos dentro dele. O `websocket` é um pacote Zig com `build.zig` próprio, e por isso usa `.module("websocket")` em vez de compilar fontes.
5. **Compilar uma biblioteca em C a partir das fontes.** É o padrão comum a todos os `build/*.zig`:
   - `createModule` com `.link_libc` (e `.link_libcpp` na `libdatachannel`, que é C++);
   - `addCSourceFiles` com `.root`, a lista `sources` e `.flags` (`-std=c99`, `gnu99`, `gnu11`, `c++17`, além dos `-Wno-...` do `usrsctp`);
   - `addIncludePath` para os headers do upstream;
   - `addLibrary`, que produz uma biblioteca estática.

   Também cabe aqui como escolher a lista `sources`: por que a `libsrtp` compila só os `*_mbedtls.c`, e por que o `usrsctp` não compila tudo.
6. **Macros e configuração em tempo de compilação:**
   - `addCMacro` com valor (`JUICE_STATIC`, `RTC_*`, `USE_MBEDTLS`);
   - macros que dependem do alvo (`HAVE_SYS_QUEUE_H` fora do musl, no `usrsctp.zig`);
   - o header de configuração do usuário da Mbed TLS (`MBEDTLS_USER_CONFIG_FILE` e `bairdwire_mbedtls_config.h`, com DTLS-SRTP e threads);
   - o `addConfigHeader` no estilo CMake da `libsrtp`, que gera um `config.h` a partir do `config_in_cmake.h`, com valores tirados do alvo (`isX86`, `endian`, `cTypeByteSize`).
7. **Headers instalados e ligação entre bibliotecas.** O `installHeadersDirectory` e o `installHeader` definem o que quem usa a biblioteca enxerga (`getEmittedIncludeTree`), incluindo o subdiretório `srtp2/` que a `libdatachannel` espera. Na ligação entram o `linkLibrary` e a ordem das dependências (Mbed TLS → libsrtp → libdatachannel), além do `mbedtls.link`, que repete a macro de configuração em quem liga. O `Deps` agrupa as quatro bibliotecas.
8. **Chamar C a partir de Zig.** O `addTranslateC` transforma um `smoke.h` num módulo Zig (`rtc_c`, `<nome>_c`). O `defineCMacro` faz o tradutor ver as mesmas macros que o compilador viu, e por isso o `libdatachannel.macros` é público e usado nos dois lugares.
9. **Os smoke tests.** A struct `Smoke` no `build.zig` cria, para cada biblioteca, um teste que importa o header traduzido, liga a lib e chama a API mínima (por exemplo, `node/build/libjuice/smoke_test.zig`, que cria um agente e confere o `a=ice-ufrag:`). Todos dependem do passo `test`. Este tópico também mostra por que o `comptime name` permite montar os caminhos com `++`.
10. **Cross-compile.** O `-Dtarget=x86_64-linux-musl` e o `aarch64-linux-musl` da CI e do `just check-no`: o Zig traz a libc e o compilador C de cada alvo, então nada muda no `build.zig`, só o que já depende de `target.result`. Entram aqui o que muda com o musl (o `usrsctp`) e por que os testes rodam no x86_64 e não no aarch64.

**Exercício sugerido, fora do BairdWire:** um projeto novo com um `build.zig` escrito do zero, que:
- compile uma biblioteca pequena em C a partir das fontes, trazida pelo `build.zig.zon` com `zig fetch --save` (por exemplo, o `cJSON` ou a `miniz`);
- defina uma macro de configuração;
- instale o header e traduza esse header com `addTranslateC`;
- tenha um teste em Zig que chame a biblioteca;
- passe no `zig build test -Dtarget=aarch64-linux-musl -Drelease` (só compilar para esse alvo, sem rodar, já vale).

**Condição para passar a `aprendendo`:** o autor fechar as issues atuais do núcleo e decidir puxar a dívida. A mudança é um ADR curto que revisa o 0042, mais a entrada no `dominio.json`. A partir daí, o build segue o critério de promoção normal: o exercício acima conta como o primeiro módulo escrito do arquivo vazio, e o `build/<lib>.zig` seguinte já é escrito pelo autor no repositório.
