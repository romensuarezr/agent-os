# Idea: Inspección Estática/Dinámica mediante Servidores MCP de Ingeniería Inversa (Patrón REA / Clean-Room)

- **Fecha:** 2026-10-21
- **Origen:** Vídeo de divulgación de Alejavi Rivera (*"Adiós Apps de Pago... La IA las está Recreando GRATIS"*) y auge de herramientas MCP como REA (*Reverse Engineer Anything*).
- **Estado:** 💡 Capturada para evaluación de arquitectura / backlog futuro.
- **Tipo:** Skill / MCP Tooling / Protocolo de Calidad.

---

## 1. Referencias y Enlaces Clave
- **Vídeo analizado:** [Adiós Apps de Pago... La IA las está Recreando GRATIS 🤯 (YouTube)](https://www.youtube.com/watch?v=R0uRwRgKxLg)
- **Repositorio REA (Reverse Engineer Anything):** [https://github.com/NabilRFG12/Reverse-Engineer-anything](https://github.com/NabilRFG12/Reverse-Engineer-anything)
  - Paquete CLI / Servidor MCP: `npx rea-agents setup` / `npm i -g rea-agents`
- **Proyecto ArtCraft (Brandon Thomas / storytold):** [https://github.com/storytold/craft-launcher-assets](https://github.com/storytold/craft-launcher-assets)
  - Documentación de clean-room & AGENTS.md: [Photoshop and Word Rebuilt by AI: Is It Legal? (innfactory analysis)](https://innfactory.ai/en/blog/ai-rebuilt-photoshop-word-reverse-engineering/)

---

## 2. Resumen Conceptual
El contenido explora la confluencia entre **ingeniería inversa guiada por agentes** y la **recreación de software desde cero**:
1. **Patrón Servidor MCP de Inspección (REA):** Conecta agentes de programación (Claude Code, Pi, OpenCode, Codex) con motores de análisis binario y desensamblado (Ghidra, Hopper, dumps de Electron/AST). En lugar de que el LLM invente interfaces o protocolos, el agente invoca herramientas MCP para trazar llamadas IPC, formatos de archivo binarios o esquemas de red.
2. **Arquitectura Clean-Room (Sala Blanca):** El agente inspector analiza el comportamiento, estructuras de datos y salidas observadas desde el exterior, mientras que el agente ejecutor programa la solución en Rust/TypeScript de forma limpia sin copiar código protegido, cumpliendo especificaciones de formato (como PSD/DOCX) mediante tests automáticos.

---

## 3. Posible Valor para `agent-os` y la Flota
- **Skill de Reconstrucción de Contratos / Mocking:** Evaluar si un sub-agente o skill puede usar herramientas de introspección (curl, schema sniffers, AST parsers o REA) para generar stubs y mocks deterministas a partir de APIs externas o bibliotecas heredadas.
- **Auditoría Forense y de Protocolos:** Soporte opcional para registrar un servidor MCP de introspección en `.agents/config/fleet.yaml` para proyectos que requieran migración de código legado o análisis de binarios.
  - *(Nota de captura: la ruta canónica es `.agents/config/fleet.yaml`; el bloque `mcpServers:` ya existe en `.agents/config/fleet.example.yaml` con formato `command`/`args`/`env`/`description`. La ruta `config/fleet.yaml` de la raíz fue deprecada y `audit-child.sh:163` la limpia.)*
- **Directrices de Propiedad Intelectual en `AGENTS.md`:** Reforzar las políticas de clean-room (el agente nunca debe importar código propietario descompilado, sino programar contra tests y contratos funcionales objetivos).

---

## 4. Próximos Pasos de Evaluación
- [ ] Determinar si se requiere una skill de análisis de AST / inspección de endpoints.
- [ ] Evaluar compatibilidad de servidores MCP de análisis estático con el `fleet-doctor.sh` y el Tooling Hub.
- [ ] Mantener como referencia de consulta para cuando surjan tareas de migración o ingeniería inversa de APIs.

---

## 5. Solapamiento verificado (inventory-check, 2026-10-21)

`bash scripts/agent/inventory-check.sh "MCP reverse engineering inspeccion AST binario"` — **no existe**
implementación previa de ingeniería inversa, análisis de binarios ni protocolo clean-room:

| Activo existente | Responsabilidad | Solape con esta idea |
| :--- | :--- | :--- |
| `.agents/config/fleet.example.yaml` (`mcpServers:`) | Inventario declarativo de servidores MCP (coolify, filesystem, github, fetch, memory) | **Punto de integración**, no solape: registrar REA sería una entrada más |
| `fleet-doctor.sh` | Diagnóstico determinista de flota y dependencias | Compatibilidad a evaluar (paso 4) |
| skill `tool-inventory` | Catálogo de herramientas activas de la flota | Consulta el inventario; no inspecciona binarios |
| skill `skill-inspector` | Auditoría estática de seguridad de skills (patrones SkillSpector) | Ninguno: audita `SKILL.md`, no artefactos externos |
| `scripts/agent/scout.sh` | Prospección OSS determinista (GitHub/npm/PyPI) | Ninguno: descubre, no inspecciona |
| `docs/architecture/tool-inventory.md` | Doc del inventario de herramientas | Ninguno |

**Nota de riesgo (a evaluar antes de cualquier implementación):** la parte 1 (introspección de
artefactos propios, APIs propias o librerías heredadas) es directamente aplicable. La parte de
recrear software de terceros a partir de binarios es una decisión **legal y de política**, no
técnica: si entra, debe entrar con las directrices clean-room escritas en `AGENTS.md` y con
revisión explícita, nunca como capacidad por defecto de un agente autónomo.
