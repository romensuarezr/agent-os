# Task-091: Regla de destilación y automejora procedimental (Self-Improvement Distillation)

## Objetivo
Implementar la regla global de automejora procedimental e integrarla en el workflow de cierre de sesión (`session-close.md`) de Agent OS, formalizando un ciclo de aprendizaje continuo donde los procedimientos novedosos o gotchas descubiertos en ejecución se destilen en reglas, skills, runbooks o entradas de inbox vivos, aplicando un umbral 3x anti-ruido, captura en caliente, actualización sin crear silos muertos y promoción humana, asegurando y verificando empíricamente su herencia a todos los proyectos satélites vía `install.sh` y `sync.sh`.

## Contexto técnico
- **Sprint**: Sprint 14 ("Automejora y Confianza").
- **Research integrado (`docs/sprints/sprint-14-core-research.md`)**:
  - *Reflexion* (Shinn et al.): Retroalimentación verbal y formulación de borradores antes de aplicar cambios (*draft* → humano).
  - *Voyager* (MineDojo): Destilación acumulativa de habilidades en caliente (*live-capture*) durante la resolución exitosa.
  - *MemGPT/Letta*: *Sleeptime curation* (edición selectiva post-ejecución) y *access reinforcement* (consolidación selectiva de patrones recurrentes ≈ umbral 3x).
  - *Agent Foundry*: *Retrospective* sobre documentos vivos existentes (`core_memory_replace`), prohibiendo taxativamente crear ficheros o silos muertos de "lecciones aprendidas" que ningún agente lee en el onboarding.
  - *Gobernanza de flota y distribución*: Registro en `scripts/agent/assets-manifest.txt` para garantizar la distribución universal mediante `install.sh` y `sync.sh`.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/rules/global/self-improvement-distillation.md` (nuevo)
- `.agents/workflows/session-close.md`
- `scripts/agent/assets-manifest.txt`
- `.agents/tasks/task-091.md` (nuevo)
- `docs/sprints/sprint-14-core.md`

## Criterios de done
- [x] Regla global `.agents/rules/global/self-improvement-distillation.md` redactada con directrices de destilación, matriz de destino canónico (skill, regla, runbook, inbox o edición in-situ), umbral 3x anti-ruido, disciplina *retrospective* en documentos vivos y requisito de aprobación humana explícita.
- [x] Workflow `.agents/workflows/session-close.md` actualizado incorporando la fase de autoreflexión previa al cierre con las 3 preguntas clave (convención no documentada, gotcha técnico recurrente, procedimiento multi-paso reusable).
- [x] Cableado de distribución: `.agents/rules/global/self-improvement-distillation.md` registrado en `scripts/agent/assets-manifest.txt`.
- [x] Verificación empírica de herencia: prueba de instalación/sincronización en repositorio satélite efímero demostrando que la regla se despliega e instala intacta en el hijo.
- [x] Validación del control plane: `tests/validate-control-plane.sh` ejecutado con éxito (12/12 ✅).
- [x] Working tree limpio tras la ejecución.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-30 11:07:51+01:00
- [x] Rama creada: feat/T-091-self-improvement-distillation
- [x] Lock activo: 2026-09-30T11:10:00+01:00
- [x] Sesión cerrada correctamente
