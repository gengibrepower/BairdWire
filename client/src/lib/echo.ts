import {
  encodeHello,
  encodeRtcAnswer,
  encodeRtcCandidate,
  encodeRtcOffer,
  isRtcDescription,
  isSessionError,
  type PeerRole,
  parseEnvelope,
  supportedVersions,
} from "./protocol";

export interface EchoStats {
  publish: RTCPeerConnectionState;
  subscribe: RTCPeerConnectionState | "aguardando";
  packetsReceived: number;
  roundTripMs: number | null;
  transport: string | null;
}

export interface EchoCallbacks {
  onStats: (stats: EchoStats) => void;
  onError: (message: string) => void;
}

export interface Echo {
  stop: () => void;
}

const statsIntervalMs = 1000;

const openSocket = (url: string): Promise<WebSocket> =>
  new Promise((resolve, reject) => {
    const socket = new WebSocket(url);
    socket.addEventListener("open", () => resolve(socket), { once: true });
    socket.addEventListener("error", () => reject(new Error("o WebSocket não abriu")), {
      once: true,
    });
  });

const forwardCandidates = (socket: WebSocket, pc: RTCPeerConnection, role: PeerRole) => {
  pc.addEventListener("icecandidate", (event) => {
    const candidate = event.candidate;
    if (candidate === null || candidate.sdpMid === null || candidate.candidate === "") return;
    socket.send(
      encodeRtcCandidate({ pc: role, candidate: candidate.candidate, mid: candidate.sdpMid }),
    );
  });
};

const selectedPair = (
  report: RTCStatsReport,
): { roundTripMs: number | null; transport: string | null } => {
  for (const stats of report.values()) {
    if (stats.type !== "transport" || typeof stats.selectedCandidatePairId !== "string") continue;
    const pair = report.get(stats.selectedCandidatePairId);
    const local = pair === undefined ? undefined : report.get(pair.localCandidateId);
    return {
      roundTripMs:
        typeof pair?.currentRoundTripTime === "number"
          ? Math.round(pair.currentRoundTripTime * 1000)
          : null,
      transport: local === undefined ? null : `${local.protocol} (${local.candidateType})`,
    };
  }
  return { roundTripMs: null, transport: null };
};

const packetsReceived = (report: RTCStatsReport): number => {
  for (const stats of report.values()) {
    if (stats.type === "inbound-rtp" && stats.kind === "audio") return stats.packetsReceived ?? 0;
  }
  return 0;
};

export const startEcho = async (
  url: string,
  audio: HTMLAudioElement,
  callbacks: EchoCallbacks,
): Promise<Echo> => {
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  const socket = await openSocket(url).catch((error: unknown) => {
    for (const track of stream.getTracks()) track.stop();
    throw error;
  });

  const publish = new RTCPeerConnection();
  let subscribe: RTCPeerConnection | null = null;
  const helloId = crypto.randomUUID();
  const offerId = crypto.randomUUID();
  forwardCandidates(socket, publish, "publish");

  const sendOffer = async () => {
    const [track] = stream.getAudioTracks();
    if (track === undefined) throw new Error("o microfone não entregou uma track de áudio");
    publish.addTransceiver(track, { direction: "sendonly", streams: [stream] });
    await publish.setLocalDescription();
    const sdp = publish.localDescription?.sdp;
    if (sdp === undefined) throw new Error("o navegador não gerou a oferta");
    socket.send(encodeRtcOffer(offerId, sdp));
  };

  const answerSubscribe = async (id: string, sdp: string) => {
    const pc = new RTCPeerConnection();
    subscribe = pc;
    pc.addEventListener("track", (event) => {
      audio.srcObject = event.streams[0] ?? new MediaStream([event.track]);
    });
    forwardCandidates(socket, pc, "subscribe");
    await pc.setRemoteDescription({ type: "offer", sdp });
    await pc.setLocalDescription();
    const answer = pc.localDescription?.sdp;
    if (answer === undefined) throw new Error("o navegador não gerou a resposta");
    socket.send(encodeRtcAnswer(id, answer));
  };

  const onMessage = async (text: string) => {
    const envelope = parseEnvelope(text);
    if (envelope === null) return;
    if (envelope.t === "session.welcome" && envelope.re === helloId) {
      await sendOffer();
    } else if (
      envelope.t === "rtc.answer" &&
      envelope.re === offerId &&
      isRtcDescription(envelope.d)
    ) {
      await publish.setRemoteDescription({ type: "answer", sdp: envelope.d.sdp });
    } else if (
      envelope.t === "rtc.offer" &&
      envelope.id !== undefined &&
      isRtcDescription(envelope.d) &&
      envelope.d.pc === "subscribe"
    ) {
      await answerSubscribe(envelope.id, envelope.d.sdp);
    } else if (envelope.t === "session.error" && isSessionError(envelope.d)) {
      callbacks.onError(`o nó respondeu ${envelope.d.code}`);
    }
  };

  socket.addEventListener("message", (event) => {
    if (typeof event.data !== "string") return;
    onMessage(event.data).catch((error: unknown) => {
      callbacks.onError(error instanceof Error ? error.message : String(error));
    });
  });
  socket.addEventListener("close", (event) => {
    if (event.code !== 1000) callbacks.onError(`o WebSocket fechou (código ${event.code})`);
  });

  const timer = setInterval(async () => {
    const pair = selectedPair(await publish.getStats());
    const received = subscribe === null ? 0 : packetsReceived(await subscribe.getStats());
    callbacks.onStats({
      publish: publish.connectionState,
      subscribe: subscribe?.connectionState ?? "aguardando",
      packetsReceived: received,
      ...pair,
    });
  }, statsIntervalMs);

  socket.send(
    encodeHello(helloId, { versions: supportedVersions, client: "bairdwire-diagnostico" }),
  );

  return {
    stop: () => {
      clearInterval(timer);
      for (const track of stream.getTracks()) track.stop();
      publish.close();
      subscribe?.close();
      audio.srcObject = null;
      socket.close(1000);
    },
  };
};
