import { svelte } from "@sveltejs/vite-plugin-svelte";
import { defineConfig } from "vite";
import { developmentCsp, devNonce } from "./csp";

export default defineConfig({
  plugins: [svelte()],
  html: { cspNonce: devNonce },
  server: {
    headers: { "Content-Security-Policy": developmentCsp },
    proxy: {
      "/api/ws": { target: "ws://127.0.0.1:8090", ws: true },
    },
  },
  preview: {
    headers: { "Content-Security-Policy": developmentCsp },
  },
  build: { target: "es2022" },
});
