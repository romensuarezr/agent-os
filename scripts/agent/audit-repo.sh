#!/usr/bin/env bash

# audit-repo.sh - Audita y adapta repositorios con vida previa al estándar de Agent OS
# Uso: bash scripts/agent/audit-repo.sh [--apply]

PROJECT_ROOT="$(pwd)"
AUDIT_FILE="docs/agent-os-audit.md"

# Asegurar que existe la carpeta docs/
mkdir -p "docs"

# ==========================================
# MODO APLICACIÓN
# ==========================================
if [ "$1" == "--apply" ]; then
    echo "⚙️ Iniciando modo aplicación en $PROJECT_ROOT..."
    
    # Salvaguarda: verificar que el working tree está limpio
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "❌ ABORTADO: Hay cambios sin commitear. Haz commit o stash antes de ejecutar --apply."
        exit 1
    fi

    if [ ! -f "$AUDIT_FILE" ]; then
        echo "❌ Error: No se encuentra el informe de auditoría: $AUDIT_FILE"
        echo "Ejecuta primero la detección: bash scripts/agent/audit-repo.sh"
        exit 1
    fi

    # Leer propuestas del informe de auditoría y aplicar
    echo "📖 Leyendo propuestas de $AUDIT_FILE..."
    
    applied_changes=0
    mkdir -p docs

    # 1. Renombrar archivos de casing incorrecto en la raíz
    if grep -q "\- \[ \] Renombrar ROADMAP.md a roadmap.md en la raíz" "$AUDIT_FILE"; then
        if [ -f "ROADMAP.md" ]; then
            git mv ROADMAP.md roadmap.md
            echo "✅ Renombrado ROADMAP.md a roadmap.md en la raíz"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Renombrar CHANGELOG.md a changelog.md en la raíz" "$AUDIT_FILE"; then
        if [ -f "CHANGELOG.md" ]; then
            git mv CHANGELOG.md changelog.md
            echo "✅ Renombrado CHANGELOG.md a changelog.md en la raíz"
            applied_changes=$((applied_changes + 1))
        fi
    fi

    # 2. Mover o renombrar mvp-tracker e implemented
    if grep -q "\- \[ \] Mover mvp-tracker.md de la raíz a docs/mvp-tracker.md" "$AUDIT_FILE"; then
        if [ -f "mvp-tracker.md" ]; then
            git mv mvp-tracker.md docs/mvp-tracker.md
            echo "✅ Movido mvp-tracker.md de la raíz a docs/mvp-tracker.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Mover MVP-TRACKER.md de la raíz a docs/mvp-tracker.md" "$AUDIT_FILE"; then
        if [ -f "MVP-TRACKER.md" ]; then
            git mv MVP-TRACKER.md docs/mvp-tracker.md
            echo "✅ Movido MVP-TRACKER.md de la raíz a docs/mvp-tracker.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Mover implemented.md de la raíz a docs/implemented.md" "$AUDIT_FILE"; then
        if [ -f "implemented.md" ]; then
            git mv implemented.md docs/implemented.md
            echo "✅ Movido implemented.md de la raíz a docs/implemented.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Mover IMPLEMENTED.md de la raíz a docs/implemented.md" "$AUDIT_FILE"; then
        if [ -f "IMPLEMENTED.md" ]; then
            git mv IMPLEMENTED.md docs/implemented.md
            echo "✅ Movido IMPLEMENTED.md de la raíz a docs/implemented.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi

    if grep -q "\- \[ \] Renombrar docs/MVP-TRACKER.md a docs/mvp-tracker.md" "$AUDIT_FILE"; then
        if [ -f "docs/MVP-TRACKER.md" ]; then
            git mv docs/MVP-TRACKER.md docs/mvp-tracker.md
            echo "✅ Renombrado docs/MVP-TRACKER.md a docs/mvp-tracker.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Renombrar docs/IMPLEMENTED.md a docs/implemented.md" "$AUDIT_FILE"; then
        if [ -f "docs/IMPLEMENTED.md" ]; then
            git mv docs/IMPLEMENTED.md docs/implemented.md
            echo "✅ Renombrado docs/IMPLEMENTED.md a docs/implemented.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi

    # 3. Mover external-inbox de la raíz a docs/external-inbox/
    if grep -q "\- \[ \] Mover external-inbox de la raíz a docs/external-inbox/" "$AUDIT_FILE"; then
        inbox_name=""
        if [ -d "external-inbox" ] || [ -f "external-inbox" ]; then inbox_name="external-inbox"
        elif [ -d "EXTERNAL-INBOX" ] || [ -f "EXTERNAL-INBOX" ]; then inbox_name="EXTERNAL-INBOX"; fi
        
        if [ -n "$inbox_name" ]; then
            mkdir -p docs/external-inbox
            if [ -d "$inbox_name" ]; then
                git mv "$inbox_name"/* docs/external-inbox/ 2>/dev/null || true
                git rm -rf "$inbox_name" 2>/dev/null || true
            else
                git mv "$inbox_name" docs/external-inbox/external-inbox.md
            fi
            echo "✅ Movido external-inbox de la raíz a docs/external-inbox/"
            applied_changes=$((applied_changes + 1))
        fi
    fi

    # 4. Migrar formato del tracker
    if grep -q "\- \[ \] Migrar el archivo .* para incorporar columnas estándar" "$AUDIT_FILE"; then
        tracker_file=""
        if [ -f "docs/mvp-tracker.md" ]; then tracker_file="docs/mvp-tracker.md"
        elif [ -f "docs/MVP-TRACKER.md" ]; then tracker_file="docs/MVP-TRACKER.md"
        elif [ -f "mvp-tracker.md" ]; then tracker_file="mvp-tracker.md"
        elif [ -f "MVP-TRACKER.md" ]; then tracker_file="MVP-TRACKER.md"; fi
        
        if [ -n "$tracker_file" ] && [ -f "$tracker_file" ]; then
            tmp_tracker=$(mktemp)
            has_peso=$(grep -i "peso" "$tracker_file" || true)
            
            if [ -z "$has_peso" ]; then
                echo "⚙️ Migrando formato de $tracker_file..."
                
                in_capacidades_table=false
                while IFS= read -r line || [ -n "$line" ]; do
                    if echo "$line" | grep -q "ID.*Capacidad"; then
                        in_capacidades_table=true
                        if echo "$line" | grep -q "Criterios"; then
                            echo "| ID | Capacidad | Peso | Estado | Avance% | Criterios de Done para MVP |" >> "$tmp_tracker"
                        else
                            echo "| ID | Capacidad | Peso | Estado | Avance% |" >> "$tmp_tracker"
                        fi
                    elif echo "$line" | grep -q "^## "; then
                        in_capacidades_table=false
                        echo "$line" >> "$tmp_tracker"
                    elif echo "$line" | grep -q "\-\-\-.*|.*\-\-\-"; then
                        if $in_capacidades_table; then
                            cols=$(echo "$line" | tr -cd '|' | wc -c)
                            if [ "$cols" -eq 7 ]; then
                                echo "|---|---|---|---|---|---|" >> "$tmp_tracker"
                            else
                                echo "|---|---|---|---|---|---|---|---|---|---|" >> "$tmp_tracker"
                            fi
                        else
                            echo "$line" >> "$tmp_tracker"
                        fi
                    elif echo "$line" | grep -q "^|"; then
                        if $in_capacidades_table; then
                            if echo "$line" | grep -q "TOTAL"; then
                                continue
                            else
                                id_val=$(echo "$line" | cut -d'|' -f2)
                                cap_val=$(echo "$line" | cut -d'|' -f3)
                                pct_val=$(echo "$line" | cut -d'|' -f4 | tr -d '% ')
                                crit_val=$(echo "$line" | cut -d'|' -f5)
                                
                                echo "|${id_val}|${cap_val}| 100 | 🔴 | ${pct_val:-0} |${crit_val:-}|" >> "$tmp_tracker"
                            fi
                        else
                            echo "$line" >> "$tmp_tracker"
                        fi
                    else
                        in_capacidades_table=false
                        echo "$line" >> "$tmp_tracker"
                    fi
                done < "$tracker_file"
                
                if ! grep -q "TOTAL" "$tmp_tracker"; then
                    hist_line=$(grep -n "## Historial" "$tmp_tracker" | cut -d':' -f1)
                    if [ -n "$hist_line" ]; then
                        sed -i "${hist_line}i | **TOTAL** | | **100** | | **0%** | | |\n" "$tmp_tracker"
                    else
                        echo -e "\n| **TOTAL** | | **100** | | **0%** | | |\n" >> "$tmp_tracker"
                    fi
                fi
                
                cat "$tmp_tracker" > "$tracker_file"
                rm -f "$tmp_tracker"
                echo "✅ Formato de $tracker_file actualizado con columnas estándar (Peso) y fila TOTAL."
                applied_changes=$((applied_changes + 1))
            fi
        fi
    fi

    # 5. Crear docs/sprints/sprint-00-historical.md
    if grep -q "\- \[ \] Crear docs/sprints/sprint-00-historical.md" "$AUDIT_FILE"; then
        mkdir -p docs/sprints
        sprint_file="docs/sprints/sprint-00-historical.md"
        
        echo "# Sprint 00: Histórico de Desarrollo" > "$sprint_file"
        echo -e "\n## Tareas Completadas (Extraídas del historial de Git)\n" >> "$sprint_file"
        
        in_sprint_section=false
        while IFS= read -r line || [ -n "$line" ]; do
            if [[ "$line" == "## Sprint-00 sugerido" ]]; then
                in_sprint_section=true
                continue
            fi
            if $in_sprint_section; then
                if [[ "$line" == "## "* ]]; then
                    break
                fi
                echo "$line" >> "$sprint_file"
            fi
        done < "$AUDIT_FILE"
        
        git add "$sprint_file"
        echo "✅ Creado $sprint_file con commits agrupados por semana."
        applied_changes=$((applied_changes + 1))
    fi

    # 6. Actualizar roadmap.md con secciones requeridas
    if grep -q "\- \[ \] Añadir secciones requeridas a roadmap.md" "$AUDIT_FILE"; then
        roadmap_file="roadmap.md"
        [ -f "ROADMAP.md" ] && roadmap_file="ROADMAP.md"
        
        if [ -f "$roadmap_file" ]; then
            echo "⚙️ Añadiendo secciones requeridas a $roadmap_file..."
            for sec in "## En progreso" "## Completado" "## Backlog"; do
                if ! grep -q "$sec" "$roadmap_file"; then
                    echo -e "\n$sec\n- [ ] Tareas iniciales por categorizar" >> "$roadmap_file"
                fi
            done
            echo "✅ roadmap.md actualizado con secciones estándar."
            applied_changes=$((applied_changes + 1))
        fi
    fi

    if [ $applied_changes -gt 0 ]; then
        git add -A
        git commit -m "chore(agent-os): apply audit adaptations to existing repo"
        echo "🎉 Adaptaciones de Agent OS aplicadas y confirmadas en Git."
    else
        echo "ℹ️ No se detectaron cambios pendientes por aplicar en el informe de auditoría."
    fi

    exit 0
fi

# ==========================================
# MODO DETECCIÓN
# ==========================================
echo "🔍 Iniciando auditoría de estructura en $PROJECT_ROOT..."

incompatibilidades=""
propuestas=""
sprint_sugerido=""

# 1. Comprobar existencia y casing de archivos clave en la raíz
for file in "roadmap.md" "changelog.md"; do
    real_file=$(find . -maxdepth 1 -iname "$file" | head -n 1 | sed 's|^\./||')
    if [ -n "$real_file" ]; then
        if [ "$real_file" != "$file" ]; then
            incompatibilidades+="- ⚠️ Archivo clave con casing incorrecto en la raíz: \`$real_file\` (debería ser \`$file\`)\n"
            propuestas+="- [ ] Renombrar $real_file a $file en la raíz\n"
        fi
    fi
done

# 2. Comprobar existencia, ubicación y casing de mvp-tracker.md e implemented.md
for file in "mvp-tracker.md" "implemented.md"; do
    in_root=$(find . -maxdepth 1 -iname "$file" | head -n 1 | sed 's|^\./||')
    in_docs=""
    if [ -d "docs" ]; then
        in_docs=$(find docs -maxdepth 1 -iname "$file" | head -n 1)
    fi

    if [ -n "$in_root" ]; then
        incompatibilidades+="- ⚠️ Archivo \`$in_root\` en la raíz (debería estar en \`docs/$file\`)\n"
        propuestas+="- [ ] Mover $in_root de la raíz a docs/$file\n"
    elif [ -n "$in_docs" ]; then
        filename=$(basename "$in_docs")
        if [ "$filename" != "$file" ]; then
            incompatibilidades+="- ⚠️ Archivo en docs/ con casing incorrecto: \`$in_docs\` (debería ser \`docs/$file\`)\n"
            propuestas+="- [ ] Renombrar $in_docs a docs/$file\n"
        fi
    fi
done

# 3. Comprobar ubicación de external-inbox
if [ -d "external-inbox" ] || [ -f "external-inbox" ]; then
    incompatibilidades+="- ⚠️ El directorio/archivo \`external-inbox\` está en la raíz (estándar de Agent OS requiere que esté en \`docs/external-inbox/\`)\n"
    propuestas+="- [ ] Mover external-inbox de la raíz a docs/external-inbox/\n"
elif [ ! -d "docs/external-inbox" ]; then
    propuestas+="- [ ] Crear carpeta vacía docs/external-inbox/\n"
fi

# 4. Validar estructura del MVP Tracker usando find_tracker
tracker_file=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/find-tracker.sh" ]; then
    source "$SCRIPT_DIR/lib/find-tracker.sh"
    tracker_file=$(find_tracker "$PROJECT_ROOT")
fi

if [ -z "$tracker_file" ]; then
    if [ -f "mvp-tracker.md" ]; then tracker_file="mvp-tracker.md"
    elif [ -f "MVP-TRACKER.md" ]; then tracker_file="MVP-TRACKER.md"
    elif [ -f "docs/mvp-tracker.md" ]; then tracker_file="docs/mvp-tracker.md"
    elif [ -f "docs/MVP-TRACKER.md" ]; then tracker_file="docs/MVP-TRACKER.md"; fi
fi

if [ -n "$tracker_file" ] && [ -f "$tracker_file" ]; then
    has_peso=$(grep -i "peso" "$tracker_file" || true)
    has_total=$(grep -q "TOTAL" "$tracker_file"; echo $?)
    if [ -z "$has_peso" ] || [ $has_total -ne 0 ]; then
        incompatibilidades+="- ⚠️ Estructura de \`$tracker_file\` desactualizada (falta columna 'Peso' o fila 'TOTAL')\n"
        propuestas+="- [ ] Migrar el archivo $tracker_file para incorporar columnas estándar y fila de control de sumas\n"
    fi
fi

# 5. Comprobar secciones en roadmap.md
roadmap_file=""
if [ -f "roadmap.md" ]; then
    roadmap_file="roadmap.md"
elif [ -f "ROADMAP.md" ]; then
    roadmap_file="ROADMAP.md"
fi

if [ -n "$roadmap_file" ]; then
    missing_sections=""
    for sec in "## En progreso" "## Completado" "## Backlog"; do
        if ! grep -q "$sec" "$roadmap_file"; then
            missing_sections+="\`$sec\`, "
        fi
    done
    if [ -n "$missing_sections" ]; then
        incompatibilidades+="- ⚠️ Faltan secciones requeridas en \`$roadmap_file\`: ${missing_sections%, }\n"
        propuestas+="- [ ] Añadir secciones requeridas a roadmap.md\n"
    fi
fi

# 6. Analizar git log para sugerir sprint-00-historical.md
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sprint_sugerido+="\n### Agrupación semanal de commits históricos\n\n"
    
    current_week=""
    tmp_log=$(mktemp)
    git log --date=short --format="%ad|%h|%s" -100 > "$tmp_log"
    
    while IFS='|' read -r date hash subject || [ -n "$date" ]; do
        [ -z "$date" ] && continue
        
        week_num=$(date -d "$date" +%Y-W%V 2>/dev/null)
        [ -z "$week_num" ] && continue
        
        if [ "$week_num" != "$current_week" ]; then
            current_week="$week_num"
            sprint_sugerido+="\n#### Semana $current_week\n"
        fi
        
        clean_subject=$(echo "$subject" | sed 's/|/\\|/g')
        sprint_sugerido+="- [x] Commit \`$hash\` ($date): $clean_subject\n"
    done < "$tmp_log"
    
    rm -f "$tmp_log"
    
    if [ -n "$sprint_sugerido" ]; then
        propuestas+="- [ ] Crear docs/sprints/sprint-00-historical.md con los commits agrupados por semana\n"
    fi
else
    incompatibilidades+="- ⚠️ El directorio no es un repositorio Git válido.\n"
fi

# ==========================================
# ESCRIBIR INFORME DE AUDITORÍA
# ==========================================
{
    echo "# Informe de Auditoría y Adaptación de Agent OS"
    echo -e "\nFecha: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "\n## Incompatibilidades\n"
    if [ -n "$incompatibilidades" ]; then
        echo -e "$incompatibilidades"
    else
        echo "✅ No se encontraron incompatibilidades estructurales graves."
    fi

    echo -e "\n## Cambios Propuestos\n"
    if [ -n "$propuestas" ]; then
        echo -e "$propuestas"
    else
        echo "✅ El repositorio ya cumple con el estándar de Agent OS."
    fi

    echo -e "\n## Sprint-00 sugerido"
    if [ -n "$sprint_sugerido" ]; then
        echo -e "$sprint_sugerido"
    else
        echo "No hay commits históricos suficientes para estructurar el Sprint 00."
    fi
} > "$AUDIT_FILE"

echo "✅ Auditoría completada. Informe escrito en $AUDIT_FILE"
echo "👉 Revisa docs/agent-os-audit.md y ejecuta con --apply para aplicar los cambios propuestos."
