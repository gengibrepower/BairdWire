import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { decidir, ESTADOS, lerRegras } from "./dominio.mjs";

const aqui = dirname(fileURLToPath(import.meta.url));
const raizDoRepo = join(aqui, "../..");

const regras = [
  { caminho: "node/src/core/", estado: "aprendendo", adr: "0042" },
  { caminho: "node/src/core/sdp.zig", estado: "delegada", adr: "0050" },
  { caminho: "node/src/core/rtp/", estado: "em-prova", adr: "0051" },
  { caminho: "node/build/", estado: "divida", adr: "0042" },
  { caminho: "client/", estado: "fora-do-objetivo", adr: "0042" },
];

const repoTemporario = (conteudo) => {
  const raiz = mkdtempSync(join(tmpdir(), "dominio-"));
  mkdirSync(join(raiz, "docs"));
  if (conteudo !== undefined) writeFileSync(join(raiz, "docs/dominio.json"), conteudo);
  return raiz;
};

test("o docs/dominio.json do repositório é válido", () => {
  assert.notEqual(lerRegras(raizDoRepo), null);
});

test("os cinco estados", () => {
  assert.deepEqual(ESTADOS, ["aprendendo", "em-prova", "delegada", "divida", "fora-do-objetivo"]);
  assert.equal(decidir("node/src/core/node.zig", regras).permitir, false);
  assert.equal(decidir("node/src/core/rtp/parser.zig", regras).permitir, false);
  assert.equal(decidir("node/src/core/sdp.zig", regras).permitir, true);
  assert.equal(decidir("node/build/mbedtls.zig", regras).permitir, true);
  assert.equal(decidir("client/src/App.svelte", regras).permitir, true);
});

test("o caminho mais específico vence, nos dois sentidos", () => {
  assert.equal(decidir("node/src/core/sdp.zig", regras).estado, "delegada");
  assert.equal(decidir("node/src/core/rtp/parser.zig", regras).estado, "em-prova");
  const invertido = [...regras].reverse();
  assert.equal(decidir("node/src/core/sdp.zig", invertido).estado, "delegada");
});

test("um arquivo não cobre outro com o mesmo prefixo", () => {
  assert.equal(decidir("node/src/core/sdp.zig.bak", regras).estado, "aprendendo");
});

test("*_test.zig é liberado em aprendendo e em-prova", () => {
  assert.equal(decidir("node/src/core/node_test.zig", regras).permitir, true);
  assert.equal(decidir("node/src/core/rtp/parser_test.zig", regras).permitir, true);
});

test("caminho não coberto em node/src/ conta como aprendendo", () => {
  const d = decidir("node/src/novo.zig", regras);
  assert.equal(d.permitir, false);
  assert.equal(d.estado, "aprendendo");
  assert.match(d.motivo, /não está em docs\/dominio\.json/);
});

test("caminho não coberto fora de node/src/ é livre", () => {
  assert.equal(decidir("README.md", regras).permitir, true);
});

test("a mensagem cita o estado e o ADR, e em-prova proíbe sugerir design", () => {
  const aprendendo = decidir("node/src/core/node.zig", regras).motivo;
  assert.match(aprendendo, /`aprendendo` \(ADR 0042\)/);
  assert.match(aprendendo, /não escreva a implementação/);
  const emProva = decidir("node/src/core/rtp/parser.zig", regras).motivo;
  assert.match(emProva, /`em-prova` \(ADR 0051\)/);
  assert.match(emProva, /nem sugira design/);
});

test("JSON ausente ou inválido bloqueia node/src/, inclusive testes, e libera o resto", () => {
  for (const conteudo of [undefined, "{", "{}", '[{"caminho":"node/src/","estado":"livre"}]', '[{"estado":"divida"}]']) {
    const r = lerRegras(repoTemporario(conteudo));
    assert.equal(r, null, String(conteudo));
    assert.equal(decidir("node/src/core/node_test.zig", r).permitir, false);
    assert.match(decidir("node/src/main.zig", r).motivo, /ausente ou inválido/);
    assert.equal(decidir("client/src/App.svelte", r).permitir, true);
  }
});

test("o hook do Claude Code sai com 2 ao bloquear e 0 ao liberar", () => {
  const raiz = repoTemporario(JSON.stringify(regras));
  const rodar = (arquivo) =>
    spawnSync(process.execPath, [join(aqui, "area-do-autor.mjs")], {
      input: JSON.stringify({ cwd: raiz, tool_input: { file_path: join(raiz, arquivo) } }),
      env: { ...process.env, CLAUDE_PROJECT_DIR: raiz },
      encoding: "utf8",
    });
  const bloqueado = rodar("node/src/core/node.zig");
  assert.equal(bloqueado.status, 2);
  assert.match(bloqueado.stderr, /aprendendo/);
  assert.equal(rodar("node/build/mbedtls.zig").status, 0);
});
