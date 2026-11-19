<script lang="ts">
import { type Echo, type EchoStats, startEcho } from "./lib/echo";
import { openSession, type SessionResult, socketUrl } from "./lib/session";

let running = $state(false);
let result = $state<SessionResult | null>(null);

let audio: HTMLAudioElement | undefined = $state();
let echo: Echo | null = $state(null);
let starting = $state(false);
let stats = $state<EchoStats | null>(null);
let echoError = $state<string | null>(null);

const run = async () => {
  running = true;
  result = null;
  result = await openSession(socketUrl(window.location), "bairdwire-diagnostico");
  running = false;
};

const toggleEcho = async () => {
  if (echo !== null) {
    echo.stop();
    echo = null;
    stats = null;
    return;
  }
  if (audio === undefined) return;
  starting = true;
  echoError = null;
  try {
    echo = await startEcho(socketUrl(window.location), audio, {
      onStats: (next) => {
        stats = next;
      },
      onError: (message) => {
        echoError = message;
      },
    });
  } catch (error) {
    echoError = error instanceof Error ? error.message : String(error);
  } finally {
    starting = false;
  }
};
</script>

<main>
  <h1>Diagnóstico do nó</h1>

  <section>
    <h2>WebSocket</h2>
    <button type="button" onclick={run} disabled={running}>
      {running ? "Testando…" : "Testar o WebSocket"}
    </button>

    {#if result?.kind === "welcome"}
      <p class="ok">Conectado: protocolo v{result.welcome.version}, nó {result.welcome.node}.</p>
    {:else if result?.kind === "error"}
      <p class="fail">O nó recusou o hello: {result.code}.</p>
    {:else if result?.kind === "closed"}
      <p class="fail">A conexão fechou antes do welcome (código {result.code}).</p>
    {/if}
  </section>

  <section>
    <h2>Eco de áudio</h2>
    <p>O áudio do microfone vai até o nó e volta. Use fone de ouvido para não microfonar.</p>
    <button type="button" onclick={toggleEcho} disabled={starting}>
      {echo === null ? (starting ? "Iniciando…" : "Testar o eco") : "Parar o eco"}
    </button>
    <audio bind:this={audio} autoplay></audio>

    {#if stats !== null}
      <dl>
        <dt>Publish</dt>
        <dd>{stats.publish}</dd>
        <dt>Subscribe</dt>
        <dd>{stats.subscribe}</dd>
        <dt>Pacotes recebidos de volta</dt>
        <dd class:ok={stats.packetsReceived > 0}>{stats.packetsReceived}</dd>
        <dt>RTT até o nó</dt>
        <dd>{stats.roundTripMs === null ? "—" : `${stats.roundTripMs} ms`}</dd>
        <dt>Transporte</dt>
        <dd>{stats.transport ?? "—"}</dd>
      </dl>
    {/if}
    {#if echoError !== null}
      <p class="fail">{echoError}</p>
    {/if}
  </section>
</main>

<style>
  main {
    font-family: system-ui, sans-serif;
    max-width: 40rem;
    margin: 2rem auto;
    padding: 0 1rem;
  }
  section {
    margin-top: 2rem;
  }
  dl {
    display: grid;
    grid-template-columns: max-content 1fr;
    gap: 0.25rem 1rem;
  }
  dt {
    font-weight: 600;
  }
  dd {
    margin: 0;
  }
  .ok {
    color: #2e7d32;
  }
  .fail {
    color: #c62828;
  }
</style>
