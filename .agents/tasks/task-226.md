# T-226 — Despliegue del Contrato Operativo `AGENTS.md` de Conserje en el Home de Hermes (`/home/ubuntu/AGENTS.md`)
Sprint: Sprint 42 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-226-hermes-concierge-agents-md | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 42 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Desplegar `/home/ubuntu/AGENTS.md` como contrato operativo estándar para Hermes en el VPS (su `TERMINAL_CWD`), respetando la separación estricta de Nous Research: `SOUL.md` (identidad y tono) y `AGENTS.md` (instrucciones operativas y gobernanza).
  - Definir las responsabilidades del rol Conserje:
    - Peticiones de desarrollo / código: delegación inmediata al Coordinador Antigravity residente en el VPS vía `hermes-concierge` (`concierge_bridge.py`).
    - Peticiones de infraestructura / contenedores: uso de `coolify-admin` y `remote-admin`.
    - Triage y monitoreo: scripts locales deterministas a coste $0.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Dotar a Hermes Agent de un contrato operativo claro y explícito en su raíz de ejecución (`/home/ubuntu`) para que reconozca inmediatamente su rol de conserje y sepa a quién delegar cada tipo de tarea sin vacilaciones.

## 2. Contexto técnico
- Directorio de trabajo de Hermes: `/home/ubuntu`.
- Identidad existente: `~/.hermes/SOUL.md`.
- Habilidad de puente: `~/.hermes/skills/hermes-concierge/`.

## 3. Caja de archivos
- `.agents/tasks/task-226.md`
- `docs/sprints/sprint-42.md`
- `/home/ubuntu/AGENTS.md` (en `<nodo-inferencia>`)

## 4. Plan de implementación
1. Redactar el contenido de `/home/ubuntu/AGENTS.md` estructurado según el estándar de Agent OS.
2. Definir la tabla de enrutamiento de intenciones: Desarrollo -> Antigravity; Ops -> Coolify/Docker; Monitoreo -> Local.
3. Desplegar el archivo en `<nodo-inferencia>` verificando permisos de lectura para el usuario `ubuntu`.
4. Comprobar que Hermes lo carga al iniciar sesión o en el prompt de contexto.

## 5. Criterios de aceptación
- `/home/ubuntu/AGENTS.md` existe y está alineado con `SOUL.md`.
- No hay contradicciones entre `hermes-concierge/SKILL.md` y `AGENTS.md`.
- Libre de IPs privadas o datos sensibles.
