# Research y Prospección Tecnológica — Sprint 23

> **Documento de Respaldo Scout (Fase 2d / 2e del Sprint Planning)**  
> **Tema**: Revisor Ejecutor con Orca ADE, Arbitraje Multi-Nivel y Verificación Autónoma  
> **Herramienta determinista de prospección**: `scripts/agent/scout.sh` (coste $0 de inferencia).  
> **Fecha de ejecución**: 2026-10-29

---

## Metodología y Ejecución de Búsquedas Scout

Se ejecutaron consultas deterministas sobre el ecosistema open source (GitHub, NPM Registry y Hacker News) mediante `scripts/agent/scout.sh`:
1. `cli client orca wrapper bash`
2. `agent review prompt schema json`
3. `deliberation fallback cascade timeout`
4. `mock test harness agent integration`

---

## Descubrimientos Scout (por tarea)

### T-133: Cliente Unificado `lib/orca-client.sh` (Abstracción CLI Portable)

- **Alternativas detectadas**:
  - `@orca-so/whirlpools-client` (v7.0.0, NPM): Cliente TypeScript para protocolos DeFi (resultado homónimo sin relación con el runtime ADE).
  - `@orca-so/whirlpools` (v8.0.1, NPM): SDK de alto nivel homónimo ajeno a la orquestación.
- **Recomendación del agente**: Construir. Desarrollar una biblioteca POSIX modular `scripts/agent/lib/orca-client.sh` que centralice la detección determinista del ejecutable `orca-ide` (priorizando `PATH`, descartando binarios conflictivos como `/usr/bin/orca` de GNOME y prohibiendo rutas hardcodeadas personales como `<home-usuario>`), unificando la lógica duplicada en `orca-orchestrate.sh` y `dispatch-satellite.sh`.
- **Decisión vigente**: Construcción interna en Bash nativo a coste $0. Permite unificar `orca_status()`, `orca_worker_start()`, `orca_worker_read()` y `orca_worker_release()` sin acoplamientos ni dependencias de Node en el coordinador.
- **Notas de integración**: Se auditan los bloques existentes en `scripts/agent/orca-orchestrate.sh` y `scripts/agent/dispatch-satellite.sh` para reutilizar contratos de status y JSON, consumiendo la nueva biblioteca compartida.
- **Alternativas rechazadas y motivos**:
  - `@orca-so/whirlpools-client`: Rechazado. Paquete cripto/DeFi sin relación con Orca ADE.
  - Dependencia de SDK Node.js: Rechazado. Introduce overhead de runtime y dependencias NPM en el plano de control central que opera en Bash/POSIX universal.

---

### T-134: Especificación Inyectable de Revisor Ejecutor Derivada de Perfiles

- **Alternativas detectadas**:
  - `zod-to-json-schema` (v3.25.2, NPM): Generador de esquemas JSON a partir de validadores TypeScript Zod.
  - `@earendil-works/pi-coding-agent` (v1.4.0, NPM): Agente de codificación CLI con herramientas de ejecución y sesión.
- **Recomendación del agente**: Construir. Diseñar un compilador/generador determinista a $0 tokens que lea `.agents/profiles/qa-judge.md` y `.agents/profiles/reviewer.yaml` para producir la especificación (`--spec`) inyectable en `worker-start`, sin duplicar definiciones de contrato ni mantener textos desincronizados.
- **Decisión vigente**: Construcción interna en script helper/biblioteca. Inyecta el rol `qa-judge` con límites Ralph Loop (zero code generation, prohibición de commit/push) y schema de veredicto JSON estricto (`VERIFIED`, `REJECTED`, `ESCALATED_TO_HUMAN`).
- **Notas de integración**: La especificación se inyecta limpiamente a través de `orca-client.sh` hacia `orca-ide orchestration worker-start --spec ...`.
- **Alternativas rechazadas y motivos**:
  - `zod-to-json-schema`: Rechazado. Añade dependencias de transpilación TypeScript para una directiva que se genera a partir de Markdown/YAML nativo del core.
  - Hardcodeo de prompts en bash: Rechazado. Viola la regla de Única Fuente de Verdad (SSOT) al duplicar lo estipulado en `.agents/profiles/`.

---

### T-135: Refactor de Deliberación Multi-Nivel en `deliberate-plan.sh`

- **Alternativas detectadas**:
  - `@csstools/postcss-cascade-layers` (v6.0.2, NPM) y `@csstools/cascade-layer-name-parser` (v3.0.2, NPM): Paquetes CSS homónimos espurios.
- **Recomendación del agente**: Construir. Enriquecer `scripts/agent/deliberate-plan.sh` para adoptar una arquitectura de 3 niveles: (1) Revisor ejecutor autónomo vía Orca ADE (si runtime está activo y alcanzable); (2) Cascada HTTP resiliente (`freellmapi` → `omniroute` → `ollama-local`) como fallback; (3) Fallback seguro a `SIN_REVISOR` ($0).
- **Decisión vigente**: Construcción interna. Se define y justifica el modelo de timeout con latencia peor caso de ~21s (<1s sonda Orca + hasta 15s ejecución worker Orca + 5s cascada HTTP), garantizando degradación limpia y sin bloqueo a `SIN_REVISOR`. Se formaliza la inclusión de `.agents/config/routing-policy.yaml` en la caja de archivos para parametrizar `orca_revisor`.
- **Notas de integración**: Se preservan los invariantes de `routing-policy.yaml` y la redacción obligatoria de secretos con `lib/redact.sh`.
- **Alternativas rechazadas y motivos**:
  - Sustitución total de HTTP por Orca: Rechazado explícitamente por el operador. Orca complementa y lidera la revisión como ejecutor local, pero la cascada HTTP remota (`freellmapi` → `omniroute` → `ollama-local`) es imprescindible para hosts sin ADE.
  - Bloqueo indefinido por worker: Rechazado. El coordinador debe aplicar timeout estricto de 15s al worker para evitar colgar la sesión de desarrollo.
  - Proxies/middlewares externos (LiteLLM/OpenRouter): Rechazados en Sprint 22; el core gestiona su propia cascada HTTP determinista a coste $0.

---

### T-136: Check 37 en Validate Control Plane (Certificación E2E y Denominador 36→37)

- **Alternativas detectadas**:
  - `mockttp` (v4.6.5, NPM): Servidor HTTP mock para interceptación y stubbing.
  - `@a5c-ai/adapters-harness-mock` (v6.0.0, NPM): Simulador mock de arnés agéntico para Claude Code y Codex.
  - `ignashev/tequipy` (0⭐, GitHub): Evaluador agéntico con mocks para integración.
- **Recomendación del agente**: Construir. Integrar el Check 37 en `tests/validate-control-plane.sh` con simulación offline genérica (mock determinista sin red) del ciclo Orca, cero secretos en argv y actualización atómica del denominador de 36 a 37.
- **Decisión vigente**: Construcción nativa en Bash. Garantiza que la suite verifique la resolución portable del binario, la inyección de spec aislada con `env -i`, la cascada de 3 niveles y el veredicto sin dependencias externas.
- **Notas de integración**: Limpieza rigurosa de fixtures en `/tmp` con `trap` y aserción de árbol de trabajo 100% limpio.
- **Alternativas rechazadas y motivos**:
  - `mockttp` / `@a5c-ai/adapters-harness-mock`: Rechazados. Imponen runtime de Node y paquetes externos pesados para una prueba de control plane que debe ejecutarse en cualquier entorno POSIX mínimo.
