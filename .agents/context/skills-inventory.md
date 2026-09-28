# Inventario de Habilidades de agent-os (Skills Inventory)

> Catálogo consolidado de habilidades (skills) del agente en **agent-os**. Cada habilidad encapsula instrucciones especializadas (`SKILL.md`), scripts de soporte y contratos operativos.

---

## 📋 Catálogo de Habilidades Activas

| # | Habilidad (Skill) | Cuándo Usarla (Propósito y Triggers) | Ubicación |
|---|---|---|---|
| 1 | **adr-decision-recorder** | Captura decisiones arquitectónicas críticas en formato ADR ante trade-offs técnicos o estructurales significativos. | `.agents/skills/adr-decision-recorder/` |
| 2 | **agent-os-scripts** | Guía operativa y sintaxis de los scripts CLI del núcleo (`install.sh`, `sync.sh`, `contribute.sh`, `check-sprint.sh`). | `.agents/skills/agent-os-scripts/` |
| 3 | **architecture-audit** | Auditoría técnica estática para detectar violaciones de capas, acoplamiento excesivo o ficheros >300 líneas antes de refactorizar. | `.agents/skills/architecture-audit/` |
| 4 | **buscar-codigo-en-github** | Búsqueda de implementaciones reales, patrones probados y librerías en repositorios de GitHub antes de programar. | `.agents/skills/buscar-codigo-en-github/` |
| 5 | **coolify-admin** | Gestión programática, despliegues y control de contenedores y stacks Docker Compose en Coolify PaaS vía API/CLI determinista. | `.agents/skills/coolify-admin/` |
| 6 | **coolify-nextjs-deploy** | Auditoría pre-build, dockerización standalone multi-stage de Next.js 15 y aprovisionamiento DNS en Cloudflare hacia Coolify. | `.agents/skills/coolify-nextjs-deploy/` |
| 7 | **creador-habilidades** | Creación y scaffolding de nuevas habilidades modulares (`SKILL.md`) para el ecosistema siguiendo la convención estándar. | `.agents/skills/creador-habilidades/` |
| 8 | **doc-maintainer** | Supervisión, análisis de ubicación previa y actualización obligatoria de fechas y formatos en documentación técnica. | `.agents/skills/doc-maintainer/` |
| 9 | **doe-framework** | Formalización del contrato de tarea (`task-XXX.md`) bajo el patrón Declare-Orchestrate-Execute antes de codificar. | `.agents/skills/doe-framework/` |
| 10 | **external-inbox** | Ingesta, saneamiento y auditoría previa de código externo, prototipos o auditorías depositadas en `docs/external-inbox/`. | `.agents/skills/external-inbox.md` |
| 11 | **git-gardener** | Mantenimiento e higiene del repositorio eliminando ramas remotas/locales mergeadas o huérfanas bajo confirmación. | `.agents/skills/git-gardener/` |
| 12 | **goal-evaluation** | Actuación como Judge independiente (Ralph Loop) validando desacopladamente metas y diffs vía `verify-goal.sh`. | `.agents/skills/goal-evaluation/` |
| 13 | **implementar-feature-dry** | Protocolo estricto de desarrollo para evitar duplicación de código e imponer reutilización de componentes existentes. | `.agents/skills/implementar-feature-dry/` |
| 14 | **infisical-secrets** | Inyección de secretos en memoria y sincronización centralizada con Infisical Community Edition y Universal Auth. | `.agents/skills/infisical-secrets/` |
| 15 | **orchestrator** | Orquestación multi-agente declarativa y despacho de tareas en paralelo con comandos agnósticos (`/goal`, `/dispatch`, `/merge`). | `.agents/skills/orchestrator/` |
| 16 | **remote-admin** | Ejecución remota segura de comandos, diagnóstico de infraestructura y control de contenedores Docker en VPS vía SSH. | `.agents/skills/remote-admin/` |
| 17 | **repo-onboarding** | Auditoría y adopción guiada para incorporar repositorios preexistentes al estándar operativo de Agent OS. | `.agents/skills/repo-onboarding/` |
| 18 | **roadmap-a-tarea** | Descomposición de objetivos de alto nivel o épicas del `ROADMAP.md` en tareas atómicas implementables (S/M/L). | `.agents/skills/roadmap-a-tarea/` |
| 19 | **rule-creator** | Formalización de requerimientos de comportamiento del usuario en reglas operativas persistentes en `.agents/rules/`. | `.agents/skills/rule-creator/` |
| 20 | **structure-guardian** | Supervisión de la arquitectura del árbol de directorios y propuesta de reubicaciones sin romper referencias. | `.agents/skills/structure-guardian/` |
| 21 | **tech-scout** | Evaluación comparativa de librerías, dependencias npm/pip y SDKs antes de introducir paquetes externos al proyecto. | `.agents/skills/tech-scout/` |
| 22 | **testing-flows** | Diseño e implementación de pirámide de pruebas (unitarias, integración, E2E) según el framework detectado. | `.agents/skills/testing-flows/` |
| 23 | **tool-inventory** | Descubrimiento e inspección del inventario de herramientas vivas en la flota (nodos, endpoints de inferencia y MCPs). | `.agents/skills/tool-inventory/` |
| 24 | **workflow-designer** | Creación y refactorización de flujos de trabajo estructurados en `.agents/workflows/` siguiendo el estándar oficial. | `.agents/skills/workflow-designer/` |

> ℹ️ **Nota de desambiguación**:
> - `sprint-planning`: Es un **workflow** (`.agents/workflows/sprint-planning.md`), no una skill.
> - Búsqueda de repositorios de referencia: Es cubierta por la skill `buscar-codigo-en-github`.

---

## 🔄 Procedimiento Canónico de Regeneración del Inventario

Cuando se añada, elimine o modifique una habilidad en `.agents/skills/`, sigue este procedimiento determinista:

### Procedimiento Automatizado (Coste $0)
Ejecuta el siguiente script en línea desde la raíz del proyecto para verificar y sincronizar la lista de habilidades:
```bash
python3 - <<'EOF'
import os, yaml

skills_dir = ".agents/skills"
items = []

for entry in sorted(os.listdir(skills_dir)):
    full_path = os.path.join(skills_dir, entry)
    if os.path.isdir(full_path):
        skill_file = os.path.join(full_path, "SKILL.md")
        loc = f".agents/skills/{entry}/"
    elif entry.endswith(".md"):
        skill_file = full_path
        loc = f".agents/skills/{entry}"
    else:
        continue

    if os.path.isfile(skill_file):
        with open(skill_file, "r", encoding="utf-8") as f:
            parts = f.read().split("---")
            desc = "Sin descripción"
            if len(parts) >= 3:
                try:
                    data = yaml.safe_load(parts[1])
                    desc = data.get("description", desc).strip().replace("\n", " ")
                except Exception:
                    pass
            items.append((entry.replace(".md", ""), desc, loc))

print(f"Total skills detectadas: {len(items)}")
for name, desc, loc in items:
    print(f"- {name} ({loc}): {desc}")
EOF
```

### Checklist de Mantenimiento
1. [ ] Toda nueva skill debe crearse en su propio subdirectorio con fichero `SKILL.md` y frontmatter YAML (`name`, `description`).
2. [ ] Ejecutar `tests/validate-control-plane.sh` para verificar integridad del `SKILL.md`.
3. [ ] Añadir la fila correspondiente en la tabla superior con la descripción funcional de cuándo usarla.
4. [ ] Actualizar la fecha de última revisión.

*Última actualización: 2026-09-28 (Sprint 11 — T-071)*
