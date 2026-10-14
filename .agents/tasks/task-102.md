# Task-102: Mapa global de flujos de Agent OS con niveles C4

## Objetivo
Producir un mapa de flujos de Agent OS **generado y versionado**, en dos vistas: una humana
(diagrama que GitHub renderiza sin build ni binario) y un digest plano para agentes, con coste de
tokens acotado.

La restricción que manda sobre el diseño: **no crear una quinta fuente de verdad sobre flujos.**
El mapa se genera *desde* una fuente existente, no la acompaña.

## Contexto técnico

### Ya existe — y se solapa con lo que T-102 pide (hallazgo de planning)

| Artefacto | Tamaño | Naturaleza | Relación con T-102 |
|---|---|---|---|
| `docs/critical-flows.md` | 63 líneas | Manual. Registro de flujos cuyo fallo rompe el trabajo en silencio. 1 flujo, cobertura 🟡, última tarea T-098 | **La fuente más cercana.** La exige la regla `flow-bug-traceability` de `session-start.md` |
| `docs/architecture/control-plane-topology.md` | 116 líneas | Manual. Diagrama general + inventario de nodos + flujos de trabajo | Ya es "la topología", pero escrita a mano y desactualizable. **Versionado en git desde `8b335c1`** (verificado en `HEAD`, `origin/main`, `origin/multi-agent` y `feat/sprint-11-core-planning`; no está en `.gitignore`) |
| `AGENTS.md` §Flujo de datos (L84-92) | 9 líneas | Diagrama ASCII `core ──sync.sh──▶ hijo` / `contribute.sh ──▶ core` | El mapa de flujos del core ya está esbozado ahí |
| `scripts/agent/generate-digest.sh` | — | Genera un digest LLM-friendly **de una subcarpeta**, un fichero por ejecución, nombre `[project]_YYYYMMDD_<rama>_<sha7>_<slug>.txt` | Precedente más cercano del "digest para agentes", pero otro contrato: efímero y por subcarpeta, no un artefacto versionado y estable |

Los tres primeros están escritos a mano y ninguno se genera: ese es exactamente el fallo de
documentación que este core yaPagó en T-100 y T-101 (afirmar algo sin comprobar que se sostiene).

### C4 no tiene definición en este core
C4 (Context / Containers / Components / Code) modela aplicaciones con servicios y dependencias.
Agent OS es un core bash con scripts, worktrees y assets. **Los niveles no están definidos**: si no
se define qué es un "contenedor" aquí, la columna C4 es decoración con nombre technique.

### Conflicto de política observado — VERIFICADO, es real
`critical-flows.md` abre con un `[!IMPORTANT]` que prohíbe literales de infraestructura (IPs,
dominios, hostnames, rutas personales). `docs/architecture/control-plane-topology.md`, **versionado
en git**, contiene cuatro hostnames reales: `<host-local>`, `<nodo-inferencia>`, `<nodo-web>`,
`<nodo-datos>`. Es decir, el repositorio incumple hoy su propia política.

**Consecuencia directa para T-102**: `generate-flow-map.sh` **no debe leer
`control-plane-topology.md` en ningún caso**, ni para deduplicar ni para contexto. La única fuente
es `critical-flows.md`. El incumplimiento se anota como **deuda observada en `roadmap.md`** y NO se
arranca en esta tarea (queda fuera de la Caja).

### Scout (research, §"Descubrimientos Scout T-102")
- **Descartadas**: `structurizr/structurizr` (458⭐, Apache-2.0) — estándar de facto para C4, pero
  Java/Kotlin y arranca desde cero; `mingrammer/diagrams` (42.7k⭐, MIT) — orientado a infra cloud,
  no a flujos de proceso; D2 (binario Go, MPL-2.0, pre-1.0) — GitHub no lo renderiza.
- **Recomendación**: generador propio + **Mermaid** para el render, porque GitHub lo renderiza
  nativo y el diagrama viaja dentro del propio `.md` sin build ni binario.
- El modelo debe ser **texto plano** y el renderizado **opcional**, para no atar el mapa a la
  sintaxis de una herramienta.
- **Decisión del usuario: pendiente de confirmar.**

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/generate-flow-map.sh` (nuevo — generador determinista)
- `docs/critical-flows.md` (extender: niveles y modelo de datos, sigue siendo la fuente)
- `docs/flow-map.md` (nuevo — salida humana, Mermaid embebido)
- `docs/flow-map.digest.md` (nuevo — salida para agentes, plana y acotada)
- `tests/validate-control-plane.sh` (check 21: las salidas están sincronizadas con la fuente)
- `changelog.md`
- `.agents/tasks/task-102.md` (este contrato)
- `docs/sprints/sprint-15-core.md`
- `roadmap.md` (anotar la deuda observada de literales de infraestructura; decisión del usuario)

## Criterios de done
- [ ] Una única fuente de verdad: el mapa se genera desde `critical-flows.md`, no la duplica
- [ ] `generate-flow-map.sh` es determinista: misma entrada → misma salida, byte a byte
- [ ] El mapa nombra explícitamente qué es un "nivel C4" en este core, o renombra los niveles
- [ ] Salida humana renderizable por GitHub sin build ni binario
- [ ] Digest para agentes acotado en líneas y sin literales de infraestructura
- [ ] Check 21: regenerar sin cambios no produce diff (detecta salida obsoleta)
- [ ] Suite completa sin regresiones (21/21)
- [ ] `git diff --name-only` ⊆ Caja
- [x] Plan presentado al usuario (Fase 3.5) — APROBADO CON CAMBIOS: recuento 3 con evidencia, decisión 4 reforzada, deuda al roadmap, task file como primer commit, suite 21/21
- [x] APROBADO recibido — fecha/hora: 2026-10-13T22:31:07+01:00
- [x] Rama creada: `feat/T-102-mapa-flujos-c4` (desde `main` @ `58fe67e`)
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente

## Decisiones del usuario (Fase 3.5, 2026-10-13) — todas resueltas
1. **Scout T-102 — generador propio + Mermaid**: RESUELTO — confirmado.
2. **Fuente de verdad**: RESUELTO — fuente única `critical-flows.md`.
3. **Niveles C4 CON nombres C4 y definiciones adaptadas explícitas en la fuente**: L1 Sistema,
   L2 Contenedor/subsistemas, L3 Componente/scripts, L4 Código (opcional). No renombrar, no
   columna decorativa.

5. **Nuevo script vs. extender `generate-digest.sh`**: resuelto como **script nuevo**; contratos
   distintos (efímero por subcarpeta vs. artefacto versionado y estable).
6. **Alcance**: SOLO el core. El generador acepta la raíz como parámetro para uso futuro en satélites.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5) — APROBADO CON CAMBIOS: recuento 3 con evidencia, decisión 4 reforzada, deuda al roadmap, task file como primer commit, suite 21/21
- [x] APROBADO recibido — fecha/hora: 2026-10-13T22:31:07+01:00
- [x] Rama creada: `feat/T-102-mapa-flujos-c4` (desde `main` @ `58fe67e`)
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente