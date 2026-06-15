---
description: Ritual de Onboarding y Adaptación Inicial. Ejecutar una única vez al introducir un repositorio legacy o nuevo al ecosistema de Agent OS.
---

# sprint-inicial

> Duración estimada: 15 min. Ejecutar obligatoriamente como primer paso antes de lanzar cualquier sesión o planificación de sprint en un repositorio nuevo o recién integrado.

## Objetivo

- Diagnosticar el repositorio actual para detectar incompatibilidades estructurales.
- Alinear el casing de archivos clave (`roadmap.md`, `changelog.md`).
- Agrupar commits históricos en un Sprint 00 de control de progreso y sincronizar hitos con `docs/implemented.md`.
- Generar el archivo de marca `.agents/context/onboarding-complete.md` que garantiza la idempotencia del proceso.

## Archivos y rutas a revisar

- `ROADMAP.md` / `roadmap.md`
- `CHANGELOG.md` / `changelog.md`
- `docs/MVP-TRACKER.md` / `docs/mvp-tracker.md`
- `docs/IMPLEMENTED.md` / `docs/implemented.md`
- `docs/sprints/`
- `.agents/context/onboarding-complete.md`

## Prerrequisitos

- Repositorio limpio (sin cambios locales sin commitear).
- Antigravity en modelo **Flash** (flujo de lectura y scripting de control).

---

## Protocolo

### 1. Comprobación de idempotencia

Antes de realizar cualquier acción, verificar si el onboarding ya fue completado:

```bash
ls .agents/context/onboarding-complete.md 2>/dev/null || echo "No completado"
```

*   **Si el archivo existe**: Detenerse de inmediato. Mostrar al usuario el mensaje:
    > "✅ El onboarding e inicialización de este repositorio ya fue completado previamente. Ejecuta directamente el flujo de `/sprint-planning` para planificar el siguiente sprint."
*   **Si el archivo NO existe**: Proceder al paso 2.

### 2. Detección de incompatibilidades (Solo Lectura)

Ejecutar la auditoría en modo diagnóstico:

```bash
bash scripts/agent/audit-repo.sh
```

El script creará el reporte preliminar en `docs/agent-os-audit.md`.

### 3. Revisión del reporte con el usuario

1. Leer el archivo `docs/agent-os-audit.md` generado.
2. Presentar una tabla resumida al usuario indicando:
    *   Archivos clave a renombrar (ej: `ROADMAP.md` → `roadmap.md`).
    *   Archivos de control a mover a `docs/` (ej: `mvp-tracker.md` → `docs/mvp-tracker.md`).
    *   Hitos y commits históricos detectados para agrupar en el Sprint 00.
3. **Pausar y esperar la aprobación explícita del usuario.**

> ⚠️ **IMPORTANTE**: Si el script detecta múltiples candidatos (ambigüedad) para algún archivo de control, solicita al usuario que edite `docs/agent-os-audit.md` para dejar solo el correcto antes de continuar.

### 4. Aplicación de adaptaciones

Una vez recibida la aprobación del usuario, verificar que no hay cambios sucios en el árbol de Git y ejecutar:

```bash
bash scripts/agent/audit-repo.sh --apply
```

El script ejecutará de forma automática:
- Los renombres y migraciones estructurales necesarios en Git.
- La creación de `docs/sprints/_archived/sprint-00-historical.md` en formato de tabla markdown completada (`T-00-XX` con `✅`).
- La actualización de `docs/implemented.md` con los hitos del Sprint 00.
- La creación del archivo de marca de trazabilidad `.agents/context/onboarding-complete.md`.
- Un commit automático: `chore(agent-os): apply audit adaptations to existing repo and mark onboarding complete`.

### 5. Verificación final del sistema

Ejecutar el script de control de sprint para comprobar que el entorno es 100% válido para operar:

```bash
bash scripts/agent/check-sprint.sh
```

*   **Resultado esperado**:
    *   Debe detectar con éxito `roadmap.md`.
    *   El sprint actual debe ser `ninguno`.
    *   El siguiente debe ser `sprint-01` en modo `INICIALIZACIÓN`.

### 6. Handoff a Sprint Planning

Presentar el resumen de la auditoría y concluir el flujo con el siguiente mensaje:

```
🎉 Onboarding y adaptación completados con éxito. 
💾 Se ha creado la marca de trazabilidad en `.agents/context/onboarding-complete.md`.

👉 Próximo paso: Ejecuta el flujo /sprint-planning para crear el Sprint 01 y comenzar el desarrollo normal.
```
