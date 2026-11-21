import { relative } from "node:path";
import { entrada, raiz } from "./entrada.mjs";

const arquivo = entrada.tool_input?.file_path ?? entrada.tool_input?.notebook_path;
if (!arquivo) process.exit(0);

const caminho = relative(raiz, arquivo);
const areaDoAutor =
  caminho.startsWith("node/src/core/") ||
  caminho.startsWith("node/src/adapters/") ||
  caminho === "node/src/runtime.zig" ||
  caminho === "node/src/main.zig";

if (areaDoAutor && !caminho.endsWith("_test.zig")) {
  process.stderr.write(
    `${caminho} é área do autor (ADR 0040): explique, revise ou escreva testes em *_test.zig, mas não escreva a implementação.\n`,
  );
  process.exit(2);
}
