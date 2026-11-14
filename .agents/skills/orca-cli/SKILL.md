---
name: orca-cli
description: Operar worktrees gestionados por Orca, contextos de carpetas, terminales aisladas y navegador embebido a través de la CLI `orca-ide` / `orca` (v1.4.258).
---

# 🐋 Orca CLI (Gestión de Worktrees y Entornos Aislados)

Esta habilidad proporciona el protocolo operativo para interactuar con **Orca IDE** (v1.4.258) a través de su interfaz de línea de comandos. Permite gestionar worktrees git efímeros, terminales PTY independientes, contextos de directorios y automatizaciones sin colisiones en el sistema anfitrión.

## Cuándo usar
- Cuando una tarea requiera crear o inspeccionar un `child worktree` gestionado por Orca.
- Para spawnear agentes independientes (`codex`, `claude`, subagentes) en terminales aisladas de Orca.
- Para controlar o interactuar con el navegador embebido de Orca sin requerir Computer Use invasivo.
- Cuando el usuario mencione `$orca-cli`, "Orca worktree" o "handoff a otro agente en worktree".

---

## ⚡ Resolución del Ejecutable en el Host (Prevención de Colisión)

> ⚠️ **REGLA CRÍTICA EN LINUX**:
> En distribuciones Linux, **NUNCA ejecutes `orca` directamente fuera de un terminal gestionado por Orca**.
> El comando del sistema `/usr/bin/orca` invoca el lector de pantalla GNOME Orca y activará síntesis de voz en la máquina del usuario.

Sigue estrictamente este orden determinista de resolución:

1. **Variable de entorno explícita**:
   - Si `ORCA_CLI_COMMAND` está definida, utiliza ese valor exacto.
2. **Entorno de desarrollo local**:
   - Si la sesión expone `ORCA_DEV_REPO_ROOT`, utiliza `orca-dev`.
3. **Linux estándar / terminal independiente**:
   - Si estás en Linux y no estás dentro de una terminal hija de Orca, el ejecutable homologado es:
     ```bash
     orca-ide
     ```
   - Ubicación estándar en flota: `~/.local/bin/orca-ide` o `/usr/local/bin/orca-ide`.
4. **Dentro de terminal de Orca o macOS/Windows**:
   - Usa `orca`.

---

## 🛠️ Comandos Principales de Orca CLI (v1.4.258)

### 1. Carga de Guía y Verificación de Estado
```bash
# Consultar la guía de comandos versionada en formato JSON
orca-ide skills get orca-cli --json

# Comprobar si Orca IDE está en ejecución
orca-ide open --json
```

### 2. Gestión de Worktrees
Orca automatiza la creación y vinculación de worktrees para tareas aisladas:
```bash
# Listar worktrees activos
orca-ide worktree list --json

# Crear un worktree efímero para una tarea
orca-ide worktree create --branch="feat/T-XXX-descripcion" --json

# Eliminar un worktree completado
orca-ide worktree remove <worktree-id>
```

### 3. Terminales PTY y Handoff de Agentes
```bash
# Enviar comando o prompt a una terminal de worktree
orca-ide terminal send --id="<terminal-id>" --input="npm run test\n"

# Esperar finalización de proceso en background
orca-ide terminal wait --id="<terminal-id>" --timeout=60
```

### 4. Navegador Embebido
```bash
# Abrir URL en el visor web interno de Orca
orca-ide browser open "http://localhost:3000"

# Capturar estado o screenshot del navegador embebido
orca-ide browser inspect --json
```

---

## 🔒 Buenas Prácticas y Seguridad
- Emplea siempre salida estructurada `--json` para que los agentes procesen respuestas deterministas.
- Si un comando falla con `runtime_access_denied`, no intentes forzar `orca open` en bucle: reporta la restricción de sandbox al operador.
- Nunca persistas secretos o credenciales en los comentarios o metadatos de los worktrees de Orca.
