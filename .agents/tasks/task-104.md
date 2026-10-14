# Task-104: Despacho multi-repo del core portable

## Objetivo
Que el core pueda lanzar una tarea en **otro repositorio** de forma determinista, eligiendo ruta
Orca cuando hay runtime y ruta Git-nativa cuando no, sin que la ausencia de Orca sea un fallo.

## Contexto técnico

### El problema que resuelve
Hoy `worktree-dispatch.sh` trabaja sobre el repositorio en el que se ejecuta. El core sabe aislar
agentes en worktrees, pero **no sabe salir del repo propio**: no hay forma de decir "despacha esta
tarea al repo X". La operación se hace hoy a mano, worktree por worktree.

### El diseño: dos rutas en el mismo plano

El precedente ya existe dentro del core y no se puede ignorar: `orca-orchestrate.sh:33` hace
`command -v orca` y **aborta** si no encuentra el CLI. Esa comprobación es la causa del fallo
reportado en VMs limpias desde el Sprint 12. Orca **no es auto-instalable**: `orca` es un shim que
ejecuta `/opt/Orca/resources/bin/orca-ide`, y no hay `orca install` ni descarga en el CLI.

```
¿hay runtime Orca alcanzable?
├── sí → orca orchestration worker-start --repo <selector> --worktree new-child
│         --task <id> --agent <id>
└── no → git worktree add   (lo que worktree-dispatch.sh ya hace hoy)
```

Ambas rutas producen **la misma forma de resultado** (worktree creado + arnés inyectado + tarea
registrada), de modo que el consumidor no necesita saber cuál se usó. Esa uniformidad es el
criterio de diseño, no un detalle: es lo que permite que el fallback sea de primera clase.

### Selectores de repo (verificados contra el runtime)
`worker-start --repo` acepta `id:<id>`, `name:<name>` o `path:<path>`. Y `--worktree` acepta
`identity:<id>`, `id:<repo-id>::<path>`, `new-child`, `new-top-level`. Con evidencia:
`orca repo list` devuelve 9 repos y `orca worktree ps` worktrees vivos en 3 de ellos.

### Qué NO se toca
- **No se construye panel de estado.** El estado emerge del dispatcher: sabe qué despachó porque
  él mismo lo hizo. Pedir un dashboard aquí sería duplicar el dato que ya posee quien despacha.
- **No se asume que haya Orca.** Ninguna ruta puede abortar por su ausencia.

## Caja de archivos
- `scripts/agent/dispatch-satellite.sh` (nuevo — dispatcher dual)
- `.agents/config/satellites.yaml` (nuevo — declaración de satélites)
- `scripts/agent/worktree-dispatch.sh` (extender, no reescribir: aporta la ruta Git-nativa)
- `scripts/agent/assets-manifest.txt` (registrar los ficheros nuevos)
- `tests/validate-control-plane.sh` (check N+1)
- `changelog.md`
- `.agents/tasks/task-104.md` (este contrato)
- `docs/sprints/sprint-17-core.md`

## Criterios de done
- [ ] `satellites.yaml` declara los satélites (alias → ruta), sin literales de infraestructura
- [ ] El dispatcher **detecta** el runtime y elige ruta; ambas producen el mismo contrato de salida
- [ ] Sin runtime: la ruta Git-nativa funciona y NO es un mensaje de error
- [ ] Con runtime: invoca `worker-start` con los flags correctos (verificados contra `--help`)
- [ ] El dispatcher **registra** lo que despachó (origen, destino, tarea, ruta usada, timestamp)
- [ ] Idempotencia: re-despachar la misma tarea no crea un segundo worktree
- [ ] Ninguna ruta aborta por ausencia de Orca
- [ ] Check N+1 con fixture en repos temporales: una sola prueba con runtime simulado y otra sin él
- [ ] `satellites.yaml` no introduce literales prohibidos (check 22 lo cubre)
- [ ] Suite completa sin regresiones
- [ ] `git diff --name-only` ⊆ Caja
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente