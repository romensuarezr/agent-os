# Executive Design Digest — T-151

## 🎯 Objetivo
Ejecutar un ensayo empírico no destructivo de observabilidad para evaluar el estado real del worker de inferencia (`Orca ADE`) al producirse un timeout en la deliberación, determinando si el proceso permanece vivo+avanzando, vivo+atascado o muerto, y si el veredicto estructurado llega dentro de una ventana de extensión de gracia (+30 a +60s) o nunca. Emitir un informe de diagnóstico con veredicto concluyente (`LIVENESS_VIABLE` o `LIVENESS_DESCARTADO`) sin alterar el veredicto `SIN_REVISOR` ni la compuerta humana del relé.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor no disponible (timeout o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Prospección Scout**: `CONFORME (sprint-27-research.md)`
  - Alternativa detectada:** `jest-worker` (v30.5.1, NPM), `@deepseek-ai/dsh-subprocess-local` (v0.0.1-rc.1, NPM).
  - Recomendación del agente:** Desarrollo a medida justificado (sonda determinista en Bash nativo).
  - Decisión del usuario:** Desarrollo a medida justificado — se trata de un ensayo empírico previo a cualquier cableado estructural para diagnosticar el estado del worker de inferencia (`Orca ADE`) al alcanzar el timeout (vivo+avanzando, vivo+atascado o muerto) y determinar si el veredicto llega dentro de una ventana de extensión de gracia (+30 a +60s) o nunca. No altera el veredicto `SIN_REVISOR` ni la compuerta humana; emite diagnóstico estructurado para decidir si liveness requiere componente dedicado o se descarta.
  - Notas de integración:**
- **Mensaje de Cierre**: `merge: feat/T-151-worker-liveness-trial into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-151.md`
- `docs/sprints/sprint-27-core.md`
- `docs/sprints/sprint-27-liveness-trial-report.md`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `testing-flows`
