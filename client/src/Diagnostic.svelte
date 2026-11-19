<script lang="ts">
import { openSession, type SessionResult, socketUrl } from "./lib/session";

let running = $state(false);
let result = $state<SessionResult | null>(null);

const run = async () => {
  running = true;
  result = null;
  result = await openSession(socketUrl(window.location), "bairdwire-diagnostico");
  running = false;
};
</script>

<main>
  <h1>Diagnóstico do nó</h1>
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
</main>

<style>
  main {
    font-family: system-ui, sans-serif;
    max-width: 40rem;
    margin: 2rem auto;
    padding: 0 1rem;
  }
  .ok {
    color: #2e7d32;
  }
  .fail {
    color: #c62828;
  }
</style>
