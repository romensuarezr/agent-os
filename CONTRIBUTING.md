# Guía de Contribución a Agent OS

¡Gracias por tu interés en contribuir a **Agent OS**! 🎉

Agent OS es un sistema operativo de trabajo portable y estandarizado para agentes de Inteligencia Artificial. Se instala en cualquier repositorio de código para proporcionar workflows deterministas, skills operativas, reglas de gobierno y scripts de automatización.

---

## 🏛️ Filosofía y Principios de Diseño

Antes de proponer cualquier cambio, ten en cuenta nuestros principios irrenunciables:

1. **Agnóstico y Universal**: Ningún script, skill o workflow del núcleo debe asumir un stack tecnológico concreto ni depender de infraestructura privada (sin IPs fijas, dominios privados o rutas absolutas como `/home/usuario`).
2. **Desacople Declarativo de Entornos**: Las herramientas, modelos y nodos de computación se configuran localmente en `config/fleet.yaml` (ignorado en git). El núcleo únicamente versiona `config/fleet.example.yaml` y esquemas estándar (como la especificación MCP).
3. **No destructivo por defecto**: Las herramientas de detección y auditoría nunca modifican el sistema sin confirmación explícita o flags dedicados (como `--apply`).
4. **Principio de Responsabilidad Única (SRP)**: Cada script, skill o regla tiene un propósito delimitado y comprobable.
5. **No reinventar la rueda (OSS First)**: Antes de escribir una herramienta o skill desde cero, consulta el catálogo de herramientas activas (`tool-inventory`) o ejecuta prospección determinista (`scripts/agent/scout.sh`) para contrastar con soluciones consolidadas en el ecosistema.
6. **Determinismo y Eficiencia de Tokens**: Toda consulta, inspección, filtrado o recolección de datos predecible debe resolverse mediante scripts locales (Bash/CLI) a coste **$0**, entregando al agente únicamente un digest estructurado y compacto (10–20 líneas) para no quemar tokens de contexto o inferencia del LLM.

---

## 🛤️ Modos de Contribución

Existen dos formas principales de aportar mejoras a Agent OS:

### Opción A: Mejoras originadas en proyectos hijos (`contribute.sh`)

Si estás trabajando en un proyecto donde Agent OS está instalado y perfeccionaste una skill, regla o workflow local:
1. Asegúrate de que el cambio sea verdaderamente agnóstico y no contenga código específico del proyecto hijo.
2. Ejecuta desde el proyecto hijo:
   ```bash
   bash scripts/agent/contribute.sh
   ```
3. El script empaquetará las diferencias hacia una rama y facilitará la creación del Pull Request hacia el core.

### Opción B: Desarrollo directo sobre el repositorio Core

Si estás desarrollando directamente nuevas capacidades del núcleo de Agent OS:
1. Haz un **Fork** del repositorio oficial y clónalo en tu máquina local.
2. Si es la primera vez que inicializas el entorno operativo sobre el core:
   ```bash
   bash scripts/agent/install.sh . --self
   ```
3. Copia `config/fleet.example.yaml` a `config/fleet.yaml` y ajusta tus herramientas y endpoints locales:
   ```bash
   cp config/fleet.example.yaml config/fleet.yaml
   ```
   *(Nota: `config/fleet.yaml` está ignorado en `.gitignore` para proteger tus datos privados).*

---

## 🔄 Flujo de Trabajo Operativo con Agentes

Agent OS es ciudadano de primera clase de sí mismo: sigue su propio sprint y sus propios workflows. Si operas mediante un asistente de IA (como Antigravity, Claude Code, Cursor, OpenCode, etc.):

1. **Consulta del estado activo**:
   ```bash
   bash scripts/agent/check-session.sh
   bash scripts/agent/check-sprint.sh
   ```
2. **Inicio formal de sesión (`/session-start`)**:
   - Todo trabajo se asocia a una tarea activa definida en `docs/sprints/sprint-XX-core.md` con su correspondiente task file `.agents/tasks/task-XXX.md`.
   - Se delimita la **Caja de archivos autorizados**.
   - Se formula un **Plan en Fase 3.5** con el token bloqueante `⏳ ESPERANDO` antes de crear ramas o modificar archivos.
3. **Ramificación**:
   - Crea ramas semánticas descriptivas a partir de `main`:
     ```bash
     git checkout -b feat/T-XXX-descripcion-corta
     # o
     git checkout -b fix/T-XXX-descripcion-corta
     ```
4. **Cierre y archivado**:
   - Una vez validados todos los criterios de done:
     ```bash
     bash scripts/agent/close-task.sh T-XXX "tipo(scope): descripción"
     ```

---

## 📝 Convenciones de Commits

Agent OS adopta la convención de [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(scope): descripción concisa
fix(scope): descripción concisa
refactor(scope): descripción concisa
docs(scope): descripción concisa
test(scope): descripción concisa
chore(scope): descripción concisa
BREAKING: descripción de impacto retrocompatible
```

**Scopes habituales del core**: `install`, `sync`, `contribute`, `audit`, `workflows`, `skills`, `rules`, `lib`, `fleet`, `scout`, `config`.

---

## 🧪 Pruebas y Validación de Calidad

Antes de someter un Pull Request, verifica que la suite de validación y control de calidad no arroje errores:

```bash
# 1. Validar control plane y estructura de archivos
bash tests/validate-control-plane.sh

# 2. Verificar que no haya variables o rutas privadas en el diff
git diff main...HEAD
```

Asegúrate de:
- [ ] No incluir archivos `.env`, tokens, contraseñas ni URLs con IPs privadas no documentadas.
- [ ] No alterar archivos fuera del alcance estricto de la funcionalidad o corrección.
- [ ] Documentar en `docs/adrs/` cualquier decisión de arquitectura que modifique el comportamiento estándar del core.

---

## 🤝 Código de Conducta

Nos comprometemos a brindar un entorno abierto, respetuoso, constructivo y colaborativo para todos los participantes, independientemente de su nivel de experiencia, origen o herramientas de trabajo.
