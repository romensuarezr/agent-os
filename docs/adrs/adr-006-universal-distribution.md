# ADR 006: Distribución Universal del Core como Sistema Operativo de Agentes

**Estado:** Accepted  
**Fecha:** 2026-09-30  
**Contexto:** Sprint 13 — Core (T-087: Distribución universal del Core y ciclo de vida de satélites)  

## Contexto

El ecosistema de herramientas para agentes de IA tiende a fragmentarse en gestores de utilidades o catálogos de habilidades aisladas (como paquetes npm tipo `npx skills add`, MCPs sueltos o repositorios de extensiones). Si bien este enfoque facilita la adición puntual de funciones ("buscar en la web", "conectar a una base de datos"), adolece de una limitación crítica: **carece de gobernanza, topología de flota, ciclo de vida de tareas y control determinista**.

En repositorios de producción reales (como se evidenció en la prueba empírica del Sprint 12 sobre `romensuarez-web`), un agente no necesita únicamente un catálogo de habilidades desconectadas; requiere un entorno operativo estructurado:
1. **Contrato de sesión y bloqueo atómico** (`.agent-session.lock`, `session-start`, `session-close`) para evitar carreras y corrupciones en repositorios multi-agente o trabajo humano-IA.
2. **Gobernanza y trazabilidad de sprints** (`docs/sprints/`, `docs/adrs/`, `mvp-tracker`, `check-sprint.sh`, `close-task.sh`).
3. **Flota federada y enrutamiento inteligente de modelos** (`.agents/config/fleet.yaml`, `routing-policy.yaml`, `fleet-doctor.sh`).
4. **Reglas de contención arquitectónica** (`.agents/rules/`: principios DRY, firewall anti-destructivo, modularidad).
5. **Perfiles especializados y roles** (`.agents/profiles/`: coordinator, coder, reviewer, qa-judge).
6. **Workflows estandarizados** (`.agents/workflows/`).
7. **Salud y auditoría continua de satélites** (`audit-child.sh`).

Reducir Agent OS a un instalador de plugins o habilidades atomizadas diluye su propuesta de valor fundamental y fragmenta la experiencia de desarrollo asistido.

## Decisión

Adoptar y estandarizar la **distribución universal del Core como un Sistema Operativo completo e integral para Agentes**, transportado mediante un mecanismo de instalación desatendido, reejecutable e idempotente (one-liner pineado a tags de release).

### Componentes Clave

1. **Distribución Holística (No Atomizada)**:
   El instalador despliega toda la arquitectura de Agent OS en el proyecto destino (`.agents/rules/`, `.agents/workflows/`, `.agents/profiles/`, `.agents/skills/`, `.agents/config/`, `scripts/agent/`, `docs/sprints/`, `docs/adrs/`). No se permite la instalación descontextualizada de skills sin su correspondiente capa de control y reglas.
2. **Pinchado Estricto a Release Tags**:
   El comando de distribución (`one-liner`) se pinea formalmente a un tag inmutable de release (`https://raw.githubusercontent.com/romensuarezr/agent-os/vX.Y.Z/scripts/agent/install.sh`), consumiendo `VERSION` como fuente de verdad canónica. Queda terminantemente prohibido enlazar a ramas flotantes (`main`) o punteros móviles (`latest`) para garantizar el determinismo y la reproducibilidad en CI/CD y despliegues satélites.
3. **Aprovisionamiento Efímero Autónomo**:
   Cuando `install.sh` se ejecuta canalizado vía red (`curl -fsSL ... | bash`), detecta la ausencia de assets locales, crea un directorio temporal aislado (`mktemp -d`), clona/descarga el core pineado al tag, ejecuta la instalación y limpia deterministamente sus recursos mediante trampas POSIX (`trap`).
4. **Idempotencia Defensiva (`mv-no-rm`)**:
   Reejecutar el instalador en un proyecto satélite que ya posee personalizaciones locales (onboarding adaptado, variables de entorno, configuraciones de flota locales) no sobreescribe ni destruye jamás el estado del usuario; preserva archivos existentes y actualiza únicamente los assets globales del core.

## Consecuencias

### Positivas (Pros)
* **Preservación del Diferencial Competitivo**: Cualquier repositorio satélite adquiere inmediatamente toda la disciplina de ingeniería de software de Agent OS (gobernanza, roles, auditoría, sincronización y testing), no meros atajos de prompt.
* **Determinismo e Inmutabilidad**: Al pinear a release tags, dos ejecuciones en momentos distintos garantizan exactamente el mismo estado operativo en el hijo.
* **Cero Fricción de Adopción**: Un único comando (`curl ... | bash -s -- .`) equipa cualquier repositorio en segundos sin necesidad de clonar previamente el núcleo a mano.
* **Ciclo de Vida Unificado**: Los satélites pueden auditarse contra la versión del núcleo instalada y sincronizarse ordenadamente mediante `sync.sh` y `audit-child.sh`.

### Negativas (Cons)
* **Huella Inicial Mayor**: Instala un árbol completo de directorios (`.agents/`, `scripts/agent/`, `docs/`) en lugar de añadir un único archivo de skill.
* **Mayor Responsabilidad en Mantenimiento**: Cada actualización del core debe velar por la compatibilidad retroactiva de todos los subsistemas (scripts, reglas, perfiles).

### Riesgos y Mitigaciones
* **Riesgo**: Colisión de configuraciones o rutas con frameworks del proyecto hijo (ej. Rails/Laravel con `config/`).
  * **Mitigación**: Namespacing estricto en `.agents/config/` (completado en T-085).
* **Riesgo**: Fallos de red o caídas de GitHub durante la ejecución del one-liner.
  * **Mitigación**: `install.sh` implementa pre-flights bloqueantes, verificación de integridad y limpieza automática (`trap`) en caso de interrupción.

## Referencias
* ADR-001: Core sin dependencias y auto-hospedaje (Self-Hosting)
* ADR-004: Control Plane 24/7 y Federación de Repositorios
* Sprint 13 Core: T-085 (Namespacing) y T-087 (Distribución Universal)
