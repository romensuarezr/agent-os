# Changelog — Agent OS Core

Historial de cambios y releases del núcleo de Agent OS.

### 📋 Procedimiento de Versionado
1. **SemVer estándar**: El core utiliza Versionado Semántico (`MAJOR.MINOR.PATCH`).
2. **Versión Sprint 11**: Corresponde a la versión `1.10.0` (evolución y hardening del core sobre `1.9.0`).
3. **Momento de incremento**: La versión se incrementa formalmente en `changelog.md` al completar y cerrar cada sprint (o vía `close-sprint.sh`).
4. **Única fuente de verdad**: `changelog.md` es la única fuente canónica de versiones; no se duplica la versión estática en ningún otro archivo.
5. **Breaking Changes**: Los cambios breaking incrementan `MAJOR` (ej. `2.0.0`), documentándose con su correspondiente ADR en `docs/adrs/`.

## [Unreleased]

### ✨ Features & Universalización

- **T-098**: `scripts/agent/check-inference-gateway.sh`, pre-flight determinista y agnóstico de stack para cualquier pasarela OpenAI-compatible (FreeLLMAPI, OmniRoute, LiteLLM, vLLM, Ollama). Clasifica el estado en `OK`/`AUTH_FAIL`/`UPSTREAM_DOWN`/`UNREACHABLE`, ejecuta un probe mínimo opcional que revela el modelo realmente servido, nunca imprime la credencial, enmascara el host y expone digest `--json` para orquestadores, con códigos de salida canónicos para scripting.
- **T-098**: `docs/runbooks/local-agent-inference-runbook.md` documenta, sobre evidencia verificada con peticiones reales, el montaje de agentes locales (Hermes/OpenCode) contra pasarelas OpenAI-compatible en malla Tailscale con coste cero: taxonomía de fallos (502 por `tailscale serve` apuntando a `127.0.0.1` mientras el contenedor solo publica en la IP de Tailscale, 401 por credencial cruzada entre gateways, 503 por reintentos del combo `auto/*`, 402 por modelos que exigen clave de OpenCode), resolución de `<GATEWAY_HOST>` por MagicDNS sin literales de infraestructura versionados, y la trampa de `max_tokens` que produce falsos negativos de contenido vacío.
- **T-099**: Sincronización remota desde GitHub mediante flag `--remote` en `scripts/agent/sync.sh` con aprovisionamiento efímero en `/tmp`, soporte para `--branch` y `--tag`, limpieza determinista mediante `trap` y paridad en `scripts/agent/check-session.sh` para actualizar satélites autónomos sin requerir un clon local del core en disco.

### 🐛 Bug Fixes & Refactor

- **Fix en `scripts/agent/close-task.sh`**: Soporte completo para mensajes personalizados de commit pasados como argumento o flag `-m`. Se corrige la generación automática para cumplir la convención estándar `tipo(TASK_ID): descripcion` (o `tipo(scope): descripcion (TASK_ID)`). Asimismo, se endurece la guardia de sprint localizando dinámicamente el archivo de sprint que contiene la tarea (activo o archivado) y ampliando el regex de verificación para reconocer todos los sinónimos canónicos (`✅`, `🟢 Done`, `🟢 Completada`, `🟢 Completado`, `Done`) sin abortar erróneamente.
- **Endurecimiento de habilidad `infisical-secrets`**: Runbook y guía actualizados con patrón obligatorio de 2 pasos (`infisical login` con Machine Identity -> token efímero), resolución de secretos en subcarpetas por proyecto (`--path="/<proyecto>"`), flag `--type=shared` para eliminación de variables y especificación exacta del endpoint REST `POST /v1/auth/universal-auth/login` (evitando alucinaciones de ruta/puerto).
- **T-095**: `scripts/agent/secret-locate.sh` responde determinísticamente "¿dónde vive esta clave?" sin revelar valores. Es la pieza que elimina el bucle más caro y frecuente de un agente: buscar un secreto en la carpeta equivocada y pedirlo al usuario. Modos `--name` (carpetas donde existe la clave, avisando si está duplicada), `--list` (inventario por carpeta) y `--audit` (claves duplicadas y carpetas casi clonadas por similitud). Solo lectura, token efímero en memoria, salida `--json` para orquestadores.
- **T-095**: `verify-secrets.py` gana el modo `--source=infisical`, que audita la bóveda reutilizando el verificador de vigencia ya existente en lugar de duplicarlo. Detecta lo que ninguna herramienta detectaba por defecto: **shadowing**, es decir el mismo nombre de clave presente en varias carpetas con valores distintos, donde revocar una copia deja vivas las demás y un agente que elija la carpeta equivocada usa otra credencial sin enterarse. En la auditoría real se detectaron 17 conflictos de shadowing y 1 clave revocada.
- **T-095**: La skill `infisical-secrets` incorpora taxonomía de alcance (`scope`/`env`/`owner`/`consumers`/`rot`) y las reglas de ubicación respaldadas por medición, no por criterio subjetivo. Se corrige además una instrucción peligrosa: la skill documentaba `infisical secrets` como forma de "listar claves sin mostrar valores", cuando ese comando **imprime los valores en claro** y los vuelca en el contexto del agente y en el log de sesión. Documentar un comando que filtra secretos era en sí un agujero.
- **T-095**: La plantilla de onboarding del satélite incluye la sección de gestión de secretos con el protocolo de "no adivinar", delegando el detalle en la skill.
- **T-095**: **Corrección de un falso positivo结构性 de la propia auditoría.** La detección de shadowing original marcaba como conflicto cualquier clave con el mismo nombre y valores distintos en varias carpetas. Al cruzarla con evidencia de consumo real (el hash de cada valor frente a los `.env` de la flota) se demuestra que **12 de 16 no son conflictos**: `DATABASE_URL`, `PORT`, `TELEGRAM_CHAT_ID`, `APP_URL` o `N8N_API_KEY` son configuración **por proyecto** que comparte nombre a propósito, y forzarlos a un único valor rompería servicios en marcha. La auditoría ahora clasifica: `LEGITIMO_CONFIG_POR_PROYECTO` frente a conflicto real, y quedan **4** por revisar.
- **T-095**: El catálogo descubre ahora **referencias en el código**, no solo declaraciones de `.env` y compose. Una variable usada en el código y ausente de todo lo demás es un contrato incompleto que rompe en un clon nuevo, y hasta ahora pasaba desapercibida: en `kanairos` aparecieron 4 (`N8N_INGEST_DOCS_URL`, `N8N_POLL_AND_INDEX_URL`, `N8N_WEBHOOK_URL_POLL_AND_INDEX`, `WEBMASTER_MCP_HTTP_URL`). El stack se resuelve con `detect-stack.sh` para no hardcodear extensiones, cada entrada declara su `discovered_from` y su `status` (incluida `FALTA-DECLARAR`), y el ruido de runtime (`NODE_ENV` y compañía) se filtra. Se añade `kind` como heurística `secreto`/`config` —incluyendo URL y URI, que llevan credenciales embebidas— marcada explícitamente como pista y no veredicto.
- **T-095**: `scripts/agent/materialize-secrets.sh` completa el ciclo: vuelca en el `.env` del repo los valores que la bóveda tiene para las claves que ese repo declara, usando el catálogo como contrato. Es el inverso de `import-secrets.sh` y resuelve el caso del proyecto que no puede depender de conexión para arrancar. MODO DETECCIÓN POR DEFECTO: sin `--apply` no escribe nada. Garantías verificadas en la suite: nunca imprime valores, nunca pisa un valor local sin `--force`, escribe con permisos 600, nunca escribe en `.env.example` y **aborta con exit 1 si el fichero destino no está ignorado por git**, que es la protección que evita acabar con credenciales en un commit.
- **T-095**: `scripts/agent/generate-secrets-catalog.sh` genera `.agents/config/secrets-catalog.yaml`, el contrato de secretos de un repositorio: qué claves declara, de qué carpeta de la bóveda viene cada una, qué etiquetas tiene y si sigue viva. **Nunca contiene valores.** Se versiona en git porque convierte cada cambio de contexto en algo visible en un PR, cosa que un `.env` no permite al ser una foto ciega. Degrada a `source: local-only` cuando no hay bóveda, de modo que un proyecto hijo sin Infisical también tiene catálogo. Modo `--check` para pre-flight y CI.
- **T-095**: Se amplían los verificadores de vigencia con los proveedores que faltaban en la flota: **Cloudflare** (`/user/tokens/verify`), **Telegram** (`getMe`, definitivo) y **Sentry**, este último marcado como no comprobable porque validarlo exigiría enviar un evento de prueba, es decir escribir en producción. Se corrigen dos falsos negativos del verificador: Gemini responde HTTP 400 ante una clave inválida y se reportaba como "no comprobable", y Sentry se sondeaba con GET sobre un endpoint que solo admite POST.
- **T-095**: Se etiquetan con `scope-project` + `env-dev` las 31 apariciones de las 12 claves que comparten nombre entre carpetas pero son configuración por proyecto. La auditoría **respeta la etiqueta** y las clasifica como `INTENCIONAL_SCOPE_PROJECT`, de modo que dejarán de reportarse como shadowing. Integridad verificada: 278 valores comparados contra la copia previa, **0 alterados**. Limitación descubierta durante la ejecución: los slugs de etiqueta de Infisical solo admiten minúsculas, números y guiones, por lo que la forma válida es `scope-project` y no `scope=project` (rechazada con HTTP 422).
- **T-095**: Se elimina `/configuraciones`, predecesora de `shared`, tras verificar por hash que sus 5 claves ya existían en `/shared` con valor idéntico. Se aplica **descripción a las 11 carpetas** mediante `PATCH /v2/folders`, de modo que un agente sepa qué guarda cada una sin adivinar: la de `/kanarii` advierte de las tres credenciales expuestas, y la de `/shared` declara la taxonomía obligatoria.
- **T-095**: `secret-locate.sh` incorpora la metadata real de la bóveda, que hasta ahora se ignoraba. `--list` ordena las carpetas por `lastSecretModified`, de modo que ante un conflicto de shadowing la carpeta tocada más recientemente es la canónica probable, y muestra la descripción de cada carpeta. Nuevo modo `--hygiene`, que reporta las claves sin descripción ni etiquetas para que el agente pueda proponer completarlas.
- **T-095**: La bóveda no usaba los metadatos que su propio modelo de datos ofrece: la auditoría mide **283 de 283 entradas** sin descripción y sin etiquetas. Se documenta en la skill el uso de `tags` como vía de etiquetado real (la CLI los escribe con `--tag`) y el límite honesto de que la descripción no tiene flag de escritura documentado, además de la advertencia de que `--tag` reemplaza en lugar de añadir.
- **T-095**: Saneamiento de la bóveda de secretos de la flota (ejecutado con la herramienta previa, no a ciegas). Se crea la carpeta `shared` y se migran las 5 claves transversales que vivían dispersas en `/configuraciones` (GEMINI, GOOGLE, GROQ, HF y ZAI), verificando la integridad por hash sin exponer valores. Se eliminan dos carpetas que eran clones: `/kanairos_backup` (0 claves exclusivas en toda la bóveda) y `/codigo_descargado`. Inventario: de 13 a 12 carpetas y de 236 a 207 claves únicas. Antes de borrar se verificó la exclusividad clave por clave y se dejó una copia de ambas carpetas en `~/.local/share/agent-os/secret-backups/` con permisos 600. Las 29 claves que desaparecieron de la bóveda (21 exclusivas de `/codigo_descargado` más 8 que solo existían en esas dos carpetas a la vez) siguen presentes en los repositorios locales.
- **T-098**: Suite de control plane ampliada a 13/13 con cobertura del nuevo script: ayuda sin conectividad, validación de invocación sin `--url` (código 64) y clasificación JSON de gateway inaccesible sin filtrado de secretos.
- **T-095**: Suite de control plane ampliada a 14/14 con cobertura del localizador de secretos: ayuda sin conectividad, validación de invocación sin modo de operación (código 64) y verificación de que la skill y la plantilla desaconsejan el comando que imprime valores.
- **T-094**: `scripts/agent/audit-repo.sh` adopta el contrato `--path <dir>` que ya tenían `audit-child.sh` y `setup-profiles.sh`, eliminando la última asimetría de la familia de auditoría. El parseo pasa a ser un bucle completo: `--apply` y `--path` pueden enunciarse **en cualquier posición** y combinarse (`--apply --path <dir>` y `--path <dir> --apply` son equivalentes), en lugar del chequeo posicional `[ "$1" == "--apply" ]` que ignoraba silenciosamente el resto de la lista. Una opción desconocida ahora falla con mensaje y código de error en lugar de descartarse en silencio.
- **T-094**: Se corrige la resolución de `SCRIPT_DIR` en `audit-repo.sh`: se recalculaba con ruta relativa *después* del `cd` al proyecto destino, por lo que bajo `--path` las librerías de `lib/` dejaban de cargarse y las detecciones de stack y de tracker fallaban. Ahora se resuelve de forma absoluta antes de cualquier cambio de directorio y se eliminan los dos recálculos redundantes. Se añade además salvaguarda explícita cuando `--apply` apunta a un directorio que no es un repositorio git, caso que antes se reportaba engañosamente como "hay cambios sin commitear".
- **T-094**: Se crea `docs/critical-flows.md`, el registro que `session-start.md` exige consultar y actualizar antes de cerrar cualquier tarea que toque permisos, listeners o modelos de datos, y que el repositorio no tenía. Se registra el primer flujo crítico: discrepancia entre el bind real de un servicio y el destino configurado en el proxy inverso (backend sano por vía directa, error de gateway permanente vía proxy, healthcheck en verde).

## [1.12.0] — sprint-13 — 2026-09-30

### ✨ Features & Universalización

- **T-085**: Namespacing de configuración runtime (`config/` → `.agents/config/`) blindando overlays privados (`fleet.yaml`), reubicando 12 archivos y actualizando todos los scripts y tests sin dejar rutas deprecadas.
- **T-086**: Detección defensiva de stack y runtimes en `detect-stack.sh`: resolución declarativa preservada ante la dualidad lockfile vs PATH, exportando `AGENT_OS_PACKAGE_MANAGER` y `AGENT_OS_DETECTED_LOCKFILE` con warnings formales de divergencia.
- **T-087**: Distribución universal del Core y ADR-006: instalador desatendido reejecutable e idempotente (`mv-no-rm`) pineado a release tags (`v1.11.0`+), fuente canónica `VERSION` y one-liner documentado en `README.md`.
- **T-088**: Ledger de versiones del core y auditoría de salud en satélites: herramienta `scripts/agent/audit-child.sh` 100% local y offline (cero telemetría), ledger enriquecido en `last-sync.md` y cableado del pre-flight de inicio de sesión en `AGENT_ONBOARDING.project.md`.
- **T-089**: Setup guiado y generación determinista de perfiles adaptados al stack (`scripts/agent/setup-profiles.sh`): política de artefacto regenerable con marcadores `# BEGIN/END AGENT-OS-GENERATED-STACK` y adaptación de comandos en `developer.yaml` y `AGENT_ONBOARDING.md`.
- **T-090**: Prueba ciega 0-contexto de distribución e instalación desatendida: harness determinista `tests/test-blind-distribution.sh` (5/5 hitos) y fase ciega con sujeto real en sesión fresca, verificando el descubrimiento espontáneo del pre-flight de salud y capturando 4 tropiezos para el backlog.

### 🐛 Bug Fixes & Refactor

- **Fase 0**: Reparada regresión en `detect-stack.sh` capturando `${AGENT_OS_STACK:-}` antes del blanqueo de variables, restaurando la funcionalidad de override por entorno (`AGENT_OS_STACK=override detect_stack`).

## [1.11.0] — sprint-12 — 2026-09-29

### ✨ Features & Universalización

- **T-080**: Purga extendida de infraestructura personal en workflows (`session-start.md`, `session-close.md`), skills (`orchestrator`, `remote-admin`, `coolify-admin`), scripts (`discover-fleet.sh`) y templates (`fleet.example.yaml`, `agent-registry.yaml`).
- **T-081**: Blindaje de portabilidad shell: función `portable_timeout` unificada en `scripts/agent/lib/portable-timeout.sh`, validación de `AGENT_OS_PATH` por marcadores canónicos, pre-flight de permisos de escritura `[ -w ]`, trazabilidad de commit SHA del core en `last-sync.md` y robustez con `set -euo pipefail`.
- **T-082**: Coherencia de gobernanza y precedencia de perfiles: formalización canónica en `.agents/profiles/README.md` (`.yaml` declarativo estructurado > `.md` narrativo), resolución de ambigüedades en `AGENT_ONBOARDING.md` y renombrado preventivo a `changelog-workflow.md` para evitar colisiones case-insensitive en macOS.
- **T-083**: Estandarización de interfaz CLI unificada mediante `scripts/agent/lib/cli-help.sh` con flag `-h`/`--help` en la primera línea ejecutable de los 15 scripts del core, y normalización canónica de skills a directorios con `SKILL.md` (migración de `external-inbox/SKILL.md`).
- **T-084**: Validación y pilotaje empírico del core portable en repositorio real satélite (`romensuarez-web`): sincronización no destructiva (`sync.sh`), migración automática de skills legacy preservando personalizaciones locales, superación del protocolo de prueba ciega 0-contexto (H1-H5') y documentación del riesgo operativo de la dualidad `bun.lock`/`npm`.

### 🐛 Bug Fixes & Refactor

- **T-080**: Eliminadas referencias fijas a `***REMOVED-PATH***`, `/Users`, endpoints privados y sockets de producción.
- **T-081**: Eliminada duplicación de lógica de timeouts en bash y reemplazada invocación de `which` por `shutil.which` en Python.
- **T-083**: Normalizada sintaxis de scripts de Cloudflare DNS y armonizado vocabulario de fases y gatillos en rules y workflows.
- **T-084**: Corregida migración legacy en `sync.sh` sustituyendo `rm -f` por `mv` para permitir la reconciliación segura y no destructiva de personalizaciones locales.

### 📚 Documentación & Trazabilidad

- **T-084**: Acta de pilotaje formalizada en `.agents/tasks/task-084.md` con transcripción verbatim, rúbrica de evaluación externa y documentación de la dualidad técnica entre lockfile declarado y runtime del anfitrión.

## [1.10.0] — sprint-11 — 2026-09-29

### ✨ Features & Universalización

- **T-067**: `fleet-doctor.sh`: diagnóstico determinista de flota y Check 12 condicional en `validate-control-plane.sh`.
- **T-069**: Blindaje de `install.sh`: rutas dinámicas, pre-flights, `--check`, `set -euo pipefail`, instala `AGENT_ONBOARDING.md`, `sync.sh` no destructivo.
- **T-070**: Regla global `deterministic-execution.md` y resolución de contradicciones entre reglas existentes.
- **T-071**: Reparación del descubrimiento 0-contexto: inventario de skills, eliminación de referencias fantasma, inbox canónico y secuencia de boot `AGENT_ONBOARDING.md`.
- **T-072**: Purga de infraestructura personal en scripts y config (`***REMOVED-PATH***`, IPs fijas; `fleet.yaml` como overlay privado).
- **T-073**: Reglas, skills y perfiles agnósticos de stack, flota y herramientas propietarias.
- **T-074**: `detect-stack.sh` universal (11 stacks soportados: Python, TypeScript, JavaScript, Go, Rust, Java, PHP, Ruby, .NET, Bun, Static) con fallback honesto `unknown`.
- **T-076**: Instalación selectiva de skills por stack (`--minimal`/`--full`, manifiesto `config/skills-manifest.yaml`).
- **T-077**: `tool-inventory` y `repo-onboarding`: detección de stack, CI/CD (.github, .gitlab-ci, Jenkins), IaC (*.tf, docker-compose) y CLIs cloud (`aws`, `gcloud`, `az`).

### 🐛 Bug Fixes & Portabilidad

- **T-066**: Fix de renderizado y configuración en Homepage en producción.
- **T-068**: Saneamiento definitivo de Homepage en producción (dominios ficticios, ping `/health`, Ollama paramétrico).
- **T-075**: Barrido integral de portabilidad shell: compatibilidad Linux y macOS, comprobación determinista de dependencias requeridas.

### 📚 Documentación

- **T-078**: Higiene documental del core: unificación de versiones en changelog, roadmap sincronizado, integración de `DEFINITION_OF_DONE.md` en `AGENTS.md` y sanitización agnóstica de runbooks.

## [1.9.0] — sprint-10 — 2026-09-27

### ✨ Features

- feat: coolify compose deployment (T-065)
- feat: agnostic homepage generator (T-064)
- feat: dx searxng github widgets (T-063)
- feat: ai inference widgets (T-062)
- feat: multi node glances telemetry (T-061)
- feat(homepage): isolate docker socket via ro proxy and 32m limit (T-060)

### 📚 Documentación

- docs(runbooks): add coolify homepage deployment runbook with compose and mcp tooling
- docs(runbooks): add homepage security hardening runbook
- docs(runbooks): add glances multi-node telemetry setup runbook
- docs(sprint): initialize sprint-10-core planning and roadmap

## [1.8.0] — sprint-09 — 2026-09-27

### ✨ Features

- feat: deterministic promotion to main and cycle close (T-059)
- feat: core distribution and test hardening (T-058)
- feat: parallel orchestration engine and workflow (T-057)
- feat: declarative specialist profiles with rich frontmatter (T-056)
- feat: worktree lifecycle engine and atomic merge (T-055)
- feat: deterministic goals engine and quality gates (T-054)

### 🐛 Bug Fixes

- fix(check-session): harden core repository detection across git worktrees
- fix(core): restore last-sync.md core operational template

### 📚 Documentación

- docs(adrs): register ADR 005 for multi-agent parallel orchestration, deterministic goals, and worktree isolation
- docs(adrs): register ADR 004 and ADR 005 in ADR index table

## [1.7.0] — sprint-08 — 2026-09-27

### ✨ Features

- feat: <nodo-orquestacion> disk recovery plan(T-053)
- feat: deploy homepage fleet dashboard(T-051)
- feat: deploy bytebox coolify(T-050)
- feat(fleet): detect ngrok, stripe, cloudflared, supabase and sentry clis in discover-fleet
- feat: import secrets cli(T-049)
- feat: deploy infisical <nodo-orquestacion>(T-042)
- feat: deploy omniroute <nodo-inferencia>(T-048)
- feat: orca multiagent orchestration(T-041)
- feat: discover fleet cli(T-046)
- feat: sprint scout safeguard(T-045)
- feat: agnostic fleet decoupling(T-044)
- feat: fleet tool inventory(T-040)
- feat: opencode freellmapi validation(T-039)
- feat: orca readonly and gates(T-037)
- feat: deterministic scout(T-038)
- feat: remote github ssh auth(T-036)
- feat: <nodo-orquestacion> disk ports audit(T-035)
- feat(control-plane): implement Phase 1A declarative agent control plane foundation
- feat: e2e validation runbook freellmapi(T-029)
- feat: config providers ollama freellmapi(T-028)
- feat: deploy freellmapi <nodo-inferencia>(T-027)
- feat(skills): add list-hosts discovery script to remote-admin
- feat(skills): universalize and promote remote-admin to core (T-026)
- feat: promote coolify-nextjs-deploy (skill) from adama
- feat: sync assets manifest cleanup(T-025)
- feat: check session core updates detection(T-024)

### 🐛 Bug Fixes

- fix(agnostic): decouple private hosts, endpoints and IPs from skills, templates and scripts
- fix(scripts): support lowercase changelog.md in update-changelog.sh
- fix(scripts): support lowercase changelog.md in close-sprint.sh
- fix(script): allow directory recursive copy in contribute.sh for skills
- fix(sync): overwrite workflows during synchronization instead of using cp -n

### 📚 Documentación

- docs(sprint): cancel T-052 in favor of just-in-time OSS discovery with scout.sh
- docs: capture advanced homepage observability and fleet integrations idea
- docs(sprint): register task files for T-048 and T-042 and capture autonomous coordinator idea
- docs(inbox): capture OmniRoute AI gateway idea for Sprint 08
- docs(inbox): capture ideas for Infisical secrets manager and fleet tools inventory
- docs(workflows): compress session-start and sprint-planning to reduce token overhead
- docs(rules): consolidate QUE/POR QUE/TRADE-OFF and reduce token overhead
- docs(idea): register naming conventions ideas in inbox
- docs(idea): register assets manifest automation ideas in inbox
- docs(idea): register release flow redesign ideas in inbox
- docs(rules): add silent-execution rule and reduce verbose narration

### 🔧 Mantenimiento

- chore(sprint): initialize sprint-08-core with research and archive processed ideas
- chore: archive sprint-07-core [v1.6.0]
- chore: archive sprint-06-core [v1.5.0]
- chore(sprint): initialize sprint-06-core for Phase 1B
- chore: archive sprint-05-core [v1.4.0]
- chore: archive sprint-04-core [v1.3.0]
- chore: archive sprint-03-core
- chore: archive sprint-03-core

## [1.6.0] — sprint-07 — 2026-09-25

### ✨ Features

- feat(workflows): add optional DAG batch suggestions for Orca ADE in session-start and sprint-planning
- feat: orca multiagent orchestration(T-041)
- feat: discover fleet cli(T-046)
- feat: sprint scout safeguard(T-045)
- feat: agnostic fleet decoupling(T-044)
- feat: fleet tool inventory(T-040)
- feat: opencode freellmapi validation(T-039)
- feat: orca readonly and gates(T-037)
- feat: deterministic scout(T-038)
- feat: remote github ssh auth(T-036)
- feat: <nodo-orquestacion> disk ports audit(T-035)
- feat(control-plane): implement Phase 1A declarative agent control plane foundation
- feat: e2e validation runbook freellmapi(T-029)
- feat: config providers ollama freellmapi(T-028)
- feat: deploy freellmapi <nodo-inferencia>(T-027)
- feat(skills): add list-hosts discovery script to remote-admin
- feat(skills): universalize and promote remote-admin to core (T-026)
- feat: promote coolify-nextjs-deploy (skill) from adama
- feat: sync assets manifest cleanup(T-025)
- feat: check session core updates detection(T-024)
- feat: redesign roadmap sprint changelog flow (T-023)
- feat: validate sync compatibility(T-022)
- feat: agent dx improvements(T-021)
- feat: redactar adrs(T-020)

### 🐛 Bug Fixes

- fix(scripts): support lowercase changelog.md in update-changelog.sh
- fix(scripts): support lowercase changelog.md in close-sprint.sh
- fix(script): allow directory recursive copy in contribute.sh for skills
- fix(sync): overwrite workflows during synchronization instead of using cp -n
- fix(rules): add explicit criteria for QUÉ/POR QUÉ/TRADE-OFF

### ♻️ Refactoring

- refactor(rules): merge teach-while-building into caveman

### 📚 Documentación

- docs(inbox): capture OmniRoute AI gateway idea for Sprint 08
- docs(inbox): capture ideas for Infisical secrets manager and fleet tools inventory
- docs(workflows): compress session-start and sprint-planning to reduce token overhead
- docs(rules): consolidate QUE/POR QUE/TRADE-OFF and reduce token overhead
- docs(idea): register naming conventions ideas in inbox
- docs(idea): register assets manifest automation ideas in inbox
- docs(idea): register release flow redesign ideas in inbox
- docs(rules): add silent-execution rule and reduce verbose narration
- docs: adjust T-023 criteria and archive processed idea
- docs: move core-planning context to AGENTS.md, delete workflow and archive sprint-01-core
- docs: register T-024 task and update sprint-03-core
- docs: register T-023 task and initialize sprint-03-core
- docs: capture close-sprint bug in idea-inbox

### 🔧 Mantenimiento

- chore: archive sprint-06-core [v1.5.0]
- chore(sprint): initialize sprint-06-core for Phase 1B
- chore: archive sprint-05-core [v1.4.0]
- chore: archive sprint-04-core [v1.3.0]
- chore: archive sprint-03-core
- chore: archive sprint-03-core
- chore: archive sprint-02-core

## [1.5.0] — 2026-09-24
### Añadido
- **Auditoría Integral de Infraestructura en `<nodo-orquestacion>` (T-035)**:
  - Creado `scripts/agent/audit-host.sh` en `remote-admin` para diagnóstico rápido en 1 sola llamada SSH (0 tokens de inferencia).
  - Elaborado runbook exhaustivo en `docs/runbooks/<nodo-orquestacion>-disk-and-ports-audit.md` detectando 83 GB en descargas huérfanas de seedbox, 31 GB de imágenes Docker recuperables y ausencia de UFW con bypass de `DOCKER-USER`.
- **Normalización de Autenticación GitHub SSH en Servidores Remotos (T-036)**:
  - Creado `scripts/agent/check-git-remote.sh` en `remote-admin` para auditar `known_hosts` y claves públicas en servidores remotos sin exponer claves privadas.
  - Elaborado runbook en `docs/runbooks/github-ssh-setup-remote.md` con estrategia de Deploy Keys de solo lectura y aprovisionamiento determinista vía `ssh-keyscan`.
- **Prospección Determinista Pre-Código (T-038)**:
  - Creado `scripts/agent/scout.sh` para consultar repositorios en GitHub REST API, paquetes en NPM Registry y debates de arquitectura en Hacker News Algolia con coste 0 tokens de inferencia.
  - Integrado en `.agents/skills/tech-scout/SKILL.md` como paso 0 obligatorio antes de búsquedas web o Perplexity.
  - Formalizada regla pre-código en `.agents/rules/global/tool-decision-flow.md`.
- **Diagnóstico y Decision Gates de Orca (T-037)**:
  - Creado `scripts/agent/audit-orca.sh` para auditar proceso local de Orca, integridad de `orchestration.db` en modo solo lectura, y conectividad de relés remotos en `<nodo-inferencia>` y `<nodo-orquestacion>`.
  - Actualizado runbook `docs/runbooks/orca-read-only-audit.md` con el protocolo de compuertas de decisión humanas (L3) ante mutaciones.
- **Captura en Idea Inbox**:
  - Ideas registradas en `docs/idea-inbox/` para gestor de secretos autoalojado Infisical con Coolify/Hermes y para inventario activo de herramientas de la flota.

### Corregido
- Soporte para nombres de archivo `changelog.md` en minúsculas en `scripts/agent/update-changelog.sh`.

## [1.4.0] — 2026-09-24
### Añadido
- **Perfiles Declarativos de Agentes (`.agents/profiles/`)**: Registro de perfiles YAML para `coordinator`, `ops-auditor`, `developer`, `reviewer`, `marketing`, `seo` y `researcher` con definición estricta de herramientas, hosts, modelos preferidos y condiciones de escalado.
- **Registro Central (`config/agent-registry.yaml`)**: Catálogo maestro que asocia cada perfil a sus motores de ejecución (`antigravity`, `hermes`, `orca`, `opencode`) y asignación de hosts.
- **Política de Routing de Modelos (`config/routing-policy.yaml`)**: Matriz abstracta de enrutamiento por criticidad y clase de tarea (`critical_tasks`, `code_implementation`, `read_only_operations`, `marketing_and_seo`, `summaries_and_triage`, `private_data_tasks`, `general_fallback`) con fallbacks a FreeLLMAPI y Ollama local.
- **Política Global de Permisos (`.agents/rules/global/agent-permissions.md`)**: Regla de gobernanza que tipifica permisos en niveles L1 (Autonomía), L2 (Plan Aprobado) y L3 (Decision Gate Humano Obligatorio) para prevenir acciones destructivas en producción.
- **ADR 004 y Topología de Red (`docs/adrs/adr-004-agent-control-plane-architecture.md`, `docs/architecture/control-plane-topology.md`)**: Arquitectura de federación (`agent-os` core vs `hermes-vps-config` infra), asignación de roles (Hermes front door, Orca execution plane) y salvaguardas de disco.
- **Runbook de Auditoría de Orca (`docs/runbooks/orca-read-only-audit.md`)**: Procedimiento estándar de inspección no destructiva de Orca Desktop, sockets de relé remoto en VPS y base de datos relacional.
- **Suite de Validación (`tests/validate-control-plane.sh`)**: Validador no destructivo de sintaxis YAML, esquema de perfiles, consistencia de hosts y detección de secretos.
- **Endurecimiento de `.gitignore` raíz**: Bloqueo activo de variables de entorno, claves criptográficas, logs, caches, worktrees y bases de datos runtime.

---

## [1.3.0] — 2026-09-19
### Añadido
- **Skill Universal `remote-admin`**: Promovida al core (`.agents/skills/remote-admin`) para administración segura de servidores remotos vía SSH (`~/.ssh/config`), inspección de Docker y diagnóstico rápido de latencia/conectividad con el script `scripts/list-hosts.sh`.
- **Plantillas de Despliegue de FreeLLMAPI (`templates/freellmapi/`)**: Plantillas reutilizables de `docker-compose.yml`, `.env.example` y `config/freellmapi.config.json` para desplegar la pasarela de inferencia unificada con backend Ollama y proveedores gratuitos.
- **Runbook Operativo de FreeLLMAPI (`docs/runbooks/freellmapi-vps-runbook.md`)**: Guía detallada de arquitectura, binding seguro en Tailscale (`<ip-nodo-principal>:3001`), autenticación con Unified Key y ejemplos de consumo E2E (`curl`, OpenAI SDK).

### Infraestructura / Integración
- **Despliegue de FreeLLMAPI en `<nodo-inferencia>`**: Contenedor Docker configurado en `/home/ubuntu/freellmapi/`, conectado a la red compartida `<nodo>_default` con acceso directo a los modelos de Ollama (`llama3.1:8b`, `qwen2.5:7b`, `qwen2.5:3b`, `mistral-nemo:12b`) y enrutamiento automático a proveedores cloud gratuitos.

---

## [1.2.0] — 2026-06-15
### Añadido
- **Biblioteca de Detección de Stack (`detect-stack.sh`)**: Creado un componente centralizado para identificar el framework/lenguaje (Python, TypeScript, JavaScript) y exportar rutas, extensiones, patrones de complejidad y excepciones.
- **Configuración de Stack Manual (`stack.env`)**: Opción de override manual a través de `.agents/context/stack.env` para evitar falsos positivos en proyectos híbridos o con tooling mixto.
- **Gestión de `.gitignore` en la Instalación**: Creado el template `templates/.gitignore-agent-os` y modificado `install.sh` para incorporar de manera automatizada las exclusiones de archivos generados, de sincronización y del session lock en el proyecto destino.

### Modificado
- `scripts/agent/install.sh`: Modificado para verificar la existencia del marcador de Agent OS e inyectar el bloque de exclusiones de forma no destructiva si no existe.
- `scripts/agent/inventory-check.sh`: Refactorizado para usar variables y arrays dinámicos de stack, y salida limpia con código `0` en proyectos vacíos.
- `scripts/agent/generate-digest.sh`: Refactorizado para etiquetar código e indexar extensiones de forma dinámica basándose en el stack del proyecto.

---

## [1.1.0] — 2026-06-15
### Añadido
- **Flujo de Onboarding Inteligente (`sprint-inicial.md`)**: Creado como ritual exclusivo de una sola ejecución para auditar y adaptar repositorios preexistentes.
- **Marca de Onboarding (`onboarding-complete.md`)**: Implementada la generación automática de un archivo de marca al aplicar con éxito la auditoría, garantizando la idempotencia del proceso.
- **Sincronización de Workflows**: Modificado `sync.sh` para propagar de manera segura nuevos flujos y rituales globales al proyecto destino.
- **Detección Desacoplada de Actualizaciones**: Añadido aviso de commits remotos en `sync.sh` y registro de fecha de sincronización local en `.agents/context/last-sync.md`.
- **Integración en Sprint Planning**: Añadida una instrucción en `sprint-planning.md` para recomendar la sincronización si la marca local tiene más de 7 días o si no existe.

### Modificado
- `scripts/agent/audit-repo.sh`: Implementada la salvaguarda de working tree limpio, control de ambigüedad en apply, y generación del archivo de marca.
- `scripts/agent/sync.sh`: Modificado para copiar el changelog del core, escribir la fecha del último sync y comprobar silenciosamente actualizaciones en GitHub.

---

## [1.0.0] — 2026-06-12
### Añadido
- **Estructura Base de Agentes**: Directorios `.agents/rules/`, `.agents/workflows/`, `.agents/skills/`.
- **Scripts del Ciclo de Vida**:
  - `check-session.sh` y `check-sprint.sh`.
  - `close-task.sh` y `close-sprint.sh`.
  - `install.sh` y `sync.sh`.
  - `inventory-check.sh` y `update-mvp-tracker.sh`.
- **Workflows Base**: `session-start.md`, `session-close.md`, `sprint-planning.md`, `changelog.md`, `honesto.md`.
