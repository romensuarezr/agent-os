# Task-073: Reglas y skills agnósticas de stack, flota y herramientas propietarias

## Objetivo
Que las reglas globales y las skills instalables no asuman el stack, la flota ni las herramientas del autor. Lo específico pasa a ejemplo etiquetado, condicional u opcional.

## Contexto técnico
Auditoría 2026-09-28 (bloques rules y skills): `agent-permissions.md` nombra Hermes/Orca/Antigravity/OpenCode y hosts `local`/`datamanager`/`oracle` como universales; `dry-architecture.md` asume frontend React (Hooks, Pages, `{ items, isLoading, error }`); `deployment-safety.md` ejemplifica con `connectDB()` de Node; `no-destructive-without-audit.md` con `deleteDoc` de Firestore; `routing-policy.yaml` declara `preferred_model_tier: "freellmapi-auto"`, que no existe como endpoint; `agent-registry.yaml` omite `coder`/`qa-judge`/`docs-researcher`, que el protocolo exige; `known-web-tools.yaml` documenta cómo extenderse pero no cómo usarse; `architecture-audit/SKILL.md` tiene 29 líneas sin comandos ni ejemplos; hay skills atadas a herramientas propietarias de Antigravity (`run_command`, `notify_user`).

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/rules/global/agent-permissions.md`
- `.agents/rules/global/dry-architecture.md`
- `.agents/rules/global/deployment-safety.md`
- `.agents/rules/global/no-destructive-without-audit.md`
- `config/routing-policy.yaml`
- `config/agent-registry.yaml`
- `config/known-web-tools.yaml`
- `.agents/skills/architecture-audit/SKILL.md`
- Skills con dependencia propietaria (marcar `optional` + alternativa portable en su SKILL.md)

## Criterios de done
- [ ] Ninguna regla global nombra herramientas/hosts del autor como universales; donde aparezcan, van etiquetados como ejemplo o tras condición ("si tu flota es…").
- [ ] Los ejemplos de código son multi-stack o llevan etiqueta de stack explícita.
- [ ] `preferred_model_tier` referencia un endpoint real y documentado de `routing-policy.yaml`.
- [ ] El registry incluye todos los perfiles que el protocolo exige (`coder`, `qa-judge`, `docs-researcher` incluidos).
- [ ] `known-web-tools.yaml` tiene sección "cómo usar" con ejemplo de invocación, no solo "cómo extender".
- [ ] `architecture-audit/SKILL.md` incluye comandos concretos y ejemplos de uso.
- [ ] Skills dependientes de herramientas propietarias marcadas `optional: true` con alternativa portable documentada.
- [ ] `tests/validate-control-plane.sh` en verde.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
