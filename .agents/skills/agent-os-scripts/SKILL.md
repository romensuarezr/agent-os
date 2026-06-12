---
name: agent-os-scripts
description: Guía de uso de los scripts del núcleo de Agent OS (install.sh, sync.sh y contribute.sh).
---

# Agent OS Scripts (Mantenimiento de Entorno)

Esta habilidad proporciona el conocimiento para operar las herramientas de automatización y sincronización de Agent OS entre el repositorio global y los proyectos de destino.

## Los Scripts Principales

### 1. `install.sh`
Se utiliza para **inicializar Agent OS** en un proyecto nuevo.
- **Cuándo usar**: Solo una vez por proyecto nuevo, durante la fase de onboarding.
- **Cómo usar**:
  Desde la carpeta raíz de `agent-os` (donde reside el script de instalación en `scripts/agent/install.sh`), ejecuta:
  ```bash
  ./scripts/agent/install.sh /ruta/al/proyecto-destino
  ```
- **Qué hace**:
  1. Crea la estructura de directorios del agente (`.agents/rules/`, `.agents/workflows/`, `.agents/skills/`, `scripts/agent/`).
  2. Crea las carpetas de documentación (`docs/sprints/`, `docs/adrs/`, `docs/idea-inbox/`, `docs/external-inbox/`).
  3. Copia las reglas globales, workflows, habilidades y templates sin sobreescribir los archivos locales preexistentes (usa `-n` / `-rn`).

### 2. `sync.sh`
Sincroniza y propaga las reglas globales y los scripts del agente desde `agent-os` hacia el proyecto destino.
- **Cuándo usar**: Cuando se actualizan reglas globales en `agent-os` y se desea propagar el cambio a los proyectos de destino, o tras promover una regla.
- **Cómo usar**:
  ```bash
  ./scripts/agent/sync.sh /ruta/al/proyecto-destino
  ```

> [!WARNING]
> **ADVERTENCIA DE PODER DESTRUCTIVO**
> El script `sync.sh` **sobrescribe de forma agresiva y por completo** las reglas globales y scripts del agente en el proyecto destino con las versiones globales del repositorio `agent-os`. Cualquier cambio local hecho manualmente a estos archivos en el proyecto de destino se perderá de forma permanente.
> **Medidas de mitigación**:
> - Revisa siempre `git diff` en el proyecto destino tras sincronizar.
> - Si hiciste una mejora en una regla en un proyecto de destino y quieres conservarla globalmente, utiliza `contribute.sh` **antes** de hacer un `sync.sh`.

### 3. `contribute.sh`
Promoción inversa. Envía una regla, workflow o skill desarrollada localmente en un proyecto de destino de vuelta al repositorio central `agent-os`.
- **Cuándo usar**: Cuando has creado o mejorado una regla, flujo o habilidad en un proyecto local y quieres hacerla global para que otros proyectos puedan consumirla.
- **Cómo usar**:
  ```bash
  ./scripts/agent/contribute.sh /ruta/del/proyecto nombre-archivo.md [--workflow|--skill]
  ```
  *(Si no se especifica el flag `--workflow` o `--skill`, por defecto asume que es una regla).*
- **Qué hace**:
  1. Copia el archivo del proyecto local a la carpeta correspondiente en `agent-os`.
  2. Ejecuta un commit automático en el repositorio de `agent-os` con el mensaje: `feat: promote [archivo] ([tipo]) from [proyecto]`.

---

## Flujo de Onboarding para Proyectos Nuevos

Cuando se comienza a trabajar en un nuevo proyecto que consumirá Agent OS, se debe seguir estrictamente este protocolo:

1. **Instalación**:
   Ejecutar `./install.sh /ruta/al/proyecto`.
2. **Crear Configuración Inicial**:
   Configurar el archivo `.agents/AGENT_ONBOARDING.md` en el proyecto destino. Este archivo define:
   - La arquitectura de software del proyecto.
   - El Stack Tecnológico y dependencias de testing/despliegue.
   - Las reglas y flujos de trabajo particulares de ese codebase.
3. **Sincronización Inicial**:
   Ejecutar `./sync.sh /ruta/al/proyecto` para asegurar que todas las reglas globales y scripts estén en su última versión activa.
