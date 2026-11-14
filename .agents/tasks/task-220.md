# T-220 — Absorción de orca-cli (v1.4.258), actualización de infisical-secrets (v0.45.8) y fix de staging acotado en contribute.sh
Sprint: Sprint 41 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-220-tooling-absorption-and-contribute-fix | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 41 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Incorporar la skill `.agents/skills/orca-cli/SKILL.md` (v1.4.258) homologada en satélite `romensuarez-web` al catálogo canónico del Core.
  - Actualizar `.agents/skills/infisical-secrets/SKILL.md` con las referencias a las nuevas versiones (v0.45.8) y parámetros vigentes.
  - Registrar formalmente `orca-cli` en `.agents/config/skills-manifest.yaml`.
  - Corregir el fallo de staging en `scripts/agent/contribute.sh` sustituyendo `git add .` por `git add "$DEST_DIR/$FILE_NAME"` acotado.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Homologar en el Core las mejoras y nuevas habilidades originadas en los satélites de la flota, y blindar el mecanismo de retroalimentación (`contribute.sh`) para prevenir la adición involuntaria de archivos no relacionados.

## 2. Contexto técnico
- Skill orca: originada en `romensuarez-web` T-050 con prevención de colisiones GNOME (`/usr/bin/orca` vs `orca-ide`).
- Skill infisical: `.agents/skills/infisical-secrets/SKILL.md`.
- Catálogo de skills: `.agents/config/skills-manifest.yaml`.
- Script de promoción: `scripts/agent/contribute.sh`.

## 3. Caja de archivos
- `.agents/tasks/task-220.md`
- `.agents/skills/orca-cli/SKILL.md`
- `.agents/skills/infisical-secrets/SKILL.md`
- `.agents/config/skills-manifest.yaml`
- `scripts/agent/contribute.sh`
- `docs/sprints/sprint-41.md`

## 4. Plan de implementación
1. Crear el directorio `.agents/skills/orca-cli/` y copiar `SKILL.md` validando que no contiene referencias a rutas de usuario o secretos.
2. Actualizar `.agents/skills/infisical-secrets/SKILL.md` reflejando la compatibilidad v0.45.8.
3. Añadir la entrada `orca-cli` a `.agents/config/skills-manifest.yaml`.
4. Editar `scripts/agent/contribute.sh` línea 73 para acotar el staging al archivo/directorio específico copiado.
5. Ejecutar la suite de validación `tests/validate-control-plane.sh` para certificar la integridad de las 31 skills.

## 5. Criterios de aceptación
- `orca-cli` está presente en `.agents/skills/` y en `skills-manifest.yaml`.
- `contribute.sh` ejecuta staging acotado (`git add "$DEST_DIR/$FILE_NAME"`).
- `tests/validate-control-plane.sh` pasa en verde con 31 skills verificadas.
