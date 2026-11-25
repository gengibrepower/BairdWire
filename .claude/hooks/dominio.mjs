import { readFileSync } from "node:fs";
import { join } from "node:path";

export const ESTADOS = ["aprendendo", "em-prova", "delegada", "divida", "fora-do-objetivo"];
const BLOQUEADOS = ["aprendendo", "em-prova"];
const AREA_FECHADA = "node/src/";

export function lerRegras(raiz) {
  try {
    const regras = JSON.parse(readFileSync(join(raiz, "docs/dominio.json"), "utf8"));
    const valida =
      Array.isArray(regras) &&
      regras.every((r) => typeof r?.caminho === "string" && r.caminho !== "" && ESTADOS.includes(r.estado));
    return valida ? regras : null;
  } catch {
    return null;
  }
}

const cobre = (regra, caminho) =>
  regra.caminho.endsWith("/") ? caminho.startsWith(regra.caminho) : caminho === regra.caminho;

// caminho relativo à raiz do repositório; regras null = dominio.json ausente ou inválido
export function decidir(caminho, regras) {
  const fechada = caminho.startsWith(AREA_FECHADA);
  if (regras === null) {
    return fechada
      ? {
          permitir: false,
          motivo: `docs/dominio.json está ausente ou inválido, então a escrita em ${AREA_FECHADA} fica bloqueada (ADR 0042). Corrija o JSON antes de continuar.`,
        }
      : { permitir: true };
  }

  const regra = regras
    .filter((r) => cobre(r, caminho))
    .reduce((maior, r) => (maior && maior.caminho.length >= r.caminho.length ? maior : r), null);
  const estado = regra?.estado ?? (fechada ? "aprendendo" : null);
  if (!BLOQUEADOS.includes(estado) || caminho.endsWith("_test.zig")) return { permitir: true, estado };

  const adr = regra?.adr ?? "0042";
  const origem = regra ? `está em \`${estado}\` (ADR ${adr})` : `não está em docs/dominio.json e conta como \`aprendendo\` (ADR 0042)`;
  const regraDoEstado =
    estado === "em-prova"
      ? "O autor escreve sozinho, do arquivo vazio: não escreva código nem sugira design; só aponte erros de API depois de o autor terminar."
      : "Explique, revise ou escreva testes em *_test.zig, mas não escreva a implementação, nem um trecho.";
  return { permitir: false, estado, motivo: `${caminho} ${origem}. ${regraDoEstado}` };
}
