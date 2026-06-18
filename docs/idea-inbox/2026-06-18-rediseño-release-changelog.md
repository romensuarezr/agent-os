# Idea: Rediseño del flujo de Release y automatización de versión (Changelog + Semver)
**Fecha**: 2026-06-18

## Resumen del acuerdo de diseño
Se propone rediseñar el flujo de release y generación de changelogs para automatizar el bump de versiones, evitar redundancias y asegurar la consistencia mediante una regla global activa.

## Propuesta detallada

| Qué | Dónde | Por qué |
|---|---|---|
| Nueva rule `release-on-merge.md` | `.agents/rules/global/` | Garantiza que changelog+versión salten siempre |
| Ampliar `update-changelog.sh` | `scripts/agent/` | Escribir bump en fuente de verdad del stack |
| Refactorizar `/changelog` workflow | `.agents/workflows/changelog.md` | Convertirlo en orquestador único del release |
| `session-close.md` paso 4 | `.agents/workflows/session-close.md` | Delegar en `/changelog` en lugar de duplicar |

---

## 1. Nueva rule global: `release-on-merge.md`
El lugar correcto para garantizar que el changelog y la versión se actualicen es una rule global en `.agents/rules/global/release-on-merge.md`. De esta manera, el agente la leerá al inicio de cada conversación y no podrá omitirla.

**Contenido propuesto**:
```markdown
# release-on-merge.md

REGLA: Antes de hacer merge o push a main/master/develop:
1. Verifica si hay commits feat: o fix: sin entrada en CHANGELOG.md.
2. Si los hay → ejecuta update-changelog.sh + bump de versión.
3. No se puede completar un merge a la rama principal sin este paso.
```

---

## 2. Automatización de Bump de Versión (`update-changelog.sh`)
Ampliar `update-changelog.sh` para persistir el incremento de versión de semver en la fuente de verdad del stack del proyecto hijo:
1. **Detección de stack**: Usar `lib/detect-stack.sh` para identificar archivos como `pyproject.toml`, `package.json` o `VERSION`.
2. **Confirmación interactiva**:
   ```
   📦 Versión actual: 0.2.1
   📦 Versión propuesta: 0.3.0 (minor bump — 3 feat: en este sprint)
      Razón: T-023 rediseño de flujos, T-024 detección de updates, T-025 assets-manifest
   
   ¿Confirmas? (S/n):
   ```
3. **Persistencia**: Con la confirmación, escribir la nueva versión tanto en el archivo de configuración del stack como en el encabezado de `CHANGELOG.md` de manera atómica.

---

## 3. Workflow `/changelog` como orquestador único
Refactorizar el workflow `.agents/workflows/changelog.md` para que deje de ser un duplicado y se convierta en el **único punto de entrada y orquestador del proceso de release** (detección de stack, bump de versión, escritura en archivos y cierre de sprint).
El paso 4 de `session-close.md` delegará directamente en `/changelog`.

---

## 4. Convención de archivos
- `CHANGELOG.md` (Mayúsculas): El registro de cambios en la raíz de cada proyecto destinado a humanos.
- `changelog.md` (Minúsculas): El workflow operativo del sistema en `.agents/workflows/changelog.md`.
