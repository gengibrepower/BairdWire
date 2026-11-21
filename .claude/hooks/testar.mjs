import { execFileSync } from "node:child_process";
import { entrada, raiz } from "./entrada.mjs";

if (entrada.stop_hook_active) process.exit(0);

const git = (...args) => execFileSync("git", args, { cwd: raiz, encoding: "utf8" });
const base = git("merge-base", "HEAD", "main").trim();
const mudados = [
  ...git("diff", "--name-only", base).split("\n"),
  ...git("ls-files", "--others", "--exclude-standard").split("\n"),
].filter(Boolean);

// mesmos gatilhos do ci.yml (.github/scripts/changed.sh)
const mexeuNoNo = mudados.some((f) => /^(node\/|\.zig-version$|mise\.toml$)/.test(f));
const mexeuNoCliente = mudados.some((f) => /^(client\/|deploy\/Caddyfile$|pnpm-|mise\.toml$)/.test(f));

const falhas = [];
const rodar = (nome, cmd, args, cwd) => {
  try {
    execFileSync(cmd, args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  } catch (erro) {
    const saida = `${erro.stdout ?? ""}${erro.stderr ?? ""}`.trim().split("\n").slice(-40).join("\n");
    falhas.push(`## ${nome}\n${saida}`);
  }
};

if (mexeuNoNo) rodar("zig build test", "mise", ["exec", "--", "zig", "build", "test"], `${raiz}/node`);
if (mexeuNoCliente) {
  rodar("vitest", "pnpm", ["--filter", "@bairdwire/client", "exec", "vitest", "run"], raiz);
  rodar("svelte-check", "pnpm", ["--filter", "@bairdwire/client", "run", "check"], raiz);
}

if (falhas.length > 0) {
  process.stdout.write(
    JSON.stringify({
      decision: "block",
      reason: `Os testes da parte que mudou falharam. Corrija antes de encerrar:\n\n${falhas.join("\n\n")}`,
    }),
  );
}
