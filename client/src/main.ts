import { mount } from "svelte";
import Diagnostic from "./Diagnostic.svelte";

const target = document.getElementById("app");
if (target === null) throw new Error("elemento #app não encontrado");

mount(Diagnostic, { target });
