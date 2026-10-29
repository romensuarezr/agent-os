# Task-131: Ensayo End-to-End del Bucle Multi-Agente con Check 36 en Validate Control Plane

## Objetivo
Implementar el **Check 36** en la suite canónica `tests/validate-control-plane.sh`, actualizando el denominador de `[X/35]` a `[X/36]` en todas sus ocurrencias, y certificando de forma determinista y sin red el ciclo de vida completo de un trabajo multi-agente: despacho a worktree efímero, deliberación aislada, rescate de artefactos de deliberación en merge (T-128), auditoría scout en planning (T-129) y cascada de inferencia (T-130).

## Contexto técnico
El sistema ha acumulado primitivas potentes e independientes a lo largo de los sprints 20, 21 y 22:
- Aprovisionamiento y aislamiento en worktree hermano (`worktree-dispatch.sh`).
- Motor de deliberación determinista `$0` (`deliberate-plan.sh`).
- Preservación y rescate de la deliberación gitignored hacia el tronco (`worktree-merge.sh`).
- Integración y purga segura sin tocar árboles sucios (`worktree-gc.sh`).
- Cierre formal y generación del Executive Design Digest (`close-task.sh`).
- Enforcement de investigación scout (`sprint-planning.md` / `design-digest.sh`).
Esta tarea implementa el **Check 36** como ensayo end-to-end automatizado:
1. Simula el despacho completo de una tarea en un fixture temporal de repositorio.
2. Comprueba que el rescate del artefacto de deliberación durante `worktree-merge.sh` permite a `close-task.sh` emitir un digest histórico con el veredicto real del worker sin degradar a `N/A`.
3. Comprueba las compuertas de scout de T-129 y cascada de T-130.
4. Purga completamente todos los fixtures temporales y garantiza que el working tree e índice queden 100% limpios.
5. Actualiza el denominador de la suite de 35 a 36 en todo el script.

## Skills relevantes
- `testing-flows`: Diseño de suites y arneses de integración end-to-end para agentes.
- `agent-os-scripts`: Convenciones CLI, estándares de pruebas en bash y portabilidad POSIX.
- `orchestrator`: Gobernanza del ciclo de vida multi-agente en Git Worktrees.

## Caja de archivos
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-131.md`

## Criterios de done
- [ ] Ocurrencias del denominador actualizadas de `[X/35]` a `[X/36]` en todo el script.
- [ ] Check 36 implementado verificando el ciclo completo (despacho, deliberación, rescate en merge, digest no degradado en cierre).
- [ ] Suite completa ejecutando 36/36 comprobaciones exitosamente sin regresiones (0 errores).
- [ ] Limpieza total del árbol e índice tras la ejecución del test.
