export const protocolVersion = 1;
export const supportedVersions = [1] as const;
export const socketPath = "/api/ws";

export interface Envelope<D = unknown> {
  v: number;
  t: string;
  id?: string;
  re?: string;
  d?: D;
}

export interface Hello {
  versions: readonly number[];
  client?: string;
  resume?: string | null;
}

export interface Welcome {
  version: number;
  node: string;
  resumed: boolean;
}

export interface SessionError {
  code: string;
  supported?: number[];
}

export const encodeHello = (id: string, hello: Hello): string =>
  JSON.stringify({
    v: protocolVersion,
    t: "session.hello",
    id,
    d: hello,
  } satisfies Envelope<Hello>);

const isObject = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);

export const parseEnvelope = (text: string): Envelope | null => {
  let value: unknown;
  try {
    value = JSON.parse(text);
  } catch {
    return null;
  }
  if (!isObject(value) || typeof value.v !== "number" || typeof value.t !== "string") return null;
  const envelope: Envelope = { v: value.v, t: value.t, d: value.d };
  if (typeof value.id === "string") envelope.id = value.id;
  if (typeof value.re === "string") envelope.re = value.re;
  return envelope;
};

export const isWelcome = (d: unknown): d is Welcome =>
  isObject(d) &&
  typeof d.version === "number" &&
  typeof d.node === "string" &&
  typeof d.resumed === "boolean";

export const isSessionError = (d: unknown): d is SessionError =>
  isObject(d) && typeof d.code === "string";

export type PeerRole = "publish" | "subscribe";

export interface RtcDescription {
  pc: PeerRole;
  sdp: string;
}

export interface RtcCandidate {
  pc: PeerRole;
  candidate: string;
  mid: string;
}

export const encodeRtcOffer = (id: string, sdp: string): string =>
  JSON.stringify({
    v: protocolVersion,
    t: "rtc.offer",
    id,
    d: { pc: "publish", sdp },
  } satisfies Envelope<RtcDescription>);

export const encodeRtcAnswer = (re: string, sdp: string): string =>
  JSON.stringify({
    v: protocolVersion,
    t: "rtc.answer",
    re,
    d: { pc: "subscribe", sdp },
  } satisfies Envelope<RtcDescription>);

export const encodeRtcCandidate = (candidate: RtcCandidate): string =>
  JSON.stringify({
    v: protocolVersion,
    t: "rtc.candidate",
    d: candidate,
  } satisfies Envelope<RtcCandidate>);

export const isRtcDescription = (d: unknown): d is RtcDescription =>
  isObject(d) &&
  (d.pc === "publish" || d.pc === "subscribe") &&
  typeof d.sdp === "string" &&
  d.sdp.length > 0;
