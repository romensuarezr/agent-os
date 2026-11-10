# Executive Design Digest — T-180

## 🎯 Objetivo
Formalizar la integración de DeepWiki MCP como fuente secundaria y desacoplada de comprensión estructural profunda de repositorios públicos en la skill canónica `.agents/skills/tooling-advisor/SKILL.md`, estableciendo guardarraíles estrictos de seguridad y contraste obligatorio contra el árbol real (HEAD).

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico de T-180 se adhiere con un 100% de fidelidad al diseño macro sellado en task-180.md y el sprint planning. La delimitación estricta de la caja de archivos (.agents/skills/tooling-advisor/SKILL.md, .agents/config/fleet.example.yaml, .agents/tasks/task-180.md) garantiza la no dispersión del cambio.

Se incorporan de manera integral los tres guardarraíles vinculantes: seguridad fail-closed restringida a repositorios públicos, principio de verdad arquitectónica subordinando DeepWiki como fuente secundaria contrastada contra HEAD, y el axioma de cero auto-ejecución canalizado mediante docs/idea-inbox/. La preservación del umbral 38/38 en validate-control-plane.sh asegura estabilidad absoluta en el plano de control.
- **Prospección Scout**: `CONFORME (sprint-32-research.md)`
  - Alternativa detectada:** Servidor oficial DeepWiki MCP (`https://mcp.deepwiki.com/mcp`), paquetes de la comunidad (`regenrek/deepwiki-mcp` 1,390★ MIT, `@physihan/deepwiki-mcp`), captura en `docs/idea-inbox/2026-11-09-deepwiki-complemento-scout.md`.
  - Recomendación del agente:** Integrar DeepWiki como fuente de comprensión profunda estructural para repositorios públicos tras la fase determinista de `scout.sh`, con guardarraíl inviolable: DeepWiki consulta una wiki generada y no el HEAD vivo; toda conclusión debe contrastarse contra el árbol real del repo antes de generar un plan o propuesta.
  - Dictamen del Operador:** Aprobada. Absorbe integralmente la propuesta del inbox `2026-11-09-deepwiki-complemento-scout.md`.
  - Notas de integración:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-180-deepwiki-post-scout-tooling-advisor' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/skills/tooling-advisor/SKILL.md`
- `.agents/tasks/_archived/task-180.md`
- `docs/sprints/sprint-32-core.md`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
