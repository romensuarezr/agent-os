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

    # 1. Renombrar archivos de casing incorrecto
    if grep -q "\- \[ \] Renombrar ROADMAP.md a roadmap.md" "$AUDIT_FILE"; then
        if [ -f "ROADMAP.md" ]; then
            git mv ROADMAP.md roadmap.md
            echo "✅ Renombrado ROADMAP.md a roadmap.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Renombrar CHANGELOG.md a changelog.md" "$AUDIT_FILE"; then
        if [ -f "CHANGELOG.md" ]; then
            git mv CHANGELOG.md changelog.md
            echo "✅ Renombrado CHANGELOG.md a changelog.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Renombrar MVP-TRACKER.md a mvp-tracker.md" "$AUDIT_FILE"; then
        if [ -f "MVP-TRACKER.md" ]; then
            git mv MVP-TRACKER.md mvp-tracker.md
            echo "✅ Renombrado MVP-TRACKER.md a mvp-tracker.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi
    if grep -q "\- \[ \] Renombrar IMPLEMENTED.md a implemented.md" "$AUDIT_FILE"; then
        if [ -f "IMPLEMENTED.md" ]; then
            git mv IMPLEMENTED.md implemented.md
            echo "✅ Renombrado IMPLEMENTED.md a implemented.md"
            applied_changes=$((applied_changes + 1))
        fi
    fi

    # 2. Mover external-inbox de la raíz a docs/external-inbox/
    if grep -q "\- \[ \] Mover external-inbox de la raíz a docs/external-inbox/" "$AUDIT_FILE"; then
        if [ -d "external-inbox" ]; then
            mkdir -p docs/external-inbox
            git mv external-inbox/* docs/external-inbox/ 2>/dev/null || true
            git rm -rf external-inbox 2>/dev/null || true
            echo "✅ Movido external-inbox de raíz a docs/external-inbox/"
            applied_changes=$((applied_changes + 1))
        elif [ -f "external-inbox" ]; then
            mkdir -p docs/external-inbox
            git mv external-inbox docs/external-inbox/external-inbox.md
            echo "✅ Movido archivo external-inbox de raíz a docs/external-inbox/"
            applied_changes=$((applied_changes + 1))
        fi
    fi

    # 3. Migrar MVP-TRACKER.md (añadiendo Peso y TOTAL si faltan)
    if grep -q "\- \[ \] Migrar MVP-TRACKER.md" "$AUDIT_FILE"; then
        tracker_file="mvp-tracker.md"
        [ -f "MVP-TRACKER.md" ] && tracker_file="MVP-TRACKER.md"
        
        if [ -f "$tracker_file" ]; then
            # Crear copia temporal
            tmp_tracker=$(mktemp)
            has_peso=$(grep -i "peso" "$tracker_file")
            
            if [ -z "$has_peso" ]; then
                # Añadir columna Peso y fila TOTAL
                echo "⚙️ Migrando formato de $tracker_file..."
                
                # Procesar línea a línea para insertar columna Peso
                while IFS= read -r line || [ -n "$line" ]; do
                    if echo "$line" | grep -q "ID.*Capacidad.*Estado"; then
                        # Cabecera de la tabla
                        echo "| ID | Capacidad | Peso | Estado |" >> "$tmp_tracker"
                    elif echo "$line" | grep -q "\-\-\-.*|.*\-\-\-"; then
                        # Separador de cabecera
                        echo "| --- | --- | --- | --- |" >> "$tmp_tracker"
                    elif echo "$line" | grep -q "^|"; then
                        # Fila de tabla
                        if echo "$line" | grep -q "TOTAL"; then
                            # Saltar la fila TOTAL si ya existiera en otro formato
                            continue
                        else
                            # Insertar columna Peso vacía (entre Capacidad y Estado)
                            # Suponemos formato: | ID | Capacidad | Estado | ...
                            id_val=$(echo "$line" | cut -d'|' -f2)
                            cap_val=$(echo "$line" | cut -d'|' -f3)
                            est_val=$(echo "$line" | cut -d'|' -f4)
                            echo "|${id_val}|${cap_val}| |${est_val}|" >> "$tmp_tracker"
                        fi
                    else
                        echo "$line" >> "$tmp_tracker"
                    fi
                done < "$tracker_file"
                
                # Añadir fila TOTAL antes de la sección de historial si no existe
                # Buscamos la última fila de la tabla
                # Para simplificar, insertamos la fila TOTAL al final del archivo antes de ## Historial
                if ! grep -q "TOTAL" "$tmp_tracker"; then
                    # Encontrar línea de ## Historial
                    hist_line=$(grep -n "## Historial" "$tmp_tracker" | cut -d':' -f1)
                    if [ -n "$hist_line" ]; then
                        # Insertar fila TOTAL justo antes de ## Historial
                        sed -i "${hist_line}i | **TOTAL** | | | | \n" "$tmp_tracker"
                    else
                        echo -e "\n| **TOTAL** | | | |\n" >> "$tmp_tracker"
                    fi
                fi
                
                cat "$tmp_tracker" > "$tracker_file"
                rm -f "$tmp_tracker"
                echo "✅ Formato de MVP-TRACKER.md actualizado con columna Peso y fila TOTAL."
                applied_changes=$((applied_changes + 1))
            fi
        fi
    fi

    # 4. Crear docs/sprints/sprint-00-historical.md
    if grep -q "\- \[ \] Crear docs/sprints/sprint-00-historical.md" "$AUDIT_FILE"; then
        mkdir -p docs/sprints
        sprint_file="docs/sprints/sprint-00-historical.md"
        
        # Extraer la sección del Sprint-00 propuesta en el audit
        echo "# Sprint 00: Histórico de Desarrollo" > "$sprint_file"
        echo -e "\n## Tareas Completadas (Extraídas del historial de Git)\n" >> "$sprint_file"
        
        # Leer líneas del audit a partir de la sección Sprint-00
        in_sprint_section=false
        while IFS= read -r line || [ -n "$line" ]; do
            if [[ "$line" == "## Sprint-00 sugerido" ]]; then
                in_sprint_section=true
                continue
            fi
            if $in_sprint_section; then
                if [[ "$line" == "## "* ]]; then
                    # Si empieza otra sección principal, paramos
                    break
                fi
                echo "$line" >> "$sprint_file"
            fi
        done < "$AUDIT_FILE"
        
        git add "$sprint_file"
        echo "✅ Creado $sprint_file con commits agrupados por semana."
        applied_changes=$((applied_changes + 1))
    fi

    # 5. Actualizar ROADMAP.md con secciones requeridas
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
            echo "✅ ROADMAP.md actualizado con secciones estándar."
            applied_changes=$((applied_changes + 1))
        fi
    fi

    if [ $applied_changes -gt 0 ]; then
        # Agregar todos los cambios y hacer commit
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

# 1. Comprobar existencia y casing de archivos clave
for file in "roadmap.md" "changelog.md" "mvp-tracker.md" "implemented.md"; do
    # Buscar de forma insensible a mayúsculas
    real_file=$(find . -maxdepth 1 -iname "$file" | head -n 1 | sed 's|^\./||')
    if [ -n "$real_file" ]; then
        if [ "$real_file" != "$file" ]; then
            incompatibilidades+="- ⚠️ Archivo clave con casing incorrecto: \`$real_file\` (debería ser \`$file\`)\n"
            # Generar propuesta exacta
            upper_name=$(echo "$file" | tr '[:lower:]' '[:upper:]')
            propuestas+="- [ ] Renombrar $real_file a $file\n"
        fi
    else
        # Si no existe, los scripts lo crearán o el roadmap-a-tarea lo requerirá, no es un error de casing
        true
    fi
done

# 2. Comprobar ubicación de external-inbox
if [ -d "external-inbox" ] || [ -f "external-inbox" ]; then
    incompatibilidades+="- ⚠️ El directorio/archivo \`external-inbox\` está en la raíz (estándar de Agent OS requiere que esté en \`docs/external-inbox/\`)\n"
    propuestas+="- [ ] Mover external-inbox de la raíz a docs/external-inbox/\n"
elif [ ! -d "docs/external-inbox" ]; then
    # No existe en ningún sitio, proponer crear la estructura
    propuestas+="- [ ] Crear carpeta vacía docs/external-inbox/\n"
fi

# 3. Validar estructura de MVP-TRACKER.md
tracker_file=""
if [ -f "mvp-tracker.md" ]; then
    tracker_file="mvp-tracker.md"
elif [ -f "MVP-TRACKER.md" ]; then
    tracker_file="MVP-TRACKER.md"
fi

if [ -n "$tracker_file" ]; then
    has_peso=$(grep -i "peso" "$tracker_file")
    has_total=$(grep -q "TOTAL" "$tracker_file"; echo $?)
    if [ -z "$has_peso" ] || [ $has_total -ne 0 ]; then
        incompatibilidades+="- ⚠️ Estructura de \`$tracker_file\` desactualizada (falta columna 'Peso' o fila 'TOTAL')\n"
        propuestas+="- [ ] Migrar MVP-TRACKER.md para incorporar columnas estándar y fila de control de sumas\n"
    fi
fi

# 4. Comprobar secciones en roadmap.md
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

# 5. Analizar git log para sugerir sprint-00-historical.md
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sprint_sugerido+="\n### Agrupación semanal de commits históricos\n\n"
    
    # Procesar commits (hasta 100) agrupándolos por número de semana
    # Usamos date -d para agrupar
    # Formato intermedio: semana | hash | subject
    current_week=""
    
    # Creamos un archivo temporal para procesar
    tmp_log=$(mktemp)
    git log --date=short --format="%ad|%h|%s" -100 > "$tmp_log"
    
    while IFS='|' read -r date hash subject || [ -n "$date" ]; do
        # Saltar si la línea está vacía
        [ -z "$date" ] && continue
        
        # Convertir fecha a semana
        week_num=$(date -d "$date" +%Y-W%V 2>/dev/null)
        [ -z "$week_num" ] && continue
        
        if [ "$week_num" != "$current_week" ]; then
            current_week="$week_num"
            sprint_sugerido+="\n#### Semana $current_week\n"
        fi
        
        # Eliminar posibles corchetes o caracteres extraños que rompan markdown
        clean_subject=$(echo "$subject" | sed 's/|/\\|/g')
        sprint_sugerido+="- [x] Commit \`$hash\` ($date): $clean_subject\n"
    done < "$tmp_log"
    
    rm -f "$tmp_log"
    
    # Añadir propuesta de creación si hay commits históricos
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
