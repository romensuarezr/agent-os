# T-235 — Puente Declarativo: .agents/profiles/ a Orca Bot Identities y Standing Instructions
Sprint: Sprint 44 | Estado: ✅ Hecho | Tamaño: M | Rama propuesta: feat/T-235-orca-bot-identities-bridge | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 44 — 2026-11-23
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Diseñar el mecanismo o plantilla para proyectar los perfiles declarativos de `.agents/profiles/` (`coder.md`, `coordinator.md`, `qa-judge.md`, etc.) y las reglas globales de `.agents/rules/` hacia el formato de *Identity, Soul & Memory* y *standing instructions* de Orca Bots (v1.4.268).
  - Permitir que cuando se lance un bot en Orca con runtime `opencode` o `hermes`, herede de forma determinista su rol, sus directrices de sala limpia, su contrato de lenguaje y su whitelist de herramientas.
  - Crear un helper o documentación operativa en `.agents/profiles/README.md` y runbooks de orquestación.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Asegurar que cualquier bot instanciado dentro de Orca (OpenCode, Hermes o Claude) sea consciente de su identidad, contratos operativos y protocolos de Agent OS desde el primer segundo mediante standing instructions y tarjetas de identidad.

## 2. Contexto técnico
- Directorio de perfiles: `.agents/profiles/`.
- Reglas maestras: `.agents/rules/`.
- Motor de perfiles: `scripts/agent/setup-profiles.sh`.

## 3. Caja de archivos
- `.agents/profiles/`
- `scripts/agent/setup-profiles.sh`
- `docs/runbooks/`
- `.agents/tasks/task-235.md`
- `docs/sprints/sprint-44.md`

## 4. Plan de implementación
1. Analizar el esquema JSON/YAML o directivas de configuración que Orca v1.4.268 utiliza para bots, identity cards y standing instructions.
2. Adaptar `setup-profiles.sh` o proporcionar la plantilla de exportación para generar configuraciones de bots compatibles con Orca.
3. Documentar en `.agents/profiles/README.md` el ciclo de vida de un bot dentro de Orca ADE.
4. Validar la consistencia y ausencia de duplicaciones con `inventory-check.sh`.

## 5. Criterios de aceptación
- Los perfiles de Agent OS pueden ser consumidos por Orca Bots sin fricción manual.
- Las standing instructions inyectan las reglas críticas (`caveman`, `dry-architecture`, `teach-while-building`) en agentes OpenCode y Hermes.
