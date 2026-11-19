import { describe, expect, it } from "vitest";
import caddyfile from "../deploy/Caddyfile?raw";
import { productionCsp } from "./csp.ts";

describe("CSP de produção", () => {
  it("é o mesmo no Caddyfile e no cliente", () => {
    const header = caddyfile.match(/Content-Security-Policy "([^"]+)"/);
    expect(header?.[1]).toBe(productionCsp);
  });
});
