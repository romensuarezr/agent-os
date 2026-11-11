# Task-197: Auditoría determinista de tokenomics en skills

## Objetivo
Extender `scripts/agent/inspect-skills.sh` con un flag `--context` que mida líneas y peso estimado de tokens por `SKILL.md` y detecte skills huérfanas no referenciadas en workflows ni perfiles, para visibilizar el coste de memoria del catálogo.

## Contexto técnico
- `scripts/agent/inspect-skills.sh` (24.6KB) ya escanea estáticamente skills detectando inyección, exfiltración, código peligroso, abuso MCP e higiene de frontmatter, con gate bloqueante CRITICAL/HIGH y flags `--path`, `--baseline`, `--json`, `--human`, `--help`.
- Hoy no existe métrica de peso en tokens ni detección de skills huérfanas (verificado en `--help` vigente: sin flag `--context`).
- Referencias: `.agents/context/skills-inventory.md` (catálogo), `.agents/workflows/` y `.agents/profiles/` (fuentes de referencia para huérfanas).

### Research integrado (`## Descubrimientos Scout` → `### T-197`)
- **Consulta scout**: `token context weight audit orphan skills manifest lines tokens`.
- **Alternativas detectadas**: paquetes npm ajenos al problema (`js-tokens`, `parse-statements`, `@sanity-labs/design-tokens`) — sin aplicabilidad.
- **Recomendación**: `Desarrollo a medida justificado` — extensión determinista de `scripts/agent/inspect-skills.sh` (señal⚠️ leído en firewall, no recreado); se reutiliza la base de inspección estática existente.
- **Investigación web externa**: no requerida (tarea de alcance puramente interno/core; bypass declarado en `docs/sprints/sprint-36-research.md`).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 36 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Flag añadido de forma retrocompatible: el uso sin flags conserva el comportamiento y salida actuales (gate CRITICAL/HIGH intacto).
  - `--context` emite por fichero: ruta, líneas, peso estimado de tokens (`líneas × factor determinista`, sin tokenizador externo) y marca de huérfana si el nombre no aparece en `.agents/workflows/` ni `.agents/profiles/`.
  - `--context` es combinable con `--json` (salida estructurada) y `--help` documenta el flag con ejemplo.
  - Coste $0: cero red, cero dependencias nuevas, cero Python externo (bash/awk puro, portable Linux/macOS).
  - Si se amplía `tests/validate-control-plane.sh`, el denominador crece limpiamente sin romper checks existentes.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/inspect-skills.sh`
- `.agents/skills/skill-inspector/SKILL.md` (documentación del nuevo flag)
- `tests/validate-control-plane.sh` (solo si se añade cobertura del flag)

## Criterios de done
- [ ] `--help` documenta `--context` con ejemplo de uso.
- [ ] `bash scripts/agent/inspect-skills.sh --context` lista todas las skills con líneas/tokens y detecta huérfanas.
- [ ] `--context --json` emite JSON válido.
- [ ] Ejecución sin flags idéntica al comportamiento previo (sin regresiones del gate).
- [ ] Suite `tests/validate-control-plane.sh` en verde (38/38 o ampliación limpia).

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
