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
Sincroniza y propaga las reglas globales, scripts y habilidades desde el núcleo de Agent OS hacia el proyecto destino.

- **Cuándo usar**: Cuando se actualizan reglas o scripts globales en el core y se desea propagar el cambio a los satélites, o tras promover una mejora con `contribute.sh`.
- **Modos de ejecución**:
  1. **Modo Local (por defecto)**:
     Sincroniza desde el directorio del core en disco hacia el satélite:
     ```bash
     bash scripts/agent/sync.sh /ruta/al/proyecto-destino
     ```
  2. **Modo Remoto (`--remote`)**:
     Sincroniza directamente desde GitHub sin requerir tener el repositorio del core clonado en la máquina (ideal para agentes trabajando en satélites autónomos):
     ```bash
     # Sincronizar el satélite actual desde origin/main de GitHub:
     bash scripts/agent/sync.sh --remote
     
     # Sincronizar un tag o rama específica:
     bash scripts/agent/sync.sh --remote --tag=v1.12.0
     ```
     *(Descarga efímeramente el núcleo en `/tmp` con limpieza determinista mediante `trap` al finalizar).*

- **Opciones útiles**:
  - `--dry-run`: Simula la sincronización y lista diferencias sin escribir en disco.
  - `--force`: Sobrescribe archivos gestionados sin confirmación interactiva (recomendado para agentes).
  - `--commit`: Crea un commit local atómico en el satélite conteniendo **únicamente** los archivos gestionados por Agent OS.

> [!WARNING]
> **PRESERVACIÓN Y SEGURIDAD**
> Por defecto, `sync.sh` preserva archivos modificados localmente (`diferir`) a menos que se use `--force`.
> **Medidas de mitigación**:
> - Revisa siempre `git diff` en el proyecto destino tras sincronizar o ejecuta con `--dry-run` primero.
> - Si hiciste una mejora en una regla o script en un satélite y quieres conservarla globalmente, utiliza `contribute.sh` **antes** de sincronizar con `--force`.

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
