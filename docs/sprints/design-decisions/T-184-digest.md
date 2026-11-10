# Executive Design Digest — T-184

## 🎯 Objetivo
Crear la herramienta determinista `scripts/agent/audit-satellites.sh` para auditar la integridad, permisos y desvíos de los scripts del core en repositorios satélite registrados en `.agents/config/satellites.yaml` (o pasados por argumento), operando en modo solo lectura a coste cero de tokens.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan de trabajo para T-184 respeta al 100% las especificaciones selladas en el diseño macro aprobado de task-184.md. La caja de archivos autorizados está estrictamente acotada a los cuatro ficheros previstos (audit-satellites.sh, validate-control-plane.sh, AGENTS.md y task-184.md), sin fugas de scope ni alteraciones de dependencias globales.

La arquitectura del script es determinista ($0 tokens, <100ms, solo lectura), contempla degradación graceful ante satélites no encontrados y asegura que la integración en tests/validate-control-plane.sh (Check 9) preserve el invariante del denominador 38/38 de la suite de control plane sin introducir regresiones ni acoplamiento destructivo.
- **Prospección Scout**: `CONFORME (sprint-33-research.md)`
  - Alternativa detectada:** Herramientas genéricas como `audit-ci`, `codeowners-audit` o utilidades git.
  - Recomendación del agente:** Desarrollo a medida 100% justificado en Bash determinista. Las herramientas del ecosistema no comprenden la arquitectura de Agent OS (`.agents/`, contratos, scripts globales sincronizados vía `sync.sh` ni ledgers `last-sync.md`). Crear `scripts/agent/audit-satellites.sh` que inspeccione los satélites declarados en `.agents/config/satellites.yaml` (o argumentos CLI), valide hashes de scripts del core vs satélite, compruebe permisos de ejecución y detecte desvíos locales sin tocar git y sin red.
  - Dictamen del Operador:** [Pendiente de ratificación en planning].
  - Notas de integración:**
- **Mensaje de Cierre**: `merge(feat/T-184): integración de audit-satellites.sh (T-184)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-184.md`
- `AGENTS.md`
- `docs/sprints/sprint-33-core.md`
- `scripts/agent/audit-satellites.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
