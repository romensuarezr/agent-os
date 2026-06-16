# ADR 002: Detección universal de stack desacoplada

**Estado:** Accepted  
**Fecha:** 2026-06-16  
**Contexto:** Sprint 02 — Core  

## Contexto
En las primeras versiones del core, los scripts de análisis y empaquetado (como `inventory-check.sh` y `generate-digest.sh`) asumían de forma rígida un stack de Node.js/TypeScript. Al utilizar Agent OS en proyectos desarrollados en Python, Go o con arquitecturas híbridas, los scripts fallaban al buscar dependencias inexistentes o ignoraban archivos relevantes. Necesitábamos una forma dinámica de identificar el stack del repositorio cliente sin acoplar el código del core a frameworks específicos.

## Decisión
1. Crear una biblioteca de detección centralizada en `scripts/agent/lib/detect-stack.sh` que analice la presencia de archivos clave (`package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, etc.) y exporte el stack detectado, las extensiones principales y los patrones de exclusión.
2. Implementar un mecanismo de anulación manual a través del archivo de configuración opcional `.agents/context/stack.env`. Si este archivo existe, los scripts ignoran la detección automática y cargan directamente las definiciones del usuario.
3. Adaptar todos los scripts del ciclo de vida para consumir esta biblioteca y ajustar sus búsquedas y validaciones de forma dinámica en base al stack activo.

### Componentes Clave
1. `scripts/agent/lib/detect-stack.sh`: Lógica de auto-detección y carga de overrides.
2. `.agents/context/stack.env`: Archivo opcional para forzar un stack determinado.
3. `scripts/agent/generate-digest.sh`: Adaptado para indexar código basándose en el stack dinámico.

## Consecuencias

### Positivas (Pros)
* **Compatibilidad multi-stack**: Permite que las mismas herramientas de sesión y auditoría funcionen en proyectos Python, Node, Go o Vanilla HTML/JS.
* **DRY (Don't Repeat Yourself)**: La lógica de inspección del entorno se escribe una sola vez en `detect-stack.sh` en lugar de estar duplicada en cada script de utilidad.
* **Flexibilidad**: La configuración manual en `stack.env` resuelve cualquier ambigüedad en monorepos o proyectos híbridos.

### Negativas (Cons)
* **Soporte inicial limitado**: La detección automática cubre los stacks principales (TypeScript, JavaScript, Python) pero requiere ampliar la lógica para nuevos lenguajes.
* **Manejo de variables de entorno**: La importación de variables mediante `source` en Bash puede colisionar con variables de entorno del sistema si no se limpian o nombran con namespaces correctos.

### Riesgos y Mitigaciones
* **Falsos positivos en monorepos complejos**: *Probabilidad: Alta* -> *Mitigación*: Priorizar siempre la existencia de `.agents/context/stack.env` sobre la auto-detección, permitiendo al desarrollador/agente declarar el stack explícitamente en el onboarding.

## Referencias
* [changelog.md](file:///home/romen/Proyectos/agent-os/changelog.md#L5-L15)
* [scripts/agent/lib/detect-stack.sh](file:///home/romen/Proyectos/agent-os/scripts/agent/lib/detect-stack.sh)
