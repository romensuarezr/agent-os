# Executive Design Digest — T-182

## 🎯 Objetivo
Ejecutar la rotación programada y formal de credenciales de FreeLLMAPI en la pasarela de inferencia de Hermes (Opción B acordada tras la remediación provisional del incidente 401), implementando un procedimiento determinista basado estrictamente en scripts, sin imprimir valores de secretos en pantalla ni logs, y supeditado a una compuerta HITL con confirmación humana explícita previa al reinicio del servicio.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-182 resuelve con precisión y determinismo la sincronización y rotación de FreeLLMAPI en Hermes Agent. La arquitectura del script (`--check`, `--rotate`, `--sync`) preserva el principio de secreto cero mediante pipes seguros en memoria, permisos 0600, respaldo atómico y enmascaramiento estricto de salidas.

La compuerta HITL previa al reinicio de `hermes-gateway.service` mitiga eficazmente el riesgo de degradación de mensajería para el operador, mientras que los pasos de verificación empírica (`hermes ping`, inferencia sintética y suite de control plane) garantizan un cierre limpio y sin regresiones dentro de la caja de archivos autorizada.
- **Prospección Scout**: `CONFORME (sprint-32-research.md)`
  - Alternativa detectada:** Incidente documentado en `docs/runbooks/incident-hermes-401-remediation.md` (reversión provisional a OmniRoute tras error 401 en FreeLLMAPI); base de datos SQLite `freeapi.db` y variables en `~/.hermes/.env` en el host de inferencia.
  - Recomendación del agente:** Ejecutar formalmente la Opción B: rotación controlada de la API key de FreeLLMAPI en la base de datos de FreeLLMAPI y configuración de Hermes, verificación de inferencia y reactivación sin interrupción del servicio de mensajería.
  - Dictamen del Operador:** Aprobada con condición estricta: **la rotación debe realizarse exclusivamente con maquinaria de scripts, sin imprimir valores de secretos en pantalla ni logs, y con compuerta HITL del operador (solicitud de ventana + confirmación OK del operador antes de aplicar cambios destructivos o reiniciar servicios)**.
  - Notas de integración:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-182-rotacion-freellmapi-hermes-hitl' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-182.md`
- `docs/runbooks/incident-hermes-401-remediation.md`
- `docs/sprints/sprint-32-core.md`
- `scripts/agent/lib/rotate-freellmapi-token.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
