# Executive Design Digest — T-183

## 🎯 Objetivo
Estandarizar el script `scripts/ops/coolify.sh` y la skill `.agents/skills/coolify-admin/SKILL.md` para integrar la ayuda estándar determinista (`scripts/agent/lib/cli-help.sh`), eliminar literales de ejemplo hardcodeados (`coolify.example.com`), y habilitar la resolución de endpoints desde `.agents/config/fleet.yaml` con precedencia estricta sobre variables de entorno (`COOLIFY_BASE_URL` e Infisical).

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico evaluado se adecua con total fidelidad a las decisiones selladas en el diseño macro aprobado de `task-183.md`. La eliminación del fallback estático (`coolify.example.com`) a favor de una resolución jerárquica (entorno -> bloque PaaS en `fleet.yaml` -> fail-closed determinista) elimina riesgos de fuga o llamadas a endpoints inválidos, preservando la inyección efímera de credenciales.

La delimitación de la caja de archivos es exacta, la integración de `cli-help.sh` asegura uniformidad con el estándar de scripts del core, y la estrategia de mitigación preserva la retrocompatibilidad en las firmas de subcomandos sin alterar el denominador inmutable de control plane (38/38).
- **Prospección Scout**: `CONFORME (sprint-33-research.md)`
  - Alternativa detectada:** Repositorio oficial `coollabsio/coolify-cli` (497★ | MIT), paquetes npm `coolify-axi` y wrapper actual `scripts/ops/coolify.sh`.
  - Recomendación del agente:** Mantener el script wrapper bash determinista propio (`scripts/ops/coolify.sh`) a coste $0 de tokens sin introducir dependencias binarias pesadas externas. Estandarizar la resolución de endpoints con fallback dinámico a `fleet.yaml` (nodo de orquestación / PaaS) y variables de entorno (`COOLIFY_BASE_URL` / `COOLIFY_TOKEN`), integrar `scripts/agent/lib/cli-help.sh` y pre-flights conformes a la frontera portable.
  - Dictamen del Operador:** [Pendiente de ratificación en planning].
  - Notas de integración:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-183-estandarizacion-coolify-ops-fleet' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/skills/coolify-admin/SKILL.md`
- `.agents/tasks/_archived/task-183.md`
- `docs/sprints/sprint-33-core.md`
- `scripts/ops/coolify.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
