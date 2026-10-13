# Research Sprint 15
> Fuente: sesión de planning del 2026-10-13 + `scout.sh` (prospección OSS determinista, 0 tokens)
> Tarea principal: T-100 fixes de los scripts de cierre; T-101 publicación remota; T-102 mapa de flujos

## Hallazgos clave

1. **El ritual de planning estaba bloqueado por dos defectos que invaltaban sus propias
   precondiciones** (corregidos en `main`, `0b40209`):
   - Exigía `ROADMAP.md` en mayúsculas mientras el estándar del core es `roadmap.md`
     (`audit-repo.sh` migra de forma proactiva los repos). La detección decía "✅ Detectado" por
     coincidencia de caso, enmascarando el incumplimiento.
   - `SPRINT_SIGUIENTE` ignoraba `docs/sprints/_archived/` y proponía `sprint-01`, es decir
     reiniciar la numeración de 14 sprints ya cerrados.
   Lección: un prerrequisito que el propio flujo no puede cumplir es una puerta que siempre
   está cerrada, y el síntoma se disfraza de éxito.

2. **Los dos bugs de `close-*.sh` comparten causa estructural**: el script ejecuta la acción
   y reporta éxito sin verificar que el efecto se haya materializado.
   - `close-task.sh`: `git mv` del task file pero la fila del sprint sigue apuntando al
     directorio activo. Se parcheó a mano cuatro veces (T-094, T-095, T-096, T-098).
   - `close-sprint.sh`: `git mv` mueve la versión **del índice**, no la del working tree, así
     que las modificaciones sin stagear quedan fuera del commit. El commit de cierre de
     sprint-14 salió `0 insertions / 0 deletions`.

3. **La verificación post-acción debe ser explícita**, no implícita: comparar `git show --stat`
   contra lo que el script afirma haber hecho, y fallar con código distinto de cero.

4. **Scouting OSS para T-102** (mapa de flujos / arquitectura como código):
   - `structurizr/structurizr` (458⭐, Apache-2.0): "models as code" para C4. Es el estándar
     de facto para el modelo, pero es Java/Kotlin y arrancaría desde cero en este core bash.
   - `mingrammer/diagrams` (42.7k⭐, MIT): diagramas como código para arquitecturas cloud.
     Python, muy extendido, orientado a infraestructura cloud más que a flujos de proceso.
   - `CodeBoarding/CodeBoarding` (2.5k⭐, MIT): diagramas interactivos para codebases.
   - D2 (binario Go único, MPL-2.0, pre-1.0): sin navegador, pero no lo renderiza GitHub.
   **Conclusión**: no hay un reemplazo directo que genere *flujos de proceso* desde assets
   declarativos de un core bash. La decisión real es si el mapa se genera con un script
   propio (portable, cero dependencias, consistente con AGENTS.md) o se adopta una toolchain
   de diagramas (más bonito, más dependencias, peor portabilidad). Mermaid tiene el
   argumento a favor decisive: GitHub lo renderiza nativo, así que el diagrama viaja dentro
   del propio `.md` sin build ni binario.

5. **Scouting OSS para T-101**: la funcionalidad de PR ya está disponible vía la CLI `gh`,
   que el core ya usa (`fleet-doctor.sh` la verifica). No hace falta scraper ni SDK: es
   orquestación de una dependencia existente.

### Investigación de Perplexity (2026-10-13) — patrones canónicos para T-100

**1. Verificación post-condición en scripts de commit.** Recomendación recibida: *assertion
tree* comparando el árbol Git antes y después, inspeccionando la tabla binaria del commit con
`git diff-tree -r --no-commit-id --name-status <sha>` en lugar de parsear texto de
`git show --stat`. Se esperan acciones concretas (`D path/viejo`, `A path/nuevo`,
`R100 old new`) y si la aserción falla se revierte con `git reset --soft HEAD~1` y código
distinto de cero.
Casos límite señalados: `core.quotePath` entrecomilla rutas con espacios o no-ASCII;
cambios pre-existentes en staging que el script no aisló; hooks `pre-commit` que alteran el
árbol entre el stage y el commit.

**2. Reescritura idempotente y portable de enlaces Markdown.** Recomendación recibida:
*snap atómico* con `awk` POSIX — nunca `sed -i` (BSD y GNU difieren), sustitución por
`index()`/`substr()` para no interpretar metacaracteres como regex, escritura a temporal en
el mismo directorio y `mv` final; idempotencia comprobando antes con `grep -q` si el destino
nuevo ya está, y post-verificación obligatoria tras el `mv`.
Casos límite: enlaces relativos heterogéneos (`./.agents/...` vs `.agents/...`); directorios
sin permiso de escritura para el temporal; finales de línea CRLF en Git Bash que `awk`
conserva.

**3. Detección del sprint file sin depender del idioma.** Recomendación recibida: buscar
**estructuralmente** solo en el nivel superior de `docs/sprints/`, excluyendo `_archived/`,
buscando la celda de tabla `| T-XXX |`. Los sprints finalizados viven exclusivamente en
`_archived/`, así que la separación de carpetas es la regla de oro y no hace falta asumir
estados en lenguaje natural.
Caso límite: tareas listadas como elemento de lista (`- [ ] T-100`) en lugar de celda de
tabla.

## Decisiones tomadas
- **Decisión:** `close-*.sh` se arreglan con verificación post-acción explícita, no con
  parches incrementales.
  **Por qué:** el patrón de fallo (afirmar sin verificar) se repite; sin verificación, el
  siguiente fallo del mismo tipo no se detecta.
  **Constraint clave:** `close-task.sh` usa `git add -A`; el fix de T-101 no debe extender ese
  comportamiento a `close-sprint.sh` sin decirlo explícitamente.
  **Referencia:** ADR-003 (ciclo de vida y locks) documenta el contrato de cierre.

- **Decisión:** `close-task.sh` actualiza el enlace de la fila del sprint al archivar.
  **Por qué:** el enlace roto es la señal visible de que el cierre fue incompleto, y obliga a
  un commit de corrección manual que ensucia el historial.
  **Constraint clave:** debe ser idempotente; si el enlace ya apunta a `_archived/`, no tocarlo.

- **Decisión:** publicar las ramas de tarea por remoto (PR) en vez de merge local.
  **Por qué:** el protocolo exige revisión del diff vía origin, y hoy se cumple a mano.
  **Constraint clave:** `promote-to-main.sh` solo admite `--ff-only`; hace falta `--merge-commit`.
  **Referencia:** idea `docs/idea-inbox/2026-10-12-publicacion-remota-y-mapa-de-flujos.md`.

### Decisiones derivadas de la investigación de Perplexity

- **Decisión:** la verificación post-acción se apoyará en `git diff-tree -r --no-commit-id
  --name-status` sobre el SHA recién creado, en vez de parsear la salida de texto de
  `git show --stat`.
  **Por qué:** inspecciona la tabla binaria del commit, que es determinista, y no texto
  formateado que puede cambiar entre versiones de git.
  **Constraint clave:** hay que aislar el staging (o asumir `git add -A` explícito) y ser
  consciente de que un hook `pre-commit` puede alterar el árbol entre stage y commit.

- **Decisión:** la reescritura del enlace se hará con `awk` + temporal + `mv`, sin `sed -i`.
  **Por qué:** `sed -i` es la causa clásica de fallos de portabilidad entre macOS y Linux, y
  este core prioriza funcionar idéntico en ambos.
  **Constraint clave:** la post-verificación con `grep -q` no es opcional: es lo que
  convierte el patrón en idempotente y detectaría un fallo en vez de anunciarlo como éxito.

- **Decisión:** la búsqueda del sprint file se Structural y solo en el nivel superior de
  `docs/sprints/`.
  **Por qué:** no depende del idioma ni del formato de la tabla, y `close-sprint.sh` ya
  archivó sprint-14 correctamente a `_archived/`.
  **Constraint clave:** si una tarea se lists como elemento de lista y no como celda de
  tabla, la búsqueda no la encontrará. Hay que registrar esa limitación en el script.


## Descartado
- **Crear un script nuevo de publicación** (`publish-task.sh`): `promote-to-main.sh` ya
  cubre el 80% (localiza el worktree destino, valida árbol limpio, corre la suite, emite
  JSON). Duplicarlo violaría el firewall anti-duplicación del propio core.
- **Copiar un token vivo de otro repo** al rotar las credenciales revocadas: los tokens de
  Cloudflare tienen permisos por zona y las claves de Gemini están atadas a un proyecto de
  Google. Copiar daría acceso a dominios ajenos o violaría los términos del proveedor.
- **Copiar el pre-flight de secretos a `check-session.sh`**: un aviso recurrente que rara vez
  exige acción es ruido que entrena a ignorar los avisos. La marca se lee solo cuando un
  agente trabaja con secretos.
- **Diagramas como build step** (D2/PlantUML con SVG exportado): añade binario y paso de
  renderizado a un core que prioriza portabilidad y cero dependencias.

## Descubrimientos Scout (por tarea)

### T-100 — Fixes de `close-task.sh` y `close-sprint.sh`
- **Alternativa detectada:** ninguna. No se ha encontrado ninguna librería ni CLI que
  resuelva "reescribir el enlace de la fila al archivar y verificar el commit".
- **Recomendación del agente:** desarrollo a medida justificado. La lógica son ~30 líneas de
  Bash dentro de scripts que ya existen; introducir una dependencia para eso rompería la
  portabilidad y la política de cero dependencias pesadas del core.
- **Decisión del usuario:** (pendiente de confirmar en la sesión)
- **Notas de integración:** los patrones concretos vienen de la investigación de Perplexity
  (assertion tree con `git diff-tree`, `awk` + swap atómico, búsqueda estructural). Se
 Se integran en el código, no se instalan como dependencia.

### T-101 — Publicación remota de ramas de tarea
- **Alternativa detectada:** la CLI `gh` (GitHub), ya verificada por `fleet-doctor.sh` como
  dependencia del core.
- **Recomendación del agente:** adoptar. No crear scraper ni SDK; orquestar `gh pr create` /
  `gh pr merge`.
- **Decisión del usuario:** (pendiente de confirmar en la sesión)
- **Notas de integración:** extender `promote-to-main.sh`; NO crear un script nuevo (el
  firewall 2c confirmó que ya cubre el 80%).

### T-102 — Mapa global de flujos con niveles C4
- **Alternativas detectadas:** `mingrammer/diagrams` (42.7k⭐, MIT), `structurizr/structurizr`
  (458⭐, Apache-2.0), D2 (binario Go, MPL-2.0, pre-1.0).
- **Recomendación del agente:** desarrollo a medida para el generador + Mermaid para el
  render. Mermaid lo renderiza GitHub de forma nativa, así que el diagrama viaja dentro del
  propio `.md` sin build ni binario, que es lo que pide un core portable.
- **Decisión del usuario:** (pendiente de confirmar en la sesión)
- **Notas de integración:** el modelo debe ser texto plano y el renderizado opcional, para no
  atar el mapa a la sintaxis de una herramienta propietaria.

