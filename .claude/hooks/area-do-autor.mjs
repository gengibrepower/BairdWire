import { relative } from "node:path";
import { decidir, lerRegras } from "./dominio.mjs";
import { entrada, raiz } from "./entrada.mjs";

const arquivo = entrada.tool_input?.file_path ?? entrada.tool_input?.notebook_path;
if (!arquivo) process.exit(0);

const decisao = decidir(relative(raiz, arquivo), lerRegras(raiz));
if (!decisao.permitir) {
  process.stderr.write(`${decisao.motivo}\n`);
  process.exit(2);
}
