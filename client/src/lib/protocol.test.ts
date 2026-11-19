import { describe, expect, it } from "vitest";
import { encodeHello, isSessionError, isWelcome, parseEnvelope } from "./protocol";

describe("encodeHello", () => {
  it("segue o formato congelado do ADR 0035", () => {
    expect(JSON.parse(encodeHello("h1", { versions: [1], client: "diag" }))).toEqual({
      v: 1,
      t: "session.hello",
      id: "h1",
      d: { versions: [1], client: "diag" },
    });
  });
});

describe("parseEnvelope", () => {
  it("lê o welcome do nó", () => {
    const envelope = parseEnvelope(
      '{"v":1,"t":"session.welcome","re":"h1","d":{"version":1,"node":"0.1.0-dev","resumed":false}}',
    );
    expect(envelope?.t).toBe("session.welcome");
    expect(envelope?.re).toBe("h1");
    expect(isWelcome(envelope?.d)).toBe(true);
  });

  it.each(["", "nao json", "[]", "null", '{"t":"x"}', '{"v":"1","t":"x"}', '{"v":1}'])(
    "rejeita %j",
    (text) => {
      expect(parseEnvelope(text)).toBeNull();
    },
  );

  it("ignora campos desconhecidos e id/re com tipo errado", () => {
    expect(parseEnvelope('{"v":1,"t":"x","id":7,"re":null,"extra":true}')).toEqual({
      v: 1,
      t: "x",
      d: undefined,
    });
  });
});

describe("guards", () => {
  it("isWelcome exige os três campos", () => {
    expect(isWelcome({ version: 1, node: "n" })).toBe(false);
    expect(isWelcome({ version: 1, node: "n", resumed: false })).toBe(true);
  });

  it("isSessionError exige o code", () => {
    expect(isSessionError({ code: "hello_timeout" })).toBe(true);
    expect(isSessionError({ supported: [1] })).toBe(false);
  });
});
