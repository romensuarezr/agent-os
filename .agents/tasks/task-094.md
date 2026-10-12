# Task-094: Unificación de firma CLI con soporte `--path` en `audit-repo.sh`

## Objetivo
Dar a `audit-repo.sh` el mismo contrato `--path <dir>` que ya tienen `audit-child.sh` y `setup-profiles.sh`, y crear el registro de flujos críticos que `session-start.md` exige pero que el repositorio no tiene.

## Contexto técnico
`audit-repo.sh` es hoy el único script de auditoría sin `--path`: asume el directorio de trabajo actual (30 KB de script, cero ocurrencias del flag). Sus dos hermanos ya lo soportan, con la misma semántica: valor por defecto = directorio actual, argumento obligatorio que se valida y se reporta en error. La asimetría obliga a hacer `cd` o a invocar con `workdir`, y rompe cualquier orquestador que ejecute en modo batch.

Contrato a replicar (idempotente, como el de `audit-child.sh`):

```
--path <dir>   Ruta al repositorio a auditar (por defecto: directorio actual).
```

Requisito adicional del sprint: `--path` debe ser **idempotente y coherente** con `audit-child.sh` y `setup-profiles.sh` en validación de argumentos, mensaje de error y valor por defecto.

**Deuda heredada de T-098**: la regla `flow-bug-traceability` de `session-start.md` obliga a consultar y actualizar `docs/critical-flows.md` antes de cerrar cualquier tarea que corrija un bug en producción o toque permisos/listeners. Ese archivo **no existe**. Debe crearse con la estructura mínima útil y poblarse con, al menos, el caso detectado en T-098: un proxy inverso que apunta a `127.0.0.1` cuando el servicio solo escucha en la IP de Tailscale (502 permanente con healthcheck verde).

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/audit-repo.sh`
- `docs/critical-flows.md`
- `changelog.md`
- `.agents/tasks/task-094.md`

## Criterios de done
- [ ] `bash scripts/agent/audit-repo.sh --path <repo>` audita el repo indicado y no el directorio actual.
- [ ] `bash scripts/agent/audit-repo.sh` sin flags conserva el comportamiento actual (directorio actual).
- [ ] `--path` sin argumento falla con mensaje de uso y código de error coherente con `audit-child.sh` y `setup-profiles.sh`.
- [ ] Ejecutar dos veces consecutivas sobre el mismo `--path` produce el mismo resultado (idempotencia).
- [ ] `docs/critical-flows.md` existe con estructura de tabla de flujos, estado de cobertura (⬜/🟡/✅) y al menos el caso de T-098 registrado.
- [ ] `bash tests/validate-control-plane.sh` sin regresiones.
- [ ] `--help` de `audit-repo.sh` documenta `--path`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente