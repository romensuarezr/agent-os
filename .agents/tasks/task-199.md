# Task-199: Sandboxing no-root y auditoría defensiva de satélites

## Objetivo
Crear la regla global de sandboxing no-root (daemons, agentes y contenedores sin privilegios `root`) y la skill `security-audit` con escáner estático determinista de autorización de rutas, firma JWT e IDOR para satélites.

## Contexto técnico
- `.agents/rules/global/agent-permissions.md` define niveles L1/L2/L3 pero no verifica que los daemons corran sin `root`.
- No existen `.agents/rules/global/agent-sandbox.md` ni `.agents/skills/security-audit/` (verificado: cero coincidencias por nombre en inventory-check).
- El escáner debe ser estático, determinista y de coste $0 (bash/ripgrep sobre código del satélite), sin ejecución de red ni dependencias de pago.
- Referencias de patrón (hallazgos SearXNG, no dependencias): endpoints con parámetros de identidad sin validación de propiedad (IDOR), JWT con `alg: none` o sin verificación de firma, rutas sin middleware de autorización.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 36 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - `.agents/rules/global/agent-sandbox.md`: verificación no-root con comandos deterministas portables (`id -u`, `ps`, `docker inspect -f '{{.Config.User}}'`), sin asumir stack ni SO único.
  - `.agents/skills/security-audit/SKILL.md`: escáner estático de 3 familias de patrones (autorización de rutas, firma JWT, IDOR) que emite digest con severidad y ubicación archivo:línea; cero red, cero dependencias npm nuevas; no ejecuta exploits ni testers dinámicos.
  - Registro obligatorio de la skill en `.agents/context/skills-inventory.md` siguiendo la tabla existente.
  - Scout-First: `saas-security-audit` (npm) y demás hallazgos descartados por alcance/madurez insuficientes → desarrollo a medida justificado (registrado en research).
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/rules/global/agent-sandbox.md` (nuevo)
- `.agents/skills/security-audit/SKILL.md` (nuevo)
- `.agents/context/skills-inventory.md` (registro de la skill)

## Criterios de done
- [ ] Regla `agent-sandbox.md` creada con comandos de verificación no-root portables y sin literales de infraestructura.
- [ ] Skill `security-audit/SKILL.md` creada con los 3 familias de patrones, formato de salida y triggers.
- [ ] Skill registrada en `.agents/context/skills-inventory.md`.
- [ ] Cero dependencias nuevas; cero ejecución de red.
- [ ] Suite `tests/validate-control-plane.sh` en verde sin regresiones.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `[CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR]`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
