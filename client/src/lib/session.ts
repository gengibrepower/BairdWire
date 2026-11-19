import {
  encodeHello,
  isSessionError,
  isWelcome,
  parseEnvelope,
  socketPath,
  supportedVersions,
  type Welcome,
} from "./protocol";

export type SessionResult =
  | { kind: "welcome"; welcome: Welcome }
  | { kind: "error"; code: string }
  | { kind: "closed"; code: number };

export const socketUrl = (location: Location): string => {
  const scheme = location.protocol === "https:" ? "wss:" : "ws:";
  return `${scheme}//${location.host}${socketPath}`;
};

export const openSession = (url: string, client: string): Promise<SessionResult> =>
  new Promise((resolve) => {
    const socket = new WebSocket(url);
    const helloId = crypto.randomUUID();
    let settled = false;
    const settle = (result: SessionResult) => {
      if (settled) return;
      settled = true;
      resolve(result);
    };

    socket.addEventListener("open", () => {
      socket.send(encodeHello(helloId, { versions: supportedVersions, client }));
    });
    socket.addEventListener("message", (event) => {
      if (typeof event.data !== "string") return;
      const envelope = parseEnvelope(event.data);
      if (envelope === null || envelope.re !== helloId) return;
      if (envelope.t === "session.welcome" && isWelcome(envelope.d)) {
        settle({ kind: "welcome", welcome: envelope.d });
      } else if (envelope.t === "session.error" && isSessionError(envelope.d)) {
        settle({ kind: "error", code: envelope.d.code });
      }
      socket.close(1000);
    });
    socket.addEventListener("close", (event) => settle({ kind: "closed", code: event.code }));
  });
