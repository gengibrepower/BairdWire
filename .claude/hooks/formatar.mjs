import { execFileSync } from "node:child_process";
import { relative } from "node:path";
import { entrada, raiz } from "./entrada.mjs";

const arquivo = entrada.tool_input?.file_path;
if (!arquivo) process.exit(0);

const caminho = relative(raiz, arquivo);
const rodar = (cmd, args, cwd) => {
  try {
    execFileSync(cmd, args, { cwd, stdio: ["ignore", "ignore", "pipe"] });
  } catch (erro) {
    process.stderr.write(`${cmd} ${args.join(" ")}: ${erro.stderr ?? erro.message}\n`);
  }
};

if (caminho.endsWith(".zig")) {
  rodar("mise", ["exec", "--", "zig", "fmt", arquivo], raiz);
} else if (caminho.startsWith("client/") && /\.(ts|js|svelte|json|css)$/.test(caminho)) {
  rodar("./node_modules/.bin/biome", ["format", "--write", arquivo], `${raiz}/client`);
}
