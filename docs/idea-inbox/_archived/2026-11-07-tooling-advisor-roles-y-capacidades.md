# Idea: Matriz de roles por CLI + Capabilities Discovery (tooling-advisor)

- **Fecha:** 2026-11-07
- **Origen:** Conversación con Gemini depurada y verificada por el relé
  (búsqueda web + repo, 2026-11-07).
- **Estado:** 💡 REGISTRADA, NO APROBADA
- **Tipo:** Gobernanza de flota / Tooling (evolución autónoma del sistema).

## QUÉ (tareas para el planning, no el cómo)

1. **Matriz de roles:** decidir con evidencia qué CLI hace qué
   (OpenCode 2 worker, Claude Code juez, Aider rescate, Hermes front
   door, Antigravity deliberador), con las preguntas abiertas de abajo
   resueltas en planning, no asumidas.
2. **Capabilities Discovery:** sonda determinista de versiones
   (`check-tooling-updates.sh`) + skill `tooling-advisor` que propone
   mejoras a `docs/idea-inbox/` (propuestas, nunca auto-aplicar),
   con la fuente de versión correcta por herramienta.
3. **Despliegue bajo Opción D** en el siguiente sprint.

## Hechos de entrada (verificados)

- OpenCode 2 es la línea actual (v2.2.6, 7-nov-2026), binario
  `opencode` (`opencode2` fue solo el comando del periodo beta),
  repo `anomalyco/opencode` (antes `sst/opencode`), 2.x en npm como
  `@opencode/cli`. GitHub `releases/latest` sigue devolviendo la 1.x:
  NO sirve para detectar la 2.x. Ruptura v1→v2: plugins v1 no cargan,
  API de servidor cambiada, sin diagnósticos LSP.
- Orca ADE: repo `stablyai/orca` (`onorca.dev` es la web, no el repo),
  binario `orca-ide` en Linux.
- Hermes Agent existe (`NousResearch/hermes-agent`, binario `hermes`,
  v0.22.7): agente personal autoalojado con memoria y skills.
- Antigravity CLI es público (`agy`, modo headless `-p`, cuenta Google
  + plan). Su rol de deliberador NO está decidido (ensayo pendiente,
  cableado no autorizado); las promociones a `main` siguen siendo
  puerta humana.
- Claude Code `--dangerously-skip-permissions` real; Ralph Loop real
  (patrón 2025, plugin oficial `ralph-wiggum`); solo seguro en sandbox.
- Aider `--yes-always` real.
- Prompt Cache Timer existe en Orca: visor del TTL de caché de Claude
  (~300 s), no un ahorrador de contexto por sí mismo.
- Claude Teams en Orca real, desactivado por defecto.
- Renovate con Custom Regex Managers real (`datasource=github-releases`);
  abre PRs, NO issues. Dependabot NO tiene Custom Regex Managers.
- `new-releases.io` existe (avisos multi-registro + webhooks).
- La skill `idea-validator` citada NO existe en el repo
  (`tool-inventory` sí existe). El buzón canónico de ideas es
  `docs/idea-inbox/`, no `docs/external-inbox/`.
- Defectos del script propuesto: comparación de versiones por cadena
  (prefijo `v`), API de GitHub sin autenticar (límite 60/h), cuerpo
  del changelog volcado en crudo en la propuesta.

## Preguntas abiertas (las decide el planning)

- Hermes como front door duplica el daemon `whatsapp-bridge`
  existente: ¿sustituye, convive o se descarta?
- Aider rescatando merges entre worktrees choca con la doctrina de
  que solo coordinador/humano fusiona: ¿se admite como excepción?
- Claude Code como juez frente al revisor actual (Orca → `agy` →
  HTTP): ¿sustituye, complementa o se descarta?

## Descartado con motivo (no entra en la idea)

- `NousResearch/Hermes-Function-Calling` como librería de skills:
  es una demo 2024 de function calling a nivel de modelo, nada que
  ver con `llms.txt` ni con autogenerar interfaces.
- `Release-Notifier` como producto: no encontrado (el enlace era una
  búsqueda de Google, no una página de producto).
- Crawl4AI como componente: real pero fuera del stack, con 5 CVE
  críticas en 2026 (incl. RCE no autenticada, corregidas en 0.9.4+).
  Solo como evaluación futura (≥0.9.5, solo red interna), no ahora.

## Fuera de alcance

- Reescribir el puente de WhatsApp existente.
- Sustituir la verificación del relé contra origin.
- Promociones a `main` por ningún agente.
