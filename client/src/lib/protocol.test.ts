import { describe, expect, it } from "vitest";
import {
  encodeHello,
  encodeRtcAnswer,
  encodeRtcCandidate,
  encodeRtcOffer,
  isRtcDescription,
  isSessionError,
  isWelcome,
  parseEnvelope,
} from "./protocol";

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

describe("mensagens rtc", () => {
  it("rtc.offer sai sempre no publish, com id", () => {
    expect(JSON.parse(encodeRtcOffer("o1", "v=0"))).toEqual({
      v: 1,
      t: "rtc.offer",
      id: "o1",
      d: { pc: "publish", sdp: "v=0" },
    });
  });

  it("rtc.answer sai sempre no subscribe, com re", () => {
    expect(JSON.parse(encodeRtcAnswer("subscribe-2", "v=0"))).toEqual({
      v: 1,
      t: "rtc.answer",
      re: "subscribe-2",
      d: { pc: "subscribe", sdp: "v=0" },
    });
  });

  it("rtc.candidate leva pc, candidate e mid", () => {
    expect(
      JSON.parse(encodeRtcCandidate({ pc: "publish", candidate: "candidate:1", mid: "0" })),
    ).toEqual({
      v: 1,
      t: "rtc.candidate",
      d: { pc: "publish", candidate: "candidate:1", mid: "0" },
    });
  });

  it("isRtcDescription exige pc conhecido e sdp não vazio", () => {
    expect(isRtcDescription({ pc: "subscribe", sdp: "v=0" })).toBe(true);
    expect(isRtcDescription({ pc: "outro", sdp: "v=0" })).toBe(false);
    expect(isRtcDescription({ pc: "publish", sdp: "" })).toBe(false);
    expect(isRtcDescription({ pc: "publish" })).toBe(false);
  });
});
