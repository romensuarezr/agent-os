# Idea: Claridad operativa del working tree post-instalación — 2026-09-30

**Prioridad:** Media (Candidata Sprint 14 / DX / Gobernanza)

**Problema:**
Tras la ejecución de `install.sh`, la totalidad del árbol de Agent OS (`.agents/`, `scripts/agent/`, plantillas) queda como archivos untracked en el repositorio destino. Los agentes que leen las reglas de ciclo de vida (`strict-workflow.md`, `no-destructive-without-audit.md`) experimentan dudas o fricción sobre si deben crear un commit manual previo antes de realizar la primera auditoría o dejar que `audit-repo.sh --apply` lo confirme.

**Propuesta:**
1. Añadir un mensaje claro de cierre en `install.sh`: "💡 Archivos de Agent OS instalados. Puedes commitearlos ahora con `git add .agents scripts docs && git commit -m 'chore: bootstrap agent-os'` o ejecutar `audit-repo.sh --apply`".
2. Opcionalmente, ofrecer un flag `--commit` en `install.sh` que realice el commit de bootstrap de forma atómica si el working tree previo estaba limpio.

**Origen:**
Hallazgo empírico durante la prueba ciega de T-090 con sujeto real en `/tmp/agent-os-blind-subject`.
