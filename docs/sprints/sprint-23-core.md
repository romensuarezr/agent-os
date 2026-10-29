# Sprint 23 — Revisor Ejecutor con Orca ADE, Arbitraje Multi-Nivel y Verificación Autónoma

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-133 | Cliente Unificado `lib/orca-client.sh` y Detección Portable de Runtime (`orca-ide`) | Nueva herramienta / Core | S | ✅ Completada | — | [.agents/tasks/task-133.md](.agents/tasks/_archived/task-133.md) |
| T-134 | Especificación Inyectable de Revisor Ejecutor Derivada de `qa-judge.md` y `reviewer.yaml` | DX / Workflow | S | ⬜ Pendiente | — | [.agents/tasks/task-134.md](.agents/tasks/task-134.md) |
| T-135 | Refactor de `deliberate-plan.sh` (Orca Prioritario, Fallback a Cascada HTTP y Degradación Segura) | Core / Deliberación | M | ⬜ Pendiente | T-133, T-134 | [.agents/tasks/task-135.md](.agents/tasks/task-135.md) |
| T-136 | Check 37 en `validate-control-plane.sh` (Certificación E2E de Revisor Ejecutor y Denominador 36→37) | DX / Tests | M | ⬜ Pendiente | T-133, T-134, T-135 | [.agents/tasks/task-136.md](.agents/tasks/task-136.md) |

## Notas de planning

- **Objetivo Estratégico**: Evolucionar el motor de deliberación determinista de Agent OS integrando **Orca ADE** como Revisor Ejecutor autónomo local de primer nivel, manteniendo estricta interoperabilidad y resiliencia: si Orca no está disponible o falla, el sistema se degrada ordenadamente a la cascada de inferencia HTTP de 3 tiers (`freellmapi` → `omniroute` → `ollama-local`), y si esta última no responde, a `SIN_REVISOR` ($0 tokens). En ningún caso Orca sustituye completamente a la cascada HTTP, garantizando la portabilidad del core en entornos headless o servidores sin ADE.
- **Guardarraíles Operativos (Mandatorios)**:
  1. **Aislamiento de Entorno del Worker**: Todo despacho de worker vía Orca CLI debe ejecutarse con una whitelist estricta (`env -i HOME="$HOME" PATH="$PATH" ...`), impidiendo la propagación de tokens comerciales o credenciales de la sesión del coordinador al entorno del worker.
  2. **Cero Bloqueos y Resiliencia**: El bucle de arbitraje no puede quedar colgado indefinidamente. La detección de presencia de Orca debe ser inmediata (<1s) y el tiempo concedido a la deliberación debe estar acotado con timeout claro antes del fallback automático.
  3. **Higiene de Secretos**: Ningún reporte, digest, log o argumento CLI en argv contendrá valores de secretos o rutas personales absolutas (`<home-usuario>` queda terminantemente prohibido).
- **Modelo de Timeout y Latencia Peor Caso (~21s)**:
  - **Nivel 1 (Orca ADE)**:
    - Sonda determinista de presencia (`orca_status`): acotada a **<1 segundo** (fail-fast si el socket o runtime no responde).
    - Ejecución del worker Revisor: presupuesto de **hasta 15 segundos** (para revisión del plan, ejecución de tests y emisión del JSON de veredicto).
  - **Nivel 2 (Cascada HTTP)**:
    - Si Orca falla, agota su tiempo o no está en ejecución, se activa la cascada HTTP declarativa en `routing-policy.yaml` (`freellmapi` → `omniroute` → `ollama-local`) con su presupuesto global de **5 segundos**.
  - **Nivel 3 (Degradación Segura)**:
    - Si la cascada HTTP se agota o está inaccesible: fallback instantáneo a **`SIN_REVISOR` ($0)**.
  - **Latencia total peor caso**: **~21 segundos** (<1s sonda + 15s worker Orca + 5s cascada HTTP), garantizando la no-interrupción del flujo del operador ante caídas encadenadas.
- **Caja de Archivos Decidida para `routing-policy.yaml`**:
  - `routing-policy.yaml` queda formalmente incluido en la caja autorizada de T-135 para declarar la configuración del revisor local (`orca_revisor: { enabled: true, timeout_seconds: 15 }`) junto a la cascada existente `fallback_cascade: [freellmapi, omniroute, ollama-local]`.
- **Dogfooding Deliberativo**: Sometido al proceso formal de deliberación previo a la aprobación.
