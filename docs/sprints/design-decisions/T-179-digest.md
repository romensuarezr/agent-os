# Executive Design Digest — T-179

## 🎯 Objetivo
Ampliar el esquema declarativo de la flota en `.agents/config/fleet.example.yaml` y `.agents/config/fleet.yaml` para permitir la especificación y diagnóstico de servidores Model Context Protocol (MCP) remotos con transporte HTTP streamable o SSE (`url`, `headers`, `transport`), adaptando la sonda determinista `scripts/agent/fleet-doctor.sh` para verificar su disponibilidad sin fugar credenciales.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico propuesto para T-179 satisface plenamente los requisitos de determinismo, seguridad y arquitectura desacoplada de Agent OS. La delimitación de la caja de archivos es estricta (4 archivos), se garantiza la retrocompatibilidad con servidores MCP locales basados en transporte stdio y se prevé un aislamiento fail-soft de 2 segundos junto con redacción de endpoints y cabeceras de autorización para prevenir la fuga de secretos en diagnósticos.

La estrategia de verificación salvaguarda el estándar inmutable de la suite de control plane (38/38 checks) y el resumen en texto de fleet-doctor.sh se mantiene acotado a 20 líneas. No existen objeciones técnicas ni riesgos de regresión arquitectónica, por lo que se emite consenso para su ejecución.
- **Prospección Scout**: `CONFORME (sprint-32-research.md)`
  - Alternativa detectada:** Especificación oficial de Model Context Protocol (MCP) para transporte Streamable HTTP / Server-Sent Events (SSE); servidores MCP comunitarios y remotos; esquema actual de `mcpServers` en `.agents/config/fleet.yaml` y `.agents/config/fleet.example.yaml` limitado a stdio (`command`/`args`/`env`).
  - Recomendación del agente:** Extender el esquema declarativo de `fleet.yaml` para soportar servidores MCP remotos vía `url` (con tipo opcional `transport: http` o `sse`), validando sintaxis de forma determinista en `fleet-doctor.sh` y `validate-control-plane.sh`.
  - Dictamen del Operador:** Aprobada. Base indispensable para registrar servidores como DeepWiki sin necesidad de wrappers de ejecución local pesados.
  - Notas de integración:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-179-soporte-declarativo-mcp-remotos-fleet' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/fleet.example.yaml`
- `.agents/tasks/_archived/task-179.md`
- `docs/sprints/sprint-32-core.md`
- `scripts/agent/fleet-doctor.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
