# Task-082: Coherencia de Gobernanza, Resolución de Contradicciones y Precedencia de Perfiles

## Objetivo
Resolver contradicciones de gobernanza en reglas globales, documentar formalmente la precedencia de esquemas de perfil (.yaml vs .md) en `.agents/profiles/README.md`, unificar referencias cruzadas pre-push y operaciones destructivas, añadir mapa de fases de auditoría y fricción .env en `AGENT_ONBOARDING.md`, y renombrar `changelog.md` a `changelog-workflow.md` para evitar colisión case-insensitive con el archivo `changelog.md` de la raíz del proyecto.

## Contexto técnico
La auditoría del Sprint 11 identificó inconsistencias normativas y de gobernanza:
- **RUL-S3**: Coexistencia de dos esquemas de perfil (`.yaml` para control plane y `.md` para agentes autónomos) sin regla canónica de precedencia. Debe crearse `.agents/profiles/README.md` y enlazarse desde el `README.md` de la raíz.
- **RUL-C4**: Contradicción entre `maximum-autonomy.md` ("instálala tú") y `developer.yaml` ("prohibido instalar dependencias globales sin validación previa"). Se define el umbral: dependencias locales del workspace son autónomas; binarios/paquetes globales del SO requieren validación.
- **RUL-C5**: `response-checklist.md` omitía el nivel "Flota" en la jerarquía de herramientas (`Flota > OSS > Free > Premium`).
- **RUL-S1**: `no-destructive-without-audit.md` duplicaba las restricciones de `agent-permissions.md` sin cita cruzada.
- **RUL-S5**: Duplicación de "No trabajar en main" en `response-checklist.md` y `strict-workflow.md`.
- **RUL-S6**: Verificación pre-push duplicada entre `deployment-safety.md` y `strict-workflow.md`.
- **Decisión 3B / RUL-A11**: `ops-auditor.yaml` asume Linux + Docker; debe declarar scope explícito ("Linux/Docker").
- **Decisión 4B / RUL-S7**: Dispersión de la función de auditoría en 4 reglas. Se añade mapa de fases en `AGENT_ONBOARDING.md`.
- **Decisión 5B / K-H-12**: Fricción explícita para `.env` en onboarding, delegando centralizadamente en Infisical.
- **Decisión 6A / K-BAJA-4**: Colisión case-insensitive entre el archivo `changelog.md` de la raíz y `.agents/workflows/changelog.md` en sistemas de archivos case-insensitive. Se renombra a `changelog-workflow.md` y se actualiza `scripts/agent/assets-manifest.txt`.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/profiles/README.md`
- `README.md`
- `.agents/profiles/ops-auditor.yaml`
- `.agents/profiles/developer.yaml`
- `.agents/rules/global/maximum-autonomy.md`
- `.agents/rules/global/response-checklist.md`
- `.agents/rules/global/no-destructive-without-audit.md`
- `.agents/rules/global/strict-workflow.md`
- `.agents/rules/global/deployment-safety.md`
- `.agents/AGENT_ONBOARDING.md`
- `.agents/workflows/changelog.md` (renombrado a `changelog-workflow.md`)
- `.agents/workflows/changelog-workflow.md`
- `scripts/agent/assets-manifest.txt`
- `docs/sprints/sprint-12-core.md`
- `.agents/tasks/task-082.md`

## Criterios de done
- [x] `.agents/profiles/README.md`: creado documentando la precedencia `.yaml` vs `.md` y enlazado desde el `README.md` de la raíz.
- [x] `ops-auditor.yaml`: scope explícito declarado (`scope: "Linux/Docker"`).
- [x] `developer.yaml` y `maximum-autonomy.md`: umbral de validación previa unificado (dependencias locales del workspace permitidas; CLIs/paquetes globales requieren aprobación).
- [x] `response-checklist.md`: jerarquía Flota > OSS > Free > Premium alineada con `tool-decision-flow.md`.
- [x] `response-checklist.md` y `strict-workflow.md`: regla "no trabajar en main" unificada con referencia canónica sin duplicación.
- [x] `no-destructive-without-audit.md`: referencia canónica a `agent-permissions.md` (L3).
- [x] `strict-workflow.md` y `deployment-safety.md`: checklist pre-push consolidado con referencia canónica.
- [x] `AGENT_ONBOARDING.md`: mapa de fases de auditoría añadido para las 4 reglas (`audit-before-refactor`, `dry-architecture`, `tool-decision-flow`, `analysis-principles`).
- [x] `AGENT_ONBOARDING.md`: fricción explícita de `.env` documentada delegando en Infisical.
- [x] Renombrado `changelog.md` → `changelog-workflow.md` vía `git mv` y actualizado en `assets-manifest.txt`.
- [x] `tests/validate-control-plane.sh` pasa 12/12 sin regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T21:27:27+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-082-gobernanza-perfiles
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
