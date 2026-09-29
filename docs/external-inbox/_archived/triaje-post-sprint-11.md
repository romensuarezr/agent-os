# Triaje de hallazgos de auditoría — post Sprint 11

**Fecha:** 2026-09-28
**Repo auditado:** `romensuarezr/agent-os` (auditoría sobre `5099bbe`, 2026-09-28)
**Estado del sprint al redactar:** T-067, T-068, T-069, T-070, T-071, T-074, T-075 ✅ completadas · T-072, T-073, T-076, T-077, T-078 ⬜ pendientes · T-079 ⬜ pendiente (puerta de cierre)
**Documento:** borrador para revisión del usuario. No se ha modificado ningún repo.

---

## 1. Metodología

1. **Extracción:** lectura de `~/workspace/audits/agent-os/AUDITORIA.md` y los tres informes consolidados (`findings-scripts.md`: 33, `findings-rules-profiles-config.md`: 30, `findings-skills-workflows-docs.md`: 54) → **117 hallazgos** (32 alta · 56 media · 29 baja). Los IDs originales colisionan entre informes (cada uno tiene sus "A1…"), así que aquí se prefijan: `SCR-` (scripts), `RUL-` (rules/profiles/config), `SKL-` (skills/workflows/docs).
2. **Cruce:** clon fresco de `main` (commit `b1ba4ae`, posterior a T-069). Lectura de `docs/sprints/sprint-11-core.md` (incluye el "Mapa de cobertura auditoría → tareas") y de los criterios de done de `.agents/tasks/task-067.md` … `task-079.md`.
3. **Verificación data-first:** para las tareas marcadas como completadas se comprobó en el código del clon una muestra de los fixes (greps de rutas personales, `timeout`, `set -euo pipefail`, `which`, skills fantasma, `trigger:`, rutas `external-inbox/`, etc.). Lo verificado se indica; lo no verificado se marca como tal.
4. **Clasificación** de cada hallazgo:
   - **Resuelto** — cubierto por una tarea completada (verificado donde se indica).
   - **Parcial** — una parte resuelta; queda resto (en tarea pendiente o por decidir).
   - **En alcance (Sprint 11)** — cubierto por T-072/T-073/T-076/T-077/T-078, aún pendientes de ejecución.
   - **Backlog** — sin tarea asignada; candidato a Sprint 12.
   - **Requiere decisión** — ambiguo; necesita criterio del usuario antes de actuar.
   - **Wont-fix propuesto** — con justificación.

> **Caveat:** T-079 (prueba ciega 0-contexto) puede generar hallazgos nuevos no contemplados en este triaje. Este documento cubre solo la auditoría 2026-09-28.

---

## 2. Resumen ejecutivo

| Severidad | Total | Resuelto | Parcial | En alcance Sprint 11 | Backlog Sprint 12 | Requiere decisión | Wont-fix |
|---|---|---|---|---|---|---|---|
| 🔴 Alta | 32 | 16 | 1 | 13 | 2 | 0 | 0 |
| 🟡 Media | 56 | 16 | 5 | 18 | 14 | 3 | 0 |
| 🔵 Baja | 29 | 1 | 3 | 6 | 13 | 4 | 1 |
| **Total** | **117** | **33** | **9** | **37** | **29** | **7** | **1** |

*(+1 nota positiva SKL-T-2 sin acción requerida = 117.)*

**Lectura:** el Sprint 11 absorbe ~76% de los hallazgos (33 resueltos + 37 en curso + 9 parciales). Quedan **29 hallazgos sin tarea asignada** (el backlog propuesto abajo) y **7 que requieren decisión del usuario** antes de actuar. Solo **2 son de severidad alta** y ambos son de la misma familia: infraestructura personal fuera del alcance declarado de T-072 (workflows y SKILLs, no scripts/config).

---

## 3. Hallazgos en alcance del Sprint 11 (pendientes de ejecución)

Se resuelven al completar las tareas pendientes. No requieren acción nueva, solo seguimiento.

- **T-072** (purga scripts/config): SCR-A2, SCR-A3, SCR-A4, RUL-A7, SKL-M1 (+ parciales: SCR-A1-refuerzo, RUL-A8, RUL-D2, RUL-D3, RUL-D4, RUL-D7-nombre).
- **T-073** (rules/skills agnósticas): RUL-A1, RUL-A3, RUL-A4, RUL-A5, RUL-A9, RUL-A10, RUL-C6, RUL-C7, RUL-D6, SKL-A6, SKL-H-13 (+ parciales: RUL-A2-resto, SKL-M2-resto).
- **T-076** (skills selectivas): SKL-A1, SKL-A2.
- **T-077** (inventory real): SKL-H-02, SKL-H-04, SKL-H-05, SKL-H-09, SKL-H-08 (+ parcial: SKL-H-11).
- **T-078** (higiene documental): SKL-R-1, SKL-R-2, SKL-C-1, SKL-C-2, SKL-MEDIA-2, SKL-MEDIA-3, SKL-R-3, SKL-D-1, SKL-T-1, SKL-B1, SKL-D-2 (+ parcial: SKL-E-1-versión).

## 4. Hallazgos parciales (9)

| ID | Estado | Qué falta |
|---|---|---|
| RUL-A2 | T-070 ✅ (paso 1 de `tool-decision-flow` condicionado a `fleet.yaml`) | Los ejemplos (FreeLLMAPI, n8n, Unified-DB, MinIO) como "paso 1 universal" → en alcance T-073 |
| SKL-M2 | T-070 ✅ (condicional) | Agnosticidad de los ejemplos → en alcance T-073 |
| RUL-A8 | T-072 ⬜ audita IPs/refs en `agent-registry.yaml` | Convertirlo en plantilla agnóstica completa → **requiere decisión** (ver §6) |
| RUL-D7 | T-073 ⬜ añade sección "cómo usar" a `known-web-tools.yaml` | Nombre propio "OmniRoute (Diego Souza)" → en alcance T-072 (purga); ampliación de categorías → backlog (SKL-H-07) |
| SKL-M4 | T-072 ⬜ audita `agent-registry.yaml` | Hosts `datamanager`/`oracle` como registro "universal" → ver decisión RUL-A8 |
| SKL-E-1 | T-078 ⬜ corrige la versión del README | Estructura incompleta (no cita profiles, templates, config, docs, tests, contribute.sh, check-session.sh) → backlog |
| SKL-H-11 | T-077 ⬜ cubre CI/CD e IaC en `audit-repo.sh` | Docker, frameworks de test, LICENSE, monorepos → backlog (baja) |
| SCR-M8 | T-069 ✅ (`set -euo pipefail`: un glob sin match ahora aborta en vez de continuar en silencio; verificado: sin `nullglob`) | Añadir `shopt -s nullglob` explícito → **requiere decisión** (ver §6) |
| SCR-M14 | T-069 ✅ (el `cat` del template `.gitignore` sin `[ -f ]` ahora falla ruidosamente por `set -e`; verificado línea 403) | Guardia explícita opcional; se considera mitigado |

---

## 5. Backlog propuesto — hallazgos sin tarea asignada (29)

### 5.1 Severidad alta (2)

**SKL-A5 — `parallel-orchestration.md` (instalable en todo proyecto) contiene infra personal.**
Workflow con máquina `inteligencia-colectiva`, prohibición en nodo `oracle` (`vnic-rsr`, "72% de uso en su volumen raíz"). Verificado: sigue en `main`. Ninguna tarea lo cubre (T-072 es scripts+config; T-073 es rules+skills).
*Disposición:* candidato Sprint 12 — sanitizar a plantilla (hosts/roles parametrizados vía `fleet.yaml`) o mover la versión personal al overlay. *Dependencia:* hacer junto a T-072 (misma familia de purga).

**SKL-A7 (resto) — Rutas y endpoints personales en SKILLs instalables.**
La parte de scripts va en T-072; en SKILLs sigue verificado: `coolify-admin/SKILL.md:21` (fallback `<USER_HOME>/Proyectos/configuraciones/api_keys.env`), `:23` (`https://coolify.<USER_DOMAIN>/api/v1`), `orchestrator/SKILL.md:114` (ejemplo `<PROJECT_ROOT>/Proyectos/agent-os`).
*Disposición:* candidato Sprint 12 — extender el barrido de T-072 a `.agents/skills/` (variables de entorno + placeholders). *Dependencia:* tras T-072.

### 5.2 Severidad media (14)

**RUL-S3 — Dos esquemas de perfil (`.md` vs `.yaml`) sin precedencia documentada.**
Frontmatter `.md` (`skills:`, `tooling:`, `decision_gates`) vs `.yaml` (`allowed_tools`, `allowed_hosts`, `preferred_model_tier`…): ningún documento dice qué manda ni cómo se combinan.
*Disposición:* candidato Sprint 12 (gobernanza). Relevante para T-079: un agente ciego no puede inferir qué esquema seguir.

**RUL-C4 — `maximum-autonomy.md` vs `developer.yaml` (instalar herramientas).**
"Instálala tú (si tienes permisos)" vs "prohibido instalar dependencias globales sin validación previa": el umbral no está definido. T-070 solo resolvió C1–C3.
*Disposición:* candidato Sprint 12 — definir el criterio de "validación previa" y referenciarlo en ambas.

**RUL-C5 — `response-checklist.md` omite el nivel "flota" de la jerarquía.**
El checklist dice "(OSS > Free > Premium)"; `tool-decision-flow.md` exige Flota > OSS > Free > Premium. Verificado: sigue en `response-checklist.md:12`.
*Disposición:* candidato Sprint 12 — una línea: alinear el checklist con el flow.

**RUL-S1 — `no-destructive-without-audit.md` duplica la fila L3 de `agent-permissions.md`.**
Dos fuentes de verdad para operaciones destructivas sin referencia cruzada. Verificado: `no-destructive-without-audit.md` no cita a `agent-permissions.md`.
*Disposición:* candidato Sprint 12 — declarar canónica una y cruzar la otra por nombre (patrón ya usado en T-070/C1).

**SKL-M5 — `templates/` con infraestructura personal.**
`templates/freellmapi/`, `templates/bytebox/` (fork personal `pinkpixel-dev/bytebox`), `templates/omniroute/`, `templates/homepage/glances-compose.yml:2` (comentario con `100.77.82.13 via Tailscale`, verificado). Ninguna tarea cubre `templates/`.
*Disposición:* candidato Sprint 12 — parametrizar con variables/entorno o mover al overlay personal; `install.sh`/`sync.sh` deben excluirlos o tratarlos como opcionales.

**SKL-M3 — `import-secrets.sh` resuelve Infisical contra el nodo `oracle` (líneas 98-101).**
Fallback cableado a un host personal en un script instalado en todo proyecto. T-072 no lo lista en su caja.
*Disposición:* candidato Sprint 12 — resolver vía `fleet.yaml`/variable de entorno. *Dependencia:* tras T-072 (misma familia).

**SKL-H-16 — Skills atadas a herramientas propietarias de Antigravity.**
`creador-habilidades:52` (`run_command`), `rule-creator:25` (`notify_user` con `BlockedOnUser`), `doe-framework` ("abrir Antigravity"). Verificado: siguen. En Claude Code/OpenCode no son ejecutables.
*Disposición:* candidato Sprint 12 — capa de compatibilidad ("si tu runtime es X, equivale a…") o reescritura agnóstica. Relacionado con el espíritu de T-073.

**SCR-M5 — `check-session.sh` sin `set -euo pipefail`.**
Verificado: 0 ocurrencias. Es el único script de `scripts/agent/` sin gestión de errores mínima; T-075 no lo exigió explícitamente.
*Disposición:* candidato Sprint 12 — añadir `set -euo pipefail` + pre-flights (extensión natural de T-075).

**SCR-M11 — `timeout` de GNU coreutils (inexistente en macOS por defecto).**
Verificado: sigue en `check-session.sh:77` y `sync.sh:123`; el fallo va a `2>/dev/null` (se salta la comprobación en silencio en Mac).
*Disposición:* candidato Sprint 12 — `gtimeout` si existe, o rama por OS, o eliminar el `timeout` con justificación.

**SCR-M13 — Solo 10 de 27 scripts implementan `--help` en runtime.**
El resto solo documenta uso en cabecera; `update-mvp-tracker.sh` ni siquiera tiene línea de uso.
*Disposición:* candidato Sprint 12 — añadir `--help` mínimo (una función compartida en `lib/` reduciría el coste).

**SKL-MEDIA-4 — Referencia a "Fase 2.5" inexistente.**
`session-close.md:59` verifica contra la "Fase 2.5" de `session-start.md`, que no existe (verificado).
*Disposición:* candidato Sprint 12 — corregir la referencia a la fase real.

**SKL-MEDIA-6 — Ruta errónea `./scripts/cloudflare-dns.sh` en `coolify-nextjs-deploy/SKILL.md:73`.**
En troubleshooting de emergencia (Let's Encrypt); la ruta correcta está en el propio SKILL (`:49,52`). Verificado: sigue mal.
*Disposición:* candidato Sprint 12 — corrección de una línea.

**SKL-MEDIA-8 — `external-inbox.md` rompe la convención de skills.**
Sigue siendo archivo suelto en vez de directorio con `SKILL.md` (verificado); `install.sh`/`sync.sh` mantienen ramas `elif` de excepción.
*Disposición:* candidato Sprint 12 — convertir a `external-inbox/SKILL.md` y simplificar instalador/sync.

**SKL-H-07 — `known-web-tools.yaml`: faltan categorías.**
Sin AWS/GCP/Azure, Notion, Linear, Slack, Discord, Mistral, xAI, Copilot, Cursor. T-073 solo añade la sección "cómo usar".
*Disposición:* candidato Sprint 12 (baja prioridad) — ampliar catálogo o documentar el criterio de inclusión.

### 5.3 Severidad baja (13)

| ID | Hallazgo | Disposición propuesta |
|---|---|---|
| SCR-B1 | `update-mvp-tracker.sh` sin línea `Uso:` ni `--help` | Sprint 12 — añadir cabecera (entra en el lote SCR-M13) |
| SCR-B4 | `install.sh`/`sync.sh` no validan writability del destino | Sprint 12 — pre-flight de escritura antes de copiar |
| SCR-B5 | `check-session.sh`: `git rev-parse` con `stderr` no silenciado del todo | Sprint 12 — verificar tras T-075 (el script se reestructuró con `date-utils.sh`); si persiste, corregir |
| SCR-B6 | `discover-fleet.sh` usa `which` en vez de `command -v` (3 ocurrencias, verificado) | Sprint 12 — sustitución trivial |
| SCR-B7 | `assets-manifest.txt` declara `.agents/context/agent-os-changelog.md`, inexistente en el core | Sprint 12 — corregir el manifiesto o documentar que se genera en el hijo |
| RUL-S5 | "No trabajar en main" duplicado (`strict-workflow.md` + `response-checklist.md`) | Sprint 12 — el checklist referencia por nombre en vez de repetir |
| RUL-S6 | Verificación pre-push duplicada (`deployment-safety.md` §4 vs `strict-workflow.md`) | Sprint 12 — unificar en una checklist canónica |
| SKL-H-19 | 7 skills sin "Cuándo usar" explícito (`coolify-admin`, `coolify-nextjs-deploy`, `goal-evaluation`, `infisical-secrets`, `orchestrator`, `remote-admin`, `tool-inventory`) | Sprint 12 — añadir sección (mejora la invocación correcta) |
| SKL-BAJA-1 | `AGENTS.md:111` cita `docs/external-inbox/` del core, inexistente en el clon (verificado) | Sprint 12 — documentar que lo crea `install.sh --self` o crearlo con `.gitkeep` |
| SKL-BAJA-2 | `implementar-feature-dry/SKILL.md:22` cita `.agents/rules/naming-convention.md`, inexistente (verificado) | Sprint 12 — corregir o eliminar el ejemplo |
| SKL-BAJA-5 | Código muerto en `install.sh:355` (fuzzy-match de `implemented.md` inexistente; verificado) | Sprint 12 — eliminar (una línea) |
| SKL-R-5 | Numeración de secciones rota en `orca-read-only-audit.md` | Sprint 12 — renumerar (entra en el lote T-078) |
| SKL-E-2 | `CONTRIBUTING.md` asume jerga interna sin enlaces ("token ⏳ ESPERANDO", "Fase 3.5") | Sprint 12 — enlazar a los workflows donde se definen |
| SKL-H-11 (resto) | `audit-repo.sh` no detecta Docker, tests, LICENSE ni monorepos (CI/IaC van en T-077) | Sprint 12 opcional — ampliar tras T-077 |

---

## 6. Requieren decisión del usuario (7)

1. **RUL-A8 / SKL-M4 — `config/agent-registry.yaml`: ¿plantilla agnóstica o foto de tu flota como ejemplo?**
   T-072 purga IPs/refs personales, pero el registro modela tus motores (`antigravity`, `hermes`, `orca`, `opencode`) y hosts (`datamanager`, `oracle`). Opciones: (a) convertirlo en plantilla con placeholders y mover tu registro real al overlay; (b) mantenerlo como ejemplo documentado. Recomendación: (a), coherente con el principio portable.
2. **K-H-06 — Peers Tailscale descubiertos pero no integrados.**
   `discover-fleet.sh --apply` no fusiona los peers en `nodes:` de `fleet.yaml`. ¿Debe hacerlo automáticamente, solo con flag, o documentarse como paso manual? Recomendación: documentar como manual (un descubrimiento que escribe topología de red sin confirmación es arriesgado).
3. **RUL-A11 — `ops-auditor.yaml` asume Linux + Docker + Tailscale.**
   Parcialmente justificable por el rol (auditor de infra). ¿Se documenta su scope ("solo flotas Linux/Docker") o se parametriza? Recomendación: etiquetar scope explícito en el perfil.
4. **RUL-S7 — La función "auditar" dispersa en 4 reglas** (`audit-before-refactor`, `dry-architecture`, `tool-decision-flow`, `analysis-principles`).
   ¿Vale la pena unificarlas o basta un mapa "qué regla cubre qué fase"? Recomendación: mapa breve en `AGENT_ONBOARDING.md`, no refactor grande.
5. **K-H-12 — Detección de `.env` fragmentada** (`audit-repo.sh` no lo menciona; el SKILL delega a `import-secrets.sh`).
   ¿Se documenta como limitación conocida o se unifica el reconocimiento? Recomendación: documentar; el manejo de secretos merece fricción explícita, no magia.
6. **K-BAJA-4 — Colisión de nombre: workflow `changelog.md` vs `CHANGELOG.md` del proyecto.**
   Confusión real en sistemas case-insensitive (macOS/Windows). ¿Renombrar el workflow (p. ej. `changelog-workflow.md`) o documentar? Recomendación: renombrar; barato y evita una clase entera de errores.
7. **SCR-M8 — ¿Exigir `shopt -s nullglob` en `install.sh`/`sync.sh`?**
   Con `set -euo pipefail` (T-069) un glob sin match ya aborta ruidosamente; `nullglob` lo haría silenciosamente iterable-vacío (comportamiento distinto, no necesariamente mejor en un instalador). Recomendación: no cambiar; el aborto ruidoso es la semántica correcta aquí.

## 7. Wont-fix propuesto (1)

- **SKL-BAJA-3 — Referencias rotas confinadas a tasks archivadas** (`task-023` → `docs/IMPLEMENTED.md`, etc.). Solo arqueología histórica; ningún flujo operativo las toca. Propuesta: no corregir; si molestan, una pasada de limpieza de `tasks/_archived/` algún día.

---

## 8. Propuesta de backlog Sprint 12 (priorizada)

Ordenado por impacto en la promesa portable + coste. Los 2 hallazgos altos primero; luego lotes temáticos que reutilizan el contexto de tareas del Sprint 11.

### Lote P0 — Purga extendida (familia T-072)
*Dependencia: tras T-072. Los 3 son "la purga que T-072 no cubre por su caja".*
1. **SKL-A5** — sanitizar `parallel-orchestration.md` (hosts y % disco personales) → plantilla con `fleet.yaml`.
2. **SKL-A7-resto** — extender el barrido a `.agents/skills/` (`coolify-admin`, `orchestrator`): rutas personales y dominio Coolify → env vars/placeholders.
3. **SKL-M5** — `templates/` personales (`freellmapi`, `homepage`, `bytebox`, `omniroute`): parametrizar o mover al overlay; decidir qué instala `install.sh` por defecto.
4. **SKL-M3** — `import-secrets.sh`: nodo `oracle` cableado → resolución vía `fleet.yaml`/env.

### Lote P1 — Gobernanza (familia T-070)
*Sin dependencias entre ellos; idealmente antes de T-079 si el sprint se alarga, si no, Sprint 12.*
5. **RUL-S3** — documentar precedencia `.md` vs `.yaml` en perfiles.
6. **RUL-C4** — definir "validación previa" para instalar herramientas (`maximum-autonomy` vs `developer.yaml`).
7. **RUL-C5** — alinear `response-checklist.md` con la jerarquía Flota > OSS > Free > Premium.
8. **RUL-S1** — una sola fuente de verdad para operaciones destructivas (cross-ref por nombre).

### Lote P2 — Detección honesta (familia T-074/T-077)
*Dependencia: tras T-077 para no pisar su trabajo.*
9. **SKL-H-07** — ampliar `known-web-tools.yaml` (consolas cloud, IDEs agnósticos) o documentar criterio de inclusión.
10. **SKL-H-11-resto** — `audit-repo.sh`: Docker, tests, LICENSE, monorepos.

### Lote P3 — Portabilidad shell (familia T-075)
*Sin dependencias; lote mecánico de bajo riesgo.*
11. **SCR-M5** — `set -euo pipefail` + pre-flights en `check-session.sh`.
12. **SCR-M11** — sustituir `timeout` GNU (2 ocurrencias) por alternativa portable.
13. **SCR-B6** — `which` → `command -v` en `discover-fleet.sh`.

### Lote P4 — DX y docs (familia T-071/T-078)
*Sin dependencias salvo SKL-E-1-resto tras T-078.*
14. **SCR-M13 + SCR-B1** — `--help` en runtime para los 17 scripts sin él (función compartida en `lib/`).
15. **SKL-MEDIA-8** — `external-inbox.md` → directorio `external-inbox/SKILL.md`; simplificar ramas `elif` en instalador/sync.
16. **SKL-H-19** — sección "Cuándo usar" en las 7 skills sin criterios de activación.
17. **SKL-H-16** — capa de compatibilidad para antigravity-isms en skills.
18. **SKL-E-1-resto** — README: estructura completa del repo (tras T-078).
19. **Limpieza menor** (una pasada): SKL-MEDIA-4, SKL-MEDIA-6, SKL-BAJA-1, SKL-BAJA-2, SKL-BAJA-5, SKL-R-5, SKL-E-2, SCR-B4, SCR-B7, RUL-S5, RUL-S6, SCR-B5 (verificar).

### Decisiones (§6) como entrada del Sprint 12
Las decisiones 1–7 deben resolverse antes de planificar: la 1 condiciona el Lote P0; la 6 es independiente y barata (hacerla ya si se aprueba).

---

## 9. Notas de trazabilidad

- Informes fuente: `~/workspace/audits/agent-os/AUDITORIA.md`, `findings-scripts.md`, `findings-rules-profiles-config.md`, `findings-skills-workflows-docs.md` (+ detalle en `work/sec1-4-*.md`).
- Sprint: `docs/sprints/sprint-11-core.md` (mapa de cobertura) y `.agents/tasks/task-067.md`…`task-079.md` en `main` @ `b1ba4ae`.
- Verificaciones propias sobre el clon: grep de rutas personales en `scripts/` → 0 (T-069 ✅); `timeout` persiste en `check-session.sh:77` y `sync.sh:123`; `which` persiste en `discover-fleet.sh:106,149,226`; 0 skills fantasma en perfiles/reglas salvo el valor controlado `trigger: idea-capture` (T-070, intencional); `coordinator.yaml` sin `whatsapp-bridge`/`rag-query`/`coolify-mcp`; `install.sh`/`sync.sh` con bit `+x` (100755); `discover-fleet.sh` cubre `/home` y `/Users`; `parallel-orchestration.md`, `coolify-admin/SKILL.md`, `orchestrator/SKILL.md`, `templates/homepage/glances-compose.yml` aún con datos personales; `response-checklist.md:12` aún sin nivel "flota"; `session-close.md:59` aún cita "Fase 2.5"; `fleet.example.yaml:76` aún `label: "DataManager (Susana)"` (pendiente T-072).
