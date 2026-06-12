---
name: git-gardener
description: Mantiene la higiene del repositorio eliminando ramas mergeadas o estancadas, siempre bajo propuesta y aprobación.
---

# Git Gardener (Git Master)

Esta habilidad actúa como **Guardián del Repositorio**. Su misión es evitar la proliferación de ramas zombis, asegurando que solo las ramas activas y relevantes permanezcan en el sistema, liberando espacio y carga cognitiva.

## Cuándo Activar
- **Mantenimiento**: "Limpia ramas viejas", "Borra ramas mergeadas".
- **Post-Release**: Después de completar un sprint o una feature grande.
- **Trigger Implícito**: Al ver demasiadas ramas en `git branch` (>15).

## Flujo de Trabajo

### Fase 0: SINCRONIZACIÓN
1. **Actualizar referencias remotas**:
   ```bash
   git fetch --prune
   ```
   Esto marca automáticamente como `:gone` las ramas cuyo remote ya fue borrado en origin.
2. **Detectar ramas con remote desaparecido ("gone")**:
   ```bash
   git branch -vv | grep ": gone]"
   ```
   Clasificar estas como **[GONE]** — candidatas seguras a borrar localmente.

### Fase 1: DETECCIÓN (Scan)
1. **Identificar Ramas Mergeadas**:
   ```bash
   git branch --merged main
   ```
   Candidatas seguras — ya integradas en main.

2. **Identificar Ramas "Stale" (Estancadas)**:
   ```bash
   # Ver últimas fechas de commit por rama
   git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads/
   ```
   Criterio stale: sin commits en > 15 días **Y** no mencionada en `task.md` como activa.

3. **Verificar divergencia real** (para ramas stale — distingue basura de trabajo pendiente):
   ```bash
   # Commits únicos de BRANCH que no están en main
   git log --oneline $(git merge-base BRANCH main)..BRANCH | wc -l
   ```
   - Output `0` → rama sin trabajo propio → **[SAFE]** aunque no tenga PR.
   - Output `> 0` → rama con trabajo único → **[STALE-WORK]** — requiere revisión manual antes de borrar.

4. **Filtrado de Seguridad (Whitelist)**:
   - **INTOCABLES**: `main`, `master`, `develop`, `staging`, `production`, `release/*`.
   - **ACTIVAS**: Ramas mencionadas en la tarea actual o con PR abierto.

### Fase 2: PROPUESTA (The Cleanup Plan)
1. **Generar Plan (`git_cleanup_plan.md`)** con tres categorías:

   | Categoría | Criterio | Acción propuesta |
   |---|---|---|
   | **[MERGED]** | Aparece en `--merged main` | `git branch -d` + `git push origin --delete` |
   | **[GONE]** | Remote desaparecido (`gone`) | `git branch -d` local únicamente |
   | **[STALE]** | > 15 días, sin trabajo único (divergencia = 0) | `git branch -D` + `git push origin --delete` |
   | **[STALE-WORK]** | > 15 días, tiene commits únicos | ⚠️ Requiere decisión explícita del humano |

2. Listar explícitamente qué se borrará, con el comando exacto.
3. **No ejecutar nada sin aprobación explícita.**

### Fase 3: PODA (Execution)
1. **Validar Aprobación**: Confirmar que el usuario ha revisado y aprobado el plan.
2. **Ejecutar Limpieza Local**:
   ```bash
   git branch -d [branch]    # merged — falla si no está merged (seguro)
   git branch -D [branch]    # stale aprobado explícitamente
   ```
3. **Ejecutar Limpieza Remota**:
   ```bash
   git push origin --delete [branch]
   ```
4. **Pruning final** — limpiar referencias locales residuales:
   ```bash
   git remote prune origin
   ```

## Comandos de Referencia Rápida
```bash
# Sincronizar y detectar gone
git fetch --prune
git branch -vv | grep ": gone]"

# Merged branches (excepto main)
git branch --merged main | grep -v "main"

# Ramas ordenadas por fecha de último commit
git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)'

# Verificar divergencia de una rama específica
git log --oneline $(git merge-base FEAT_BRANCH main)..FEAT_BRANCH | wc -l
```

## Verificación Post-Poda
- `git branch -a` — confirmar que las ramas borradas han desaparecido local y remoto.
- Verificar que `main` sigue intacta y sin cambios.
- Comprobar que las ramas activas (con PR abierto o en task.md) siguen presentes.
