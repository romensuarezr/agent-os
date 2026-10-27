# Research Sprint 19

> Fuentes: inspección del código en ejecución sobre `multi-agent` @ `847546f` / `main` @ `cdb1566`
> (2026-10-27), `inventory-check.sh` (4 consultas) y `scout.sh` determinista.
> Tareas: T-113 `VERSION` automática · T-114 `PREV_TAG` · T-115 versión de la flota · T-116 honestidad del escáner

## Descubrimientos Scout (por tarea)

### T-113 — El cierre escribe `VERSION`
- **Alternativa detectada:** ninguna. `semantic-release`/`release-it` (ya evaluados en sprint-18, ver `_archived/sprint-18-core-research.md`) resuelven el versionado de un proyecto Node, no el `VERSION` de un core bash sin `package.json`.
- **Recomendación del agente:** desarrollo a medida (≈8 líneas en `close-sprint.sh`).
- **Decisión del usuario:** desarrollo a medida — el fix es una asignación atómica dentro del commit que ya existe.
- **Notas de integración:** N/A.

### T-114 — `PREV_TAG` por versión
- **Alternativa detectada:** ninguna aplicable; `git describe` es la primitiva nativa (sin dependencia).
- **Recomendación del agente:** desarrollo a medida sobre git.
- **Decisión del usuario:** desarrollo a medida justificado.
- **Notas de integración:** N/A.

### T-115 — Desfase de versión de la flota
- **Alternativa detectada:** `scout.sh "version drift tracking fleet satellite core"` → 0 repos GitHub ≥500⭐; los paquetes devueltos (`satellite.js`, `is-core-module`, `@sentry/node-core`) son homónimos irrelevantes.
- **Recomendación del agente:** desarrollo a medida (lectura de ficheros locales, sin red).
- **Decisión del usuario:** desarrollo a medida, alcance mínimo, sin dashboards.
- **Notas de integración:** reutilizar el formato del ledger que ya escriben `install.sh` y `sync.sh`; no inventar un fichero nuevo.

### T-116 — Honestidad de `locator-hygiene.sh`
- **Alternativa detectada:** ninguna (herramienta propia del core).
- **Recomendación del agente:** desarrollo a medida.
- **Decisión del usuario:** desarrollo a medida justificado.
- **Notas de integración:** N/A.

### T-117 — `secrets.sh` (valores por stdin, huella, `--search`)
- **Alternativa detectada:** `scout.sh` → 0 repos ≥500⭐; `get-stdin` (npm, Node), `secretlint` (escáner, no un punto de escritura), `@expo/fingerprint` (irrelevante).
- **Recomendación del agente:** desarrollo a medida.
- **Decisión del usuario:** desarrollo a medida — el contrato es de proceso (stdin, sin eco) y de integración con Infisical.
- **Notas de integración:** N/A.

### T-118 — `lib/redact.sh` y normas
- **Alternativa detectada:** `scout.sh` → 0 repos ≥500⭐; `object-inspect`, `is-docker`, `@azure/logger` irrelevantes. `secretlint` detecta secretos en ficheros, no redacta un stream.
- **Recomendación del agente:** desarrollo a medida (filtro de líneas, sin dependencias).
- **Decisión del usuario:** desarrollo a medida.
- **Notas de integración:** N/A.

## Hallazgos técnicos verificados

### T-113 — `VERSION` no se escribe al cerrar
- `VERSION` (raíz) es canónico y ya se consume: `install.sh:196-217` y `:796-805`, `sync.sh:522-523`, `audit-child.sh:80-99` y `:224-236`; `tests/test-install-oneliner.sh` y `tests/test-audit-child.sh` lo referencian.
- `close-sprint.sh:112-122` ya calcula `VERSION_TAG` desde la primera entrada `## [` del changelog y lo usa en el mensaje del commit (`:170-171`). **Nunca escribe `VERSION`.**
- Consecuencia observada: la release `v1.14.0` se publicó con `VERSION = 1.12.0`. Cualquier satélite sincronizado desde ese clon habría registrado la versión equivocada en su `last-sync.md`.
- El staging de `close-sprint.sh` ya es acotado ("propios ficheros"); `VERSION` debe entrar explícitamente en ese conjunto.

### T-114 — `PREV_TAG` ordena por fecha de creación del tag
- `update-changelog.sh:49`: `git tag --sort=-creatordate | head -1`. En el cierre del sprint-18 eligió `v1.13.0` por casualidad: los tags se crearon en orden cronológico creciente.
- El fallo aparece si se crea un tag de parche sobre una release anterior, si se reetiqueta, o si se importa un tag con fecha antigua: el rango `PREV_TAG..HEAD` deja fuera commits o los repite.
- Fallback actual sin tags: `HEAD~50..HEAD` (`:52`).
- El check 26 existente cubre el semver del changelog (`## [Unreleased]`), no la selección del tag base → se extiende.

### T-115 — El dato existe; falta la vista agregada
- `install.sh:792-805` y `sync.sh:519-534` escriben `.agents/context/last-sync.md` con tres líneas: `fecha`, `version:`, `tag:` (y `commit:` en install).
- `audit-child.sh:80-99` localiza el core y su `VERSION`; `:224-236` compara el ledger del hijo contra el core y avisa `Desalineado con el core: satélite=X vs core=Y. Ejecuta sync.sh.` o `legacy/no declarada`.
- **Hueco real:** esa comparación es *por hijo y ejecutada dentro del hijo*. No existe forma de ver el desfase de la flota de una vez (inventory-check no encontró agregador alguno).
- **Trampa de diseño:** el `last-sync.md` del propio core **no** es el ledger — es un documento escrito a mano (modo self-hosted, tabla de hijos) y sigue diciendo "sprint-18". Un agregador que asuma "todo `last-sync.md` tiene formato ledger" fallará en el core.
- **Descubrimiento de satélites:** `.agents/config/satellites.yaml` es solo esquema con ejemplos comentados y se distribuye a los hijos; las entradas reales del operador viven en `.agents/config/fleet.yaml`, **gitignored** (`.gitignore:17-23`). Sin `fleet.yaml`/`satellites.yaml` poblado no hay descubrimiento: la herramienta debe aceptar rutas explícitas y decir "no configurado", no inventar la flota.
- Caso real: `ops-hub` arrancó con el core del 5-6 oct y el core ya es `v1.14.0`.

### T-116 — Dos formas de afirmar "limpio" sin verificar
- `locator-hygiene.sh:118`: `FILES="$(git -C "$ROOT" ls-files 2>/dev/null || true)"` → solo ficheros **trackeados**. Un fichero nuevo con una IP real no se escanea.
- Si `$ROOT` no es un repo git, `ls-files` falla, `FILES` queda vacío y el script termina con `exit 0` → **"limpio"**. Reproducido en T-106 al pasar `--path` sobre un directorio no-repo; el fix de entonces (`--path` honra excepciones) no tocó esta salida.
- El check 22 (`tests/validate-control-plane.sh:947`) solo ejecuta el escáner sobre el core (repo git, todo trackeado), así que **no puede detectar ninguno de los dos huecos**.
- Clase de bug común con el resto del sprint: una herramienta que afirma un veredicto sobre datos que no miró.

### T-117 — El doble barrido de `--hygiene` y la receta con valor
- `secret-locate.sh:170-175` construye el inventario llamando `keys_in(f)` (→ `keys_with_meta` → `infisical export`) para **cada** carpeta.
- `secret-locate.sh:197-201` (`--hygiene`) vuelve a llamar `keys_with_meta(f)` para cada carpeta: **segundo `infisical export` por carpeta**, sin reutilizar `tags`/`comments` del primero. Eso es la "doble exportación".
- La receta de higiene (`:212`) imprime `infisical secrets set <CLAVE>='<valor>' ...`: valor en `argv`.
- La receta final (`:252-253`) recomienda `infisical run -- bash -c 'echo $<CLAVE>'`.
- `import-secrets.sh` (`.env` → bóveda, dry-run por defecto) y `materialize-secrets.sh` (bóveda → `.env` 600, rechaza ficheros versionados) ya no imprimen valores: el hueco es el punto de escritura puntual y las recetas, no la migración masiva.

### T-118 — La norma dice lo que la skill desmiente
- `agent-permissions.md` (tabla, "Acceso a Secretos"): L3, "prohibido leer, mostrar, imprimir o transferir".
- `infisical-secrets/SKILL.md:120` y `:194`: `eval $(infisical export ...)`; `:175` y `:321`: `secrets set CLAVE="valor"`; `:59`/`:142`: `export INFISICAL_TOKEN=$(...)` (token en variable de shell).
- `AGENT_ONBOARDING.md:72`: remite a `import-secrets.sh` "o el cliente oficial" — lista abierta, sin script cerrado.
- No existe `lib/redact.sh` ni ningún filtro para `docker compose config`, `docker inspect`, `env`/`printenv`.

## Ideas archivadas en este planning

| Idea | Tarea que la cerró |
|---|---|
| `2026-06-18-rediseño-release-changelog.md` | T-108 |
| `2026-06-18-convencion-nombres.md` | T-109 |
| `2026-09-30-portabilidad-cp-update-none.md` | T-110 |

## Riesgos y decisiones

- **R1 (T-115):** el formato del ledger no tiene versión de esquema. Mitigación: parsear las claves `version:`/`tag:` con tolerancia y marcar `LEGACY`/`AUSENTE` en vez de fallar; un satélite sin `last-sync.md` es un hallazgo, no un error de la herramienta.
- **R2 (T-113):** si el changelog no tiene entrada con versión, `close-sprint.sh` debe avisar y **no** tocar `VERSION` (nunca escribir `unknown`).
- **R3 (T-116):** incluir untracked por defecto puede encarecer el escaneo en árboles grandes. Se decide en el plan de la tarea; la opción conservadora es `--include-untracked` explícito y que el check 22 lo use.
- **Decisión:** T-115 reserva el check 31; T-113 el 30, T-117 el 32 y T-118 el 33. Si el orden de ejecución cambia, se usa el siguiente número libre y se anota en el sprint.
- **R4 (T-117):** `--search` recorre **metadatos** (claves, comentarios, etiquetas) o valores? Decisión propuesta: buscar en valores implica leerlos; se hace dentro del script, se devuelve solo carpeta+clave+hash del valor, nunca el valor ni un fragmento. Si el usuario prefiere metadatos-only, se acota en el plan.
- **R5 (T-118):** `redact.sh` necesita saber qué claves redactar. Por defecto, el catálogo `.agents/config/secrets-catalog.yaml` (generado, sin valores); `--keys` para casos puntuales. Si el catálogo está vacío, el filtro no redacta nada: el check 33 debe cubrir ese caso con `--keys`.
