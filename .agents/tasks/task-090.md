# Task-090: Prueba ciega 0-contexto de distribución e instalación desatendida en repo efímero

## Objetivo
Ejecutar la validación ciega de ciclo de vida completo de Agent OS en un repositorio satélite efímero e independiente: un harness de prueba determinista (`tests/test-blind-distribution.sh`) y un experimento con sujeto ciego real (agente en sesión fresca sin contexto previo del core, recibiendo únicamente un repositorio virgen y el comando de instalación), midiendo el descubrimiento espontáneo del pre-flight de onboarding (`audit-child.sh`), la llegada al estado `✅ CONFORME` y capturando el transcript de dudas y tropiezos como evidencia central de calidad de distribución.

## Contexto técnico y Dependencias
- **Prerrequisitos**: `T-087` (one-liner / distribución universal), `T-088` (auditoría `audit-child.sh` y ledger) y `T-089` (`setup-profiles.sh`).
- **Los 5 Hitos Canónicos del Harness Determinista**:
  1. **Aprovisionamiento Efímero**: Creación de un proyecto satélite realista limpio (ej. TypeScript con `package.json`, `tsconfig.json` y git inicializado) fuera del core (`mktemp -d`).
  2. **Instalación Desatendida**: Despliegue mediante el instalador universal (`install.sh`), verificando el diferencial completo de Agent OS y la generación atómica del ledger enriquecido (`.agents/context/last-sync.md`).
  3. **Ciclo de Onboarding y Salud (Corregido)**:
     - Auditoría inicial con `audit-child.sh` devuelve `⚠️  DRIFT DETECTADO` (comportamiento esperado: la plantilla `AGENT_ONBOARDING.md` está recién instalada y sin personalizar).
     - Personalización del onboarding (sustitución de marcadores genéricos).
     - Re-ejecución de `audit-child.sh` alcanza `✅ CONFORME` (exit code 0).
  4. **Setup Determinista de Perfiles**: Ejecución de `bash scripts/agent/setup-profiles.sh --apply`, inyectando el bloque regenerable delimitado por `# BEGIN AGENT-OS-GENERATED-STACK` y `# END AGENT-OS-GENERATED-STACK`.
  5. **Re-auditoría Final y Limpieza Hermética**: Re-ejecución de `audit-child.sh` ratificando `✅ CONFORME` y limpieza determinista de residuos vía `trap EXIT` (0 fugas en `/tmp`).
- **Fase Ciega con Sujeto Real (Subagente Fresco)**:
  - Se aprovisiona un workspace efímero con un proyecto nuevo.
  - Se invoca a un subagente con **cero contexto previo de agent-os**, dándole únicamente la instrucción de instalar Agent OS y seguir el onboarding del repositorio para dejarlo operativo.
  - Se mide explícitamente:
    - ¿Descubrió y ejecutó espontáneamente `audit-child.sh` desde el pre-flight del onboarding sin que se le ordenara? (Sí/No).
    - ¿Qué dudas, ambigüedades o tropiezos encontró en el camino? (Transcript analizado como evidencia).

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-13-core.md`
- `.agents/tasks/task-090.md`
- `tests/test-blind-distribution.sh`

## Criterios de done
- [x] Harness determinista `tests/test-blind-distribution.sh` implementado cubriendo los 5 hitos con el flujo corregido de onboarding.
- [x] Ejecución del harness automatizado: 5/5 hitos superados con éxito en entorno efímero aislado (8/8 aserciones PASS).
- [x] Fase ciega ejecutada con un subagente independiente a cero contexto previo sobre repositorio virgen (`/tmp/agent-os-blind-subject`).
- [x] Medición documentada del descubrimiento del trigger: comprobación de si ejecutó espontáneamente `audit-child.sh` (**SÍ**, detonado por directiva en cabecera de `AGENT_ONBOARDING.md`).
- [x] Transcript de dudas, tropiezos y resoluciones del sujeto ciego documentado en la evidencia de la tarea.
- [x] `tests/validate-control-plane.sh` permanece en 12/12 PASS sin regresiones.

## Evidencia Empírica de la Fase Ciega (Sujeto Ciego)
- **Descubrimiento espontáneo del trigger (`audit-child.sh`)**: **SÍ**.
  - Evidencia transcript: *"Directiva explícita en la cabecera de `.agents/AGENT_ONBOARDING.md`: '## 🩺 Pre-flight de Inicio de Sesión (Salud del Repositorio) — Antes de iniciar cualquier tarea o planificar trabajo, ejecuta la auditoría de salud local de Agent OS: bash scripts/agent/audit-child.sh'"*.
- **Ciclo de salud**:
  - Auditoría inicial post-instalación: detectó `⚠️ DRIFT DETECTADO` por plantilla de onboarding con placeholders.
  - Personalización de `AGENT_ONBOARDING.md`: completó el stack real de `my-saas-app` (Node.js/JavaScript, `npm run dev`, `npm test`).
  - Re-auditoría: alcanzó `✅ CONFORME` (6 de 6 checks superados).
- **Tropiezos documentados para el backlog futuro**:
  1. Firma CLI: `audit-child.sh` soporta `--path`, mientras que `audit-repo.sh` asume `git rev-parse --show-toplevel`.
  2. Roadmap mismatch: plantilla inicial (`## En curso`, `## Próximo`) vs expectativas estrictas de `audit-repo.sh` (`## En progreso`, `## Backlog`).
  3. Estado de working tree tras `install.sh`: archivos quedan untracked y generan duda sobre cuándo commitear.
  4. Portabilidad de `cp -n` en Linux: avisos `cp: warning: behavior of -n is non-portable`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-30T09:55:00+01:00
- [x] Rama creada: feat/T-090-blind-install-test
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
