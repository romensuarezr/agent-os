# Idea: Publicación remota de tareas + mapa global de flujos de Agent OS — 2026-10-12

**Prioridad:** Media (calidad del flujo / DX) — candidata a sprint-15

> Contiene **dos ideas** relacionadas que conviene no separar: la primera es un hueco
> concreto del tooling, la segunda es la deuda estructural que hizo visible ese hueco.

---

## PARTE 1 — Publicación remota de ramas de tarea

### Problema

El flujo `/session-start` termina en `close-task.sh`, que commitea y archiva **en local**. No
existe ninguna herramienta que eleve el resultado a `origin`. El efecto observado en T-094 fue
un ciclo de correcciones entero dedicado a eso: push, `git ls-remote` para confirmar que la
rama existe, discovers que `main` está pinada en otro worktree, mergear a mano en ese worktree,
volver a intentarlo en el worktree original, y un `git branch -d` rechazado que obliga a
comprobar a mano y forzar con `-D`.

### Análisis de solapamiento (lo que ya existe)

Antes de proponer una herramienta nueva, el mapeo de lo existente:

| Script | Responsabilidad | ¿Publica la rama? | ¿Abre PR? | Tipo de merge |
| :--- | :--- | :--: | :--: | :--- |
| `promote-to-main.sh` | Consolida source → target, valida tests, emite JSON | ❌ solo empuja el *target* | ❌ | **`--ff-only` únicamente** |
| `worktree-merge.sh` | Merge de worktree efímero + desmantelamiento (ADR 004), JSON | ❌ | ❌ | controlado |
| `worktree-dispatch.sh` | Aprovisiona worktree + rama `feat/<task>-<profile>` | ❌ | ❌ | — |
| `contribute.sh` | Promoción inversa satélite → core | — | ❌ | — |
| `close-task.sh` | Commit atómico + archivado del task file | ❌ | ❌ | — |

**Hallazgo 1 — el script que iba a crearse ya existe en el 80%.** `promote-to-main.sh`
resuelve *exactamente* la fricción de worktrees que tuvimos que resolver a mano: localiza el
worktree que tiene la rama destino parseando `git worktree list --porcelain` (`find_target_worktree`,
línea 135) y ejecuta `git -C "$TARGET_WT" merge` y `git -C "$TARGET_WT" push` desde ahí. Además
valida árbol limpio, worktree destino limpio, posibilidad de fast-forward y ejecuta la suite del
control plane antes de mergear. Crear `publish-task.sh` tal cual habría duplicado su SRP y
violado el firewall anti-duplicación (`inventory-check.sh`).

**Hallazgo 2 — el hueco real es de otro tipo.** `promote-to-main.sh` solo admite `--ff-only`,
y el T-094 requería `--no-ff` por convención del repo (hay tres commits de merge:
`02f71ae`, `602d05a`, `64446d8`). El script **no habría podido** ejecutar el merge aprobado.
Además, en todo `scripts/agent/` no hay **ni una sola** invocación de `gh pr`: nadie publica
una rama de feature ni abre pull request desde el core.

**Hallazgo 3 — la política del usuario ya es PR-first.** El protocolo exige que la rama esté
en `origin` para que haya revisión del diff y aprobación de merge. Ninguna herramienta del
core implementa ese paso, así que hoy lo cumple el agente a mano, de forma no determinista.

### Propuesta

**No crear `publish-task.sh`. Extender `promote-to-main.sh`** con las capacidades que le
faltan, conservando su SRP (consolidar y publicar) y su digest JSON:

1. `--push-source` (o implícito): empujar la rama *source* a `origin` **antes** de consolidar,
   que es el paso que hoy falta y que provocó el ciclo de correcciones.
2. `--merge-commit`: alternativa a `--ff-only` para los merges que requieren commit de
   contenedor, con el mensaje que ya usa el repo (`merge: <scope> (T-XXX)`).
3. `--pr`: `gh pr create` + `gh pr merge --delete-branch`, para el flujo PR-first.
4. Verificación previa al borrado de rama: confirmar por API que `origin/main` contiene el tip
   antes de eliminar la rama local. Cero `--force` en todo el recorrido.

**Restricción dura**: ningún cambio de comportamiento por defecto. Lo actual (ff-only, sin
push de source) se conserva; todo lo nuevo es opt-in por flag.

### Preguntas a resolver en el sprint

- ¿Debe `close-task.sh` encadenar la publicación, o se mantienen como dos pasos explícitos?
  Encadenar reduce fricción pero mezcla commit local con acción remota.
- Si se adopta el flujo PR-first, ¿`session-start.md` debe cablear `promote-to-main.sh --pr`
  en su Fase 6? Al ser un workflow global, alterarlo cambia el comportamiento de todos los
  satélites y roza la política de breaking changes: probablemente exija ADR.

---

## PARTE 2 — Árbol de flujos de Agent OS

### Problema

El core tiene una cantidad creciente de superficie operativa —reglas, skills, workflows,
perfiles, scripts, ADRs, runbooks, tareas— sin ninguna vista de conjunto. Quien llega nuevo
no puede responder "¿qué hace Agent OS y en qué orden?" sin leerlo todo. Y no es solo un
problema de lectura humana: los agentes tampoco pueden responder preguntas sobre la topología
del sistema sin leer decenas de ficheros.

Hay un antecedente parcial y revelador: `docs/critical-flows.md` nació en T-098 por una regla del
workflow que no tenía dónde escribir. Se hoy existe un único flujo documentado a mano.

### Cómo se hace en buenas prácticas

Lo que se busca tiene nombre y precedentes establecidos:

- **Modelo C4** (Simon Brown): niveles de zoom fijos — Contexto → Contenedor → Componente →
  Código — más vistas **dinámica** (escenarios concretos numerados) y de **despliegue**. Lo
  valioso no son los diagramas sino que cada nivel significa lo mismo para todo el mundo, con
  un vocabulario mínimo compartido.
- **arc42** como plantilla de documento: la sección 5 "Building Block View" ya es jerárquica
  con niveles de zoom, y la sección 6 "Runtime View" es exactamente "flujos concretos" —
  escenarios numerados de piezas interactuando. Su consejo explícito es **no rellenar todo**:
  cada sección es mantenimiento que alguien firmará.
- **Diagramas como código** (Structurizr DSL, C4-PlantUML): el modelo se versiona junto al
  código y los diagramas se *generan*. Un diagrama dibujado a mano queda obsoleto el día que
  alguien renombra un contenedor; uno renderizado desde el modelo solo queda obsoleto si el
  modelo miente.

La lección que estos tres enfoques comparten y que hay que aplicar aquí: **generar, no escribir a
mano**. Un mapa de flujos mantenido a mano se convierte en basura más rápido que la
documentación estática, y este repo ya tiene la materia prima declarativa para generarlo.

### Materia prima que ya existe

| Activo | Aporta |
| :--- | :--- |
| `.agents/config/skills-manifest.yaml` | skills disponibles y su estado |
| `.agents/config/agent-registry.yaml` | agentes y roles |
| `.agents/config/routing-policy.yaml` | a quién enruta cada petición |
| `.agents/skills/`, `.agents/workflows/`, `.agents/rules/`, `.agents/profiles/` | las cuatro superficies del core |
| `scripts/agent/*.sh` | las operaciones ejecutables y su ciclo de vida |
| `docs/adrs/` | el *por qué* de cada decisión |
| `docs/critical-flows.md` | flujos que fallan sin señal clara (hoy: 1) |
| `inspect-skills.sh`, `inventory-check.sh` | precedents de escáner determinista con digest |
| `generate-digest.sh`, `fleet-doctor.sh` | precedente de digest compacto para agentes |

### Propuesta

**Un mapa de flujos generado, en dos niveles de zoom, con dos consumidores.**

- **Nivel 1 — imagen global (lectura humana).** Una página: el core y sus cuatro superficies
  (skills, workflows, rules, scripts), qué produce cada una y cómo se relacionan. Responde
  "¿qué es esto?" en un pantallazo.
- **Nivel 2 — flujos concretos (lectura humana y agente).** Los flujos ejecutables del sistema:
  ciclo de vida del satélite (`install → sync → contribute`), ciclo de una tarea
  (`session-start → close-task → publish`), y los flujos de datos con su invariante escrito
  (`sync` nunca es inverso). Numerados, como pide la vista dinámica de C4.
- **Vista de riesgos**: enlazar cada flujo con los flujos críticos de `critical-flows.md` y con
  el ADR que lo justifica. Es el punto donde el mapa se vuelve útil: hoy esa información está
  dispersa y es fácil no encontrarla cuando importa.
- **Consumo por agentes**: digest JSON/YAML del mismo modelo, siguiendo el principio 6 de
  `AGENTS.md` (si es determinista, un script lo resuelve con coste cero de tokens). El mapa se
  genera con un script, no se escribe.

**Restricción de disciplina**: aplicar el consejo de arc42 y no documentarlo todo. Empezar por
los flujos que ya generan fricción real (publicación de tareas, ciclo de tarea, distribución
a satélites) y crecer solo cuando aparezca una fourth pregunta que no se pueda responder.

### Preguntas a resolver en el sprint

- ¿El mapa vive en `docs/architecture/` (ya existe la carpeta) o en `docs/` raíz? Conviene
  decidirlo antes para no crear una segunda convención.
- ¿Generar diagramas visuales (PlantUML/Mermaid) o solo Markdown estructurado? Los diagramas
 requiere una toolchain de renderizado que este core no tiene; el Markdown generado es
  portable y no añade dependencias.
- ¿Quién es el consumidor prioritario, la persona o el agente? Define el formato del digest y
  cuánto detalle entra.

### Herramientas existentes: cuál usar y cuál descartar

Investigado antes de construir nada, para no inventar un motor de diagramas propio:

| Opción | A favor | En contra | Veredicto |
| :--- | :--- | :--- | :--- |
| **Mermaid** | GitHub lo renderiza **nativo** en Markdown: cero binario, cero paso de build, el diagrama viaja dentro del propio `.md` | Su CLI exige headless Chrome (peso muerto para renderizar server-side) | **Elegida para la vista humana** |
| **D2** | Binario Go único, sin navegador, layouts buenos | Pre-1.0 (v0.9.0), MPL-2.0, GitHub **no** lo renderiza: hay que exportar y versionar el SVG. Sintaxis propietaria | Capa opcional futura |
| **Graphviz** | El estándar abierto: un `.dot` lo lee casi cualquier herramienta (mejor salida estratégica de las tres) | Output feo, estilos a mano | Descartado ahora |
| **PlantUML** | Muy asentada | Necesita Java. Rompe la portabilidad del core | Descartada |

**Conclusión**: el modelo es texto plano; la capa humana es Markdown con Mermaid y la capa de
agentes es un digest JSON. Si algún día hacen falta diagramas más pulidos, D2 entra **encima**
sin tocar el modelo. Esta separación es lo que evita el peor resultado habitual: quedar atado a
una sintaxis propietaria.

### Solape con skills ya existentes

El core tiene un firewall anti-duplicación, así que antes de proponer una habilidad nueva hay
que mapear qué existe:

| Skill | Responsabilidad | Solape |
| :--- | :--- | :--- |
| `architecture-audit` | Audita **código**: SRP, dependencias, duplicidad, límite de 300 líneas | Ninguno: no toca documentación |
| `doc-maintainer` | Decide **dónde** vive un doc y obliga a actualizar fecha | **Parcial**: la habilidad nueva debe delegarle el guardado, no decidir ubicación |
| `structure-guardian` | Reubicaciones de ficheros por estándar | Ninguno |

### Propuesta concreta: tres piezas con SRP separado

1. **`scripts/agent/generate-flow-map.sh`** — determinista, cero tokens, portable. Lee los
   assets reales (skills, workflows, rules, profiles, manifests, ADRs, `critical-flows.md`,
   cabeceras de los scripts) y emite `docs/architecture/flow-map.md` (humano, Mermaid) más
   `flow-map.json` (agentes). Es una **fuente de verdad generada**, al estilo de
   `fleet-doctor.sh`. No es una descripción: es el resultado de inspeccionar lo que existe.
2. **`.agents/skills/flow-cartographer/SKILL.md`** — gobierna revisar, modificar y crear esa
   documentación: cuándo regenerar, cómo añadir un flujo, cómo enlazarlo con
   `critical-flows.md` y con el ADR que lo justifica. Delega el guardado en `doc-maintainer`.
3. **Distribución a hijos** — ambos artefactos ya figuran en `scripts/agent/assets-manifest.txt`,
   así que `install.sh` y `sync.sh` los propagan sin cambios. Al estar en el manifest, un
   proyecto hijo recibe el generador y la habilidad en su despliegue inicial.

### Preguntas que quedan abiertas

- **¿Debe el generador ejecutarse en el despliegue inicial del hijo?** `install.sh` hoy no
  genera nada. Pero un hijo tiene mucha menos superficie que el core: su "mapa" puede ser casi
  vacío, o con un enfoque distinto (qué skills usa, qué scripts corre, qué flujo de datos mantiene con el
  core). Es posible que lo útil en el hijo no sea el mismo mapa. **Decisión de diseño, no de
  implementación.**
- **¿En qué sprint entra?** La parte 1 (publicación) ya es candidata a sprint-15. La parte 2
  puede ir como tarea propia (`T-101`) si se decide ahora, o agruparla en el mismo sprint-15 para
  resolver ambas con el mismo análisis de flujo que la motiva.
- **¿Documentación generada + escrita a mano conviven?** Hoy `docs/architecture/` tiene tres
  documentos escritos a mano (`control-plane-topology.md`, `scout-business-hub.md`,
  `tool-inventory.md`). Hay que decidir si el mapa generado los absorbe, los referencia o
  convive. Riesgo de duplicidad semántica, no de ficheros.

### Riesgos

- Un mapa generado que nadie regenera se convierte en basura con la misma facilidad que uno
  escrito a mano. Mitigación: la habilidad obliga a regenerar en cada cambio estructural y el
  script imprime un digest para que el agente lo ejecute en vez de razonar sobre el mapa.
- Una skill nueva es **asset global**: llega a todos los satélites por `sync.sh` y cambia el
  comportamiento de los agentes que se activen por descripción. No es breaking, pero sí es
  superficie global, y por eso debe quedar etiquetada como feature de universalización en
  `changelog.md`.

---

## Origen

Sesión de trabajo del 2026-10-12: cierre de T-094 (unificación de `--path` en `audit-repo.sh`).
El bloqueo con `main` pinada en otro worktree y el `git branch -d` rechazado por comparar contra
HEAD dispararon la necesidad de automatizar la publicación; el inventario accidental de
`promote-to-main.sh`, `worktree-merge.sh` y `close-task.sh` reveló que el mapa de flujos
necesario para razonar sobre esas herramientas era precisamente lo que faltaba.