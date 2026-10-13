# Task-101: Publicación remota de ramas de tarea

## Objetivo
Extender `promote-to-main.sh` con `--push-source`, `--merge-commit` y `--pr` para que publicar
una rama de tarea contra `main` sea una orden, no una secuencia manual de cuatro pasos que cada
sesión recuerda de memoria.

## Contexto técnico
- `scripts/agent/promote-to-main.sh` (243 líneas) ya localiza el worktree destino, valida árbol
  limpio, corre la suite y emite JSON. Cubre ~80% del caso: **no se crea un script nuevo**
  (firewall 2c, `## Descartado` del research).
- **Hueco 1 — la rama de tarea nunca llega a origin.** Existe `--push` (línea 52), pero empuja
  `TARGET` (`git push origin "$TARGET"`, línea 221). El diff que el revisor necesita no está en
  origin; hoy se resuelve a mano con `git push -u origin <rama>` al inicio de cada revisión.
- **Hueco 2 — el merge está cableado a fast-forward.** `--ff-only` aparece en el mensaje de
  error (línea 172) y en las dos ejecuciones reales (líneas 203 y 215), sin flag que lo relaje.
  Con T-100 ya mergeado con `--no-ff`, promover una rama con varios commits exige rebase previo
  o fallar.
- Flags actuales: `--source`, `--target`, `--push`, `--skip-tests`, `--json`, `--help`.
  La ayuda (línea 65) no menciona `--skip-tests`.
- Herramienta de PR: la CLI `gh`, ya verificada como dependencia por `fleet-doctor.sh`.
  No se introduce scraper ni SDK (research §5 y Scout T-101).
- `promote-to-main.sh` **no está** en `scripts/agent/assets-manifest.txt`, así que hoy no se
  distribuye a los proyectos hijos.
- T-100 (dependencia) está mergeada en `main` @ `632454e`: los scripts de cierre ya verifican
  antes de mover el ref y avisan de todo commit sin verificar. El patrón a reutilizar aquí es
  "no afirmar lo que no se ha comprobado".

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/promote-to-main.sh`
- `tests/validate-control-plane.sh`
- `changelog.md`
- `.agents/tasks/task-101.md` (este contrato; lo archiva `close-task.sh`)
- `docs/sprints/sprint-15-core.md` (estado de la fila T-101)

## Criterios de done
- [x] `--push-source` publica la rama de tarea en origin con tracking (`-u`), sin exigir rebase
- [x] `--merge-commit` permite integrar sin fast-forward; el `--ff-only` actual sigue siendo el
      valor por defecto
- [x] `--pr` crea el PR con `gh` y propaga su URL; si `gh` falta o no está autenticado, falla
      con mensaje accionable en vez de a medias
- [x] `--help` refleja todos los flags reales, incluidos los preexistentes que faltaban
- [x] Ninguna combinación de flags deja la rama publicada y el merge sin hacer, ni al revés
- [x] Verificación post-condición: el script comprueba que el push y el merge ocurrieron antes de
      reportar éxito (mismo patrón que `lib/verify-commit.sh`)
- [x] Check 20 en `tests/validate-control-plane.sh` con fixture en repo temporal
- [x] Suite completa sin regresiones (20/20)
- [ ] `git diff --name-only` ⊆ Caja
- [x] Plan presentado al usuario (Fase 3.5) — APROBADO CON CAMBIOS: rama/commit del contrato + `--help` documenta los 3 flags nuevos, la distinción `--push` (TARGET) vs `--push-source` (SOURCE) y `--skip-tests`
- [x] APROBADO recibido — fecha/hora: 2026-10-13T21:52:14+01:00
- [x] Rama creada: `feat/T-101-push-source-merge-commit-pr` (desde `main` @ `632454e`)
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente

## Defectos encontrados durante la implementación

Cuatro fallos reales, tres de ellos introducidos por mí en el camino. Se documentan porque el
valor de un check está en detectar, no en afirmar que todo fue bien a la primera:

1. **`--merge-commit` no hacía nada.** Parseaba el flag pero nunca propagaba el valor a
   `MERGE_MODE`, que se quedaba en `--ff-only`. El caso de prueba lo detectó: `merge_mode`
   seguía siendo `--ff-only` y no se creaba commit de merge.
2. **El modo `--json` estaba roto.** La salida de `git merge` y `git checkout` iba a stdout y
   contaminaba el JSON, impidiendo cualquier parseo. `log()` ya respetaba el modo JSON; los
   comandos git no.
3. **Mi arreglo del punto 2 rompió el script entero.** Puse `>&2` dentro de una variable
   (`GIT_OUT=">&2"`); bash no reparsea el resultado de una expansión como redirección, así que
   git recibía `>&2` como una ref a fusionar y abortaba. La redirección tiene que ir literal.
4. **Los fixtures del check 20 no probaban lo que decían.** Escribían los ficheros de captura
   dentro del repo del fixture, así que el working tree aparecía sucio y el script abortaba
   antes de ejecutar nada. Un test que no ejercita el código es peor que no tener test.

## Decisiones del usuario (Fase 3.5, 2026-10-13T21:52:14+01:00)
1. **Scout T-101 — la CLI `gh` queda ADOPTADA.** Confirmado explícitamente. No se introduce
   scraper ni SDK.
2. **Distribution**: `promote-to-main.sh` **NO** se añade a `scripts/agent/assets-manifest.txt`
   en esta tarea. Es una decisión de distribución separada.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5) — APROBADO CON CAMBIOS: rama/commit del contrato + `--help` documenta los 3 flags nuevos, la distinción `--push` (TARGET) vs `--push-source` (SOURCE) y `--skip-tests`
- [x] APROBADO recibido — fecha/hora: 2026-10-13T21:52:14+01:00
- [x] Rama creada: `feat/T-101-push-source-merge-commit-pr` (desde `main` @ `632454e`)
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente