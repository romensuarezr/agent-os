# Executive Design Digest — T-159

## 🎯 Objetivo
Implementar el cliente CLI determinista en Bash `scripts/agent/lib/bane-client.sh` para interactuar con la API del servicio Bane (deep research), con salida primaria por stdout en formato Markdown, soporte para flags estándar (`--query`, `--timeout`, `--output`, `--json`, `--check`), wrapper de timeout portable y semántica estricta de disponibilidad: el servicio se clasifica como activo única y exclusivamente si está configurado Y alcanzable dentro de la cota de tiempo, degradando de forma limpia y silenciosa si no está disponible sin bloquear la ejecución del agente.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-159 se ajusta de forma exacta al diseño macro aprobado en planning y al contrato formal de [.agents/tasks/task-159.md](file:///home/romen/orca/workspaces/agent-os/multi-agent/.agents/tasks/task-159.md). Define con precisión la interfaz de flags (`--query`, `--timeout`, `--output`, `--check`, `--json`), la salida primaria estructurada por stdout y la semántica binaria estricta para la sonda de salud (código 0 para activo y alcanzable dentro del timeout; código 2 para inactivo o no configurado) con degradación fail-soft.

La caja de archivos autorizados está estrictamente acotada a tres elementos (`scripts/agent/lib/bane-client.sh`, `tests/validate-control-plane.sh` y `.agents/tasks/task-159.md`), garantizando la preservación del denominador de la suite de control plane en 37/37 sin introducir dependencias externas ni riesgos de regresión.
- **Prospección Scout**: `CONFORME (sprint-28-research.md)`
  - Alternativa detectada:** `firecrawl-cli` (v1.26.24, NPM), `@anthropic-ai/sandbox-runtime` (v0.0.81, NPM).
  - Recomendación del agente:** Desarrollo a medida justificado (script CLI ligero en `scripts/agent/lib/bane-client.sh`).
  - Decisión del usuario:** Desarrollo a medida justificado — cliente determinista en Bash para interactuar con la API REST de Bane:
  - Salida estándar (stdout)*: La salida primaria del cliente es el resultado de la investigación en Markdown directo por stdout (o archivo de destino opcional con `--output`), facilitando pipes y composición UNIX.
- **Mensaje de Cierre**: `Merge branch 'feat/T-159-bane-cli-client' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-159.md`
- `docs/sprints/sprint-28-core.md`
- `scripts/agent/lib/bane-client.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `tool-inventory`
