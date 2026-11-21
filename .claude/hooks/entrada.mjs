import { readFileSync } from "node:fs";

export const entrada = JSON.parse(readFileSync(0, "utf8"));
export const raiz = process.env.CLAUDE_PROJECT_DIR ?? entrada.cwd;
