#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/inspect-skills.sh — Auditor estático determinista para skills
# ==============================================================================
# Port adaptado de patrones estáticos de NVIDIA SkillSpector (Stage 1) para
# auditoría de seguridad y confianza en el catálogo .agents/skills/ de Agent OS.
#
# 100% OFFLINE | CERO TOKENS (Sin LLM) | SIN DEPENDENCIAS DE PYTHON 3.12+
#
# Uso:
#   bash scripts/agent/inspect-skills.sh [opciones]
#
# Opciones:
#   --path <dir>       Directorio de skills o skill individual (default: .agents/skills)
#   --baseline <file>  Ruta al archivo baseline de supresión (default: .agents/skills/skill-inspector/baseline.json)
#   --json             Salida estructurada en formato JSON determinista
#   --human            Salida formateada para terminal con reporte visual (por defecto)
#   -h, --help         Muestra este mensaje de ayuda
#
# Gate de severidad (por defecto):
#   - Exit code 0: Conforme. 0 hallazgos CRITICAL/HIGH no suprimidos.
#   - Exit code 1: Gate bloqueado. Al menos un hallazgo CRITICAL o HIGH activo.
#   - Exit code 2: Error de CLI, sintaxis o directorio inexistente.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Integración con cli-help si existe
if [ -f "$SCRIPT_DIR/lib/cli-help.sh" ]; then
  source "$SCRIPT_DIR/lib/cli-help.sh"
fi

show_usage() {
  if command -v show_help >/dev/null 2>&1; then
    show_help "inspect-skills.sh" \
      "bash scripts/agent/inspect-skills.sh [opciones]" \
      "Escanea estáticamente las habilidades (.agents/skills) detectando prompt injection, exfiltración, código peligroso, abuso MCP e higiene de frontmatter. Aplica gate bloqueante para CRITICAL/HIGH." \
      "--path <dir>       Directorio de skills o skill individual (default: .agents/skills)" \
      "--baseline <file>  Archivo de supresión de falsos positivos (default: .agents/skills/skill-inspector/baseline.json)" \
      "--json             Salida en formato JSON estructurado" \
      "--human            Salida interactiva para terminal (default)" \
      "-h, --help         Muestra esta ayuda" \
      "ejemplo: bash scripts/agent/inspect-skills.sh" \
      "ejemplo: bash scripts/agent/inspect-skills.sh --path .agents/skills/remote-admin --json"
  else
    cat << 'EOF'
Uso: bash scripts/agent/inspect-skills.sh [opciones]

Opciones:
  --path <dir>       Directorio de skills o skill individual (default: .agents/skills)
  --baseline <file>  Archivo baseline de supresión (default: .agents/skills/skill-inspector/baseline.json)
  --json             Salida en formato JSON estructurado determinista
  --human            Salida visual para consola (default)
  -h, --help         Muestra este mensaje de ayuda

Exit codes:
  0 = Conforme (0 hallazgos CRITICAL/HIGH activos; LOW/MED no bloquean)
  1 = Bloqueado (≥1 hallazgo CRITICAL o HIGH no suprimido)
  2 = Error de invocación o ruta inválida
EOF
  fi
}

# ------------------------------------------------------------------------------
# 1. Parseo de Argumentos CLI
# ------------------------------------------------------------------------------
TARGET_PATH=".agents/skills"
BASELINE_FILE=".agents/skills/skill-inspector/baseline.json"
OUTPUT_MODE="human"

while [ $# -gt 0 ]; do
  case "$1" in
    --path)
      if [ -n "${2:-}" ]; then
        TARGET_PATH="$2"
        shift 2
      else
        echo "❌ Error: La opción --path requiere una ruta como argumento." >&2
        exit 2
      fi
      ;;
    --path=*)
      TARGET_PATH="${1#*=}"
      shift
      ;;
    --baseline)
      if [ -n "${2:-}" ]; then
        BASELINE_FILE="$2"
        shift 2
      else
        echo "❌ Error: La opción --baseline requiere una ruta como argumento." >&2
        exit 2
      fi
      ;;
    --baseline=*)
      BASELINE_FILE="${1#*=}"
      shift
      ;;
    --json)
      OUTPUT_MODE="json"
      shift
      ;;
    --human)
      OUTPUT_MODE="human"
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "❌ Error: Opción desconocida: $1" >&2
      show_usage
      exit 2
      ;;
  esac
done

# Validar dependencias básicas POSIX
for cmd in bash grep sed awk find; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Error: Comando requerido no disponible en PATH: $cmd" >&2
    exit 2
  fi
done

if [ ! -e "$TARGET_PATH" ]; then
  echo "❌ Error: La ruta objetivo no existe: $TARGET_PATH" >&2
  exit 2
fi

# ------------------------------------------------------------------------------
# 2. Mecanismo de Baseline y Supresiones
# ------------------------------------------------------------------------------
# Comprueba si un fingerprint está registrado en el baseline
is_suppressed() {
  local fp="$1"
  if [ -f "$BASELINE_FILE" ]; then
    # Búsqueda determinista sin requerir jq:
    # 1. Si jq está disponible, verificación exacta
    if command -v jq >/dev/null 2>&1; then
      if jq -e --arg fp "$fp" '.suppressions[]? | select(.fingerprint == $fp)' "$BASELINE_FILE" >/dev/null 2>&1; then
        return 0
      fi
    else
      # Fallback portable en grep puro
      if grep -q "\"fingerprint\"[[:space:]]*:[[:space:]]*\"$fp\"" "$BASELINE_FILE" 2>/dev/null; then
        return 0
      fi
    fi
  fi
  return 1
}

# ------------------------------------------------------------------------------
# 3. Descubrimiento de Skills a Escanear
# ------------------------------------------------------------------------------
SKILL_DIRS=()
if [ -f "$TARGET_PATH/SKILL.md" ]; then
  # Se pasó una skill individual
  SKILL_DIRS+=("$TARGET_PATH")
elif [ -d "$TARGET_PATH" ]; then
  # Se pasó un directorio de skills
  while IFS= read -r dir; do
    if [ -n "$dir" ] && [ -d "$dir" ]; then
      SKILL_DIRS+=("$dir")
    fi
  done < <(find "$TARGET_PATH" -mindepth 1 -maxdepth 1 -type d | sort)
fi

if [ "${#SKILL_DIRS[@]}" -eq 0 ]; then
  echo "⚠️ Advertencia: No se encontraron directorios de skills en: $TARGET_PATH" >&2
fi

# ------------------------------------------------------------------------------
# 4. Definición de Patrones y Analizadores Estáticos
# ------------------------------------------------------------------------------
# Familias estáticas (Stage 1 NVIDIA SkillSpector):
# 1) PROMPT_INJECTION
# 2) DATA_EXFILTRATION
# 3) DANGEROUS_CODE
# 4) MCP_POISONING
# Higiene del catálogo:
# 5) SKILL_HYGIENE (LOW, no bloqueante)

TMP_FINDINGS="$(mktemp)"
trap 'rm -f "$TMP_FINDINGS"' EXIT

# Formato de registro en TMP_FINDINGS:
# skill|category|severity|rule_id|file_rel|line|message|suppressed(0/1)

record_finding() {
  local skill="$1"
  local cat="$2"
  local sev="$3"
  local rule="$4"
  local frel="$5"
  local line="$6"
  local msg="$7"
  
  local fp="${skill}:${cat}:${frel}:${rule}"
  local supp=0
  if is_suppressed "$fp"; then
    supp=1
  fi

  echo "${skill}|${cat}|${sev}|${rule}|${frel}|${line}|${msg}|${supp}" >> "$TMP_FINDINGS"
}

# Escaneo de Higiene (SKILL_HYGIENE) - Severidad LOW (No bloqueante)
check_hygiene() {
  local sdir="$1"
  local sname="$2"
  local smd="$sdir/SKILL.md"

  if [ ! -f "$smd" ]; then
    record_finding "$sname" "SKILL_HYGIENE" "LOW" "HYGIENE_MISSING_SKILL_MD" "SKILL.md" 0 "Archivo SKILL.md no encontrado en el directorio de la skill"
    return
  fi

  if [ ! -s "$smd" ]; then
    record_finding "$sname" "SKILL_HYGIENE" "LOW" "HYGIENE_EMPTY_FILE" "SKILL.md" 0 "Archivo SKILL.md está vacío (0 bytes)"
    return
  fi

  # Validar encabezado YAML
  local line1
  line1=$(head -n 1 "$smd" 2>/dev/null || echo "")
  if [ "$line1" != "---" ]; then
    record_finding "$sname" "SKILL_HYGIENE" "LOW" "HYGIENE_NO_FRONTMATTER" "SKILL.md" 1 "SKILL.md carece de delimitador frontmatter inicial (---)"
  else
    # Comprobar name y description en las primeras 35 líneas
    local head_content
    head_content=$(head -n 35 "$smd" 2>/dev/null)
    if ! echo "$head_content" | grep -q "^name:"; then
      record_finding "$sname" "SKILL_HYGIENE" "LOW" "HYGIENE_MISSING_NAME" "SKILL.md" 1 "Frontmatter carece de propiedad obligatoria 'name:'"
    fi
    if ! echo "$head_content" | grep -q "^description:"; then
      record_finding "$sname" "SKILL_HYGIENE" "LOW" "HYGIENE_MISSING_DESC" "SKILL.md" 1 "Frontmatter carece de propiedad obligatoria 'description:'"
    fi
  fi
}

# Escaneo de Patrones Estáticos de Seguridad en Archivos
check_static_patterns() {
  local sdir="$1"
  local sname="$2"

  # Iterar sobre archivos legibles dentro de la skill (.md, .sh, .py, .js, .ts, etc.)
  # Excluir binarios, .git, carpetas vendor/node_modules y archivos > 1MB
  while IFS= read -r file; do
    [ -f "$file" ] || continue
    
    # Comprobar tamaño (máx 1MB)
    local fsize
    fsize=$(wc -c < "$file" 2>/dev/null || echo 0)
    if [ "$fsize" -gt 1048576 ]; then
      continue
    fi

    local frel="${file#$sdir/}"

    # --------------------------------------------------------------------------
    # FAMILIA 1: PROMPT_INJECTION (CRITICAL / HIGH)
    # --------------------------------------------------------------------------
    # INJ_IGNORE_INSTRUCTIONS (CRITICAL)
    # Evasión explícita de instrucciones o directivas previas
    local m_inj_ign
    m_inj_ign=$(grep -nEI "\b(ignore|disregard)[[:space:]]+(all[[:space:]]+)?(previous|prior|above)[[:space:]]+(instructions|directives|rules|prompts)\b|\bignora[[:space:]]+(todas[[:space:]]+las[[:space:]]+)?instrucciones[[:space:]]+(anteriores|previas)\b" "$file" 2>/dev/null || true)
    if [ -n "$m_inj_ign" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "PROMPT_INJECTION" "CRITICAL" "INJ_IGNORE_INSTRUCTIONS" "$frel" "$lnum" "Directiva de evasión o anulación de instrucciones previas detectada"
      done <<< "$m_inj_ign"
    fi

    # INJ_ROLE_OVERRIDE (CRITICAL)
    # Intento de forzar modo sin restricciones o jailbreak
    local m_inj_role
    m_inj_role=$(grep -nEI "\byou[[:space:]]+are[[:space:]]+now[[:space:]]+in[[:space:]]+(developer|unrestricted|god|dan)[[:space:]]+mode\b|\bahora[[:space:]]+est[aá]s[[:space:]]+en[[:space:]]+modo[[:space:]]+(desarrollador|sin[[:space:]]+restricciones|dios)\b|\b(jailbreak|DAN)[[:space:]]+prompt\b" "$file" 2>/dev/null || true)
    if [ -n "$m_inj_role" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "PROMPT_INJECTION" "CRITICAL" "INJ_ROLE_OVERRIDE" "$frel" "$lnum" "Intento de override de rol o activación de modo sin restricciones (jailbreak)"
      done <<< "$m_inj_role"
    fi

    # INJ_SYSTEM_TAGS (HIGH)
    # Inyección de delimitadores de sistema o pseudo-roles
    local m_inj_tags
    m_inj_tags=$(grep -nEI "<[[:space:]]*(system|instruction|human|assistant)[[:space:]]*>" "$file" 2>/dev/null || true)
    if [ -n "$m_inj_tags" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "PROMPT_INJECTION" "HIGH" "INJ_SYSTEM_TAGS" "$frel" "$lnum" "Inyección de tags de rol/sistema para eludir aislamiento de contexto"
      done <<< "$m_inj_tags"
    fi

    # --------------------------------------------------------------------------
    # FAMILIA 2: DATA_EXFILTRATION (CRITICAL / HIGH)
    # --------------------------------------------------------------------------
    # EXFIL_CREDENTIAL_PIPE (CRITICAL)
    # Transmisión de credenciales o tokens a destinos externos
    local m_exfil_cred
    m_exfil_cred=$(grep -nEI "curl[[:space:]]+.*(-d|--data|-F|--form).*(\\\$|%)(TOKEN|SECRET|KEY|PASSWORD|AUTH|CREDENTIAL|PRIVATE).*https?://" "$file" 2>/dev/null || true)
    if [ -n "$m_exfil_cred" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DATA_EXFILTRATION" "CRITICAL" "EXFIL_CREDENTIAL_PIPE" "$frel" "$lnum" "Envío no autorizado de credenciales en payload HTTP hacia URL externa"
      done <<< "$m_exfil_cred"
    fi

    # EXFIL_ENV_DUMP (CRITICAL)
    # Volcado de variables de entorno a red
    local m_exfil_dump
    m_exfil_dump=$(grep -nEI "\b(env|printenv)[[:space:]]*\|[[:space:]]*(curl|wget|nc)\b" "$file" 2>/dev/null || true)
    if [ -n "$m_exfil_dump" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DATA_EXFILTRATION" "CRITICAL" "EXFIL_ENV_DUMP" "$frel" "$lnum" "Tubería de volcado de variables de entorno hacia herramienta de red"
      done <<< "$m_exfil_dump"
    fi

    # EXFIL_SUSPICIOUS_ENDPOINT (HIGH)
    # Uso de servicios de pastebin / tunneling / webhook externos
    local m_exfil_end
    m_exfil_end=$(grep -nEI "https?://(pastebin\.com|webhook\.site|requestbin\.(com|net)|pipedream\.net|ngrok\.io|burpcollaborator\.net)" "$file" 2>/dev/null || true)
    if [ -n "$m_exfil_end" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DATA_EXFILTRATION" "HIGH" "EXFIL_SUSPICIOUS_ENDPOINT" "$frel" "$lnum" "Referencia a endpoint sospechoso comúnmente asociado a exfiltración"
      done <<< "$m_exfil_end"
    fi

    # EXFIL_RAW_SOCKET (HIGH)
    # Socket crudo de netcat hacia dirección IP
    local m_exfil_nc
    m_exfil_nc=$(grep -nEI "\bnc\b[[:space:]]+(-[a-zA-Z0-9]+[[:space:]]+)*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}[[:space:]]+[0-9]+" "$file" 2>/dev/null || true)
    if [ -n "$m_exfil_nc" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DATA_EXFILTRATION" "HIGH" "EXFIL_RAW_SOCKET" "$frel" "$lnum" "Conexión socket arbitraria netcat directa a dirección IP numérica"
      done <<< "$m_exfil_nc"
    fi

    # --------------------------------------------------------------------------
    # FAMILIA 3: DANGEROUS_CODE (CRITICAL / HIGH)
    # --------------------------------------------------------------------------
    # CODE_REMOTE_PIPE (CRITICAL)
    # Descarga directa y ejecución en intérprete
    local m_code_pipe
    m_code_pipe=$(grep -nEI "(curl|wget)[[:space:]]+[^|]*\|[[:space:]]*(bash|sh|zsh|python|perl)" "$file" 2>/dev/null || true)
    if [ -n "$m_code_pipe" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DANGEROUS_CODE" "CRITICAL" "CODE_REMOTE_PIPE" "$frel" "$lnum" "Descarga y ejecución directa de script remoto en shell sin verificación"
      done <<< "$m_code_pipe"
    fi

    # CODE_DESTRUCTIVE_ROOT (CRITICAL)
    # Comandos destructivos sobre raíz o directorios críticos
    local m_code_destruct
    m_code_destruct=$(grep -nEI "rm[[:space:]]+-[rfRF]+[[:space:]]+(/|\*|/\*|\$HOME|\${HOME})([[:space:]]|$)|:\(\)\{\s*:\|:&\s*\};:" "$file" 2>/dev/null || true)
    if [ -n "$m_code_destruct" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DANGEROUS_CODE" "CRITICAL" "CODE_DESTRUCTIVE_ROOT" "$frel" "$lnum" "Comando destructivo irreversible o fork bomb detectado"
      done <<< "$m_code_destruct"
    fi

    # CODE_OBFUSCATED_EXEC (CRITICAL)
    # Ejecución de payload decodificado al vuelo
    local m_code_obf
    m_code_obf=$(grep -nEI "base64[[:space:]]+-[dD].*\|[[:space:]]*(bash|sh|python)" "$file" 2>/dev/null || true)
    if [ -n "$m_code_obf" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DANGEROUS_CODE" "CRITICAL" "CODE_OBFUSCATED_EXEC" "$frel" "$lnum" "Ejecución de payload ofuscado en base64 conectado a intérprete"
      done <<< "$m_code_obf"
    fi

    # CODE_BLIND_EVAL (HIGH)
    # Uso de eval sobre parámetros o variables
    local m_code_eval
    m_code_eval=$(grep -nEI "eval[[:space:]]+(\\\$|\"\\\$|'\\\$)" "$file" 2>/dev/null || true)
    if [ -n "$m_code_eval" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DANGEROUS_CODE" "HIGH" "CODE_BLIND_EVAL" "$frel" "$lnum" "Evaluación ciega (eval) de variables dinámicas"
      done <<< "$m_code_eval"
    fi

    # CODE_PYTHON_SUBPROCESS_SHELL (HIGH)
    # Subprocess de python con shell=True
    local m_code_py
    m_code_py=$(grep -nEI "subprocess\.(run|call|Popen)\(.*\bshell\s*=\s*True\b" "$file" 2>/dev/null || true)
    if [ -n "$m_code_py" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "DANGEROUS_CODE" "HIGH" "CODE_PYTHON_SUBPROCESS_SHELL" "$frel" "$lnum" "Invocación de subproceso Python con shell=True sin saneamiento estricto"
      done <<< "$m_code_py"
    fi

    # --------------------------------------------------------------------------
    # FAMILIA 4: MCP_POISONING (HIGH)
    # --------------------------------------------------------------------------
    # MCP_TOOL_HIJACK (HIGH)
    # Directiva que intenta secuestrar o suplantar llamadas MCP
    local m_mcp_hijack
    m_mcp_hijack=$(grep -nEI "(intercept|hijack)[[:space:]]+(all[[:space:]]+)?(mcp|tool)[[:space:]]+(calls|invocations)|pretend[[:space:]]+to[[:space:]]+be[[:space:]]+(the[[:space:]]+)?(mcp|tool)" "$file" 2>/dev/null || true)
    if [ -n "$m_mcp_hijack" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "MCP_POISONING" "HIGH" "MCP_TOOL_HIJACK" "$frel" "$lnum" "Instrucción de suplantación o secuestro de invocaciones de herramientas MCP"
      done <<< "$m_mcp_hijack"
    fi

    # MCP_CONFIRM_BYPASS (HIGH)
    # Omitir confirmación de usuario explícita en acciones de riesgo
    local m_mcp_bypass
    m_mcp_bypass=$(grep -nEI "(never[[:space:]]+ask[[:space:]]+confirmation|bypass[[:space:]]+user[[:space:]]+confirmation)[[:space:]]+.*(tool|delete|execute|command)" "$file" 2>/dev/null || true)
    if [ -n "$m_mcp_bypass" ]; then
      while IFS=: read -r lnum rest; do
        record_finding "$sname" "MCP_POISONING" "HIGH" "MCP_CONFIRM_BYPASS" "$frel" "$lnum" "Directiva que ordena omitir la confirmación humana de herramientas de riesgo"
      done <<< "$m_mcp_bypass"
    fi

  done < <(find "$sdir" -type f ! -path '*/.*' ! -path '*/node_modules/*' ! -path '*/vendor/*')
}

# ------------------------------------------------------------------------------
# 5. Ejecutar Análisis
# ------------------------------------------------------------------------------
for sdir in "${SKILL_DIRS[@]}"; do
  sname=$(basename "$sdir")
  check_hygiene "$sdir" "$sname"
  check_static_patterns "$sdir" "$sname"
done

# ------------------------------------------------------------------------------
# 6. Cálculo de Scores y Gate de Severidad
# ------------------------------------------------------------------------------
# Puntuación por skill: Base 100
# Deducciones de hallazgos NO suprimidos:
#   CRITICAL: -40
#   HIGH:     -20
#   MED:      -10
#   LOW:      -5
# Gate de severidad por defecto:
#   Bloquea (exit 1) si hay ≥1 hallazgo CRITICAL o HIGH activo (no suprimido).
#   LOW y MED no bloquean nunca por defecto.

TOTAL_SKILLS="${#SKILL_DIRS[@]}"
TOTAL_FINDINGS=0
UNSUPPRESSED_FINDINGS=0
SUPPRESSED_FINDINGS=0
COUNT_CRITICAL=0
COUNT_HIGH=0
COUNT_MED=0
COUNT_LOW=0

UNSUPP_CRITICAL=0
UNSUPP_HIGH=0
UNSUPP_MED=0
UNSUPP_LOW=0

# Acumulador por skill para scoring
declare -A SKILL_DEDUCTIONS
declare -A SKILL_FINDINGS_COUNT
for sdir in "${SKILL_DIRS[@]}"; do
  sname=$(basename "$sdir")
  SKILL_DEDUCTIONS["$sname"]=0
  SKILL_FINDINGS_COUNT["$sname"]=0
done

if [ -s "$TMP_FINDINGS" ]; then
  while IFS='|' read -r skill cat sev rule frel line msg supp; do
    TOTAL_FINDINGS=$((TOTAL_FINDINGS + 1))
    SKILL_FINDINGS_COUNT["$skill"]=$(( ${SKILL_FINDINGS_COUNT["$skill"]} + 1 ))

    case "$sev" in
      CRITICAL) COUNT_CRITICAL=$((COUNT_CRITICAL + 1)) ;;
      HIGH)     COUNT_HIGH=$((COUNT_HIGH + 1)) ;;
      MED)      COUNT_MED=$((COUNT_MED + 1)) ;;
      LOW)      COUNT_LOW=$((COUNT_LOW + 1)) ;;
    esac

    if [ "$supp" -eq 1 ]; then
      SUPPRESSED_FINDINGS=$((SUPPRESSED_FINDINGS + 1))
    else
      UNSUPPRESSED_FINDINGS=$((UNSUPPRESSED_FINDINGS + 1))
      case "$sev" in
        CRITICAL)
          UNSUPP_CRITICAL=$((UNSUPP_CRITICAL + 1))
          SKILL_DEDUCTIONS["$skill"]=$(( ${SKILL_DEDUCTIONS["$skill"]} + 40 ))
          ;;
        HIGH)
          UNSUPP_HIGH=$((UNSUPP_HIGH + 1))
          SKILL_DEDUCTIONS["$skill"]=$(( ${SKILL_DEDUCTIONS["$skill"]} + 20 ))
          ;;
        MED)
          UNSUPP_MED=$((UNSUPP_MED + 1))
          SKILL_DEDUCTIONS["$skill"]=$(( ${SKILL_DEDUCTIONS["$skill"]} + 10 ))
          ;;
        LOW)
          UNSUPP_LOW=$((UNSUPP_LOW + 1))
          SKILL_DEDUCTIONS["$skill"]=$(( ${SKILL_DEDUCTIONS["$skill"]} + 5 ))
          ;;
      esac
    fi
  done < "$TMP_FINDINGS"
fi

# Calcular score promedio
SUM_SCORES=0
for sdir in "${SKILL_DIRS[@]}"; do
  sname=$(basename "$sdir")
  ded="${SKILL_DEDUCTIONS["$sname"]}"
  sc=$(( 100 - ded ))
  if [ "$sc" -lt 0 ]; then
    sc=0
  fi
  SUM_SCORES=$((SUM_SCORES + sc))
done

AVG_SCORE=100
if [ "$TOTAL_SKILLS" -gt 0 ]; then
  AVG_SCORE=$(awk -v sum="$SUM_SCORES" -v total="$TOTAL_SKILLS" 'BEGIN { printf "%.1f", sum / total }')
fi

# Veredicto del Gate
GATE_PASSED=true
BLOCKER_COUNT=$((UNSUPP_CRITICAL + UNSUPP_HIGH))
if [ "$BLOCKER_COUNT" -gt 0 ]; then
  GATE_PASSED=false
fi

# ------------------------------------------------------------------------------
# 7. Emisión de Resultados
# ------------------------------------------------------------------------------
if [ "$OUTPUT_MODE" = "json" ]; then
  # Salida JSON Determinista
  cat << EOF
{
  "version": "1.0.0",
  "target_path": "$TARGET_PATH",
  "baseline_file": "$BASELINE_FILE",
  "summary": {
    "skills_scanned": $TOTAL_SKILLS,
    "total_findings": $TOTAL_FINDINGS,
    "unsuppressed_findings": $UNSUPPRESSED_FINDINGS,
    "suppressed_findings": $SUPPRESSED_FINDINGS,
    "unsuppressed_critical": $UNSUPP_CRITICAL,
    "unsuppressed_high": $UNSUPP_HIGH,
    "unsuppressed_med": $UNSUPP_MED,
    "unsuppressed_low": $UNSUPP_LOW,
    "blocker_count": $BLOCKER_COUNT,
    "average_score": $AVG_SCORE,
    "gate_passed": $GATE_PASSED
  },
  "findings": [
EOF
  FIRST_ITEM=true
  if [ -s "$TMP_FINDINGS" ]; then
    while IFS='|' read -r skill cat sev rule frel line msg supp; do
      [ "$FIRST_ITEM" = true ] && FIRST_ITEM=false || echo ","
      is_supp_bool="false"
      [ "$supp" -eq 1 ] && is_supp_bool="true"
      cat << ITEM
    {
      "skill": "$skill",
      "category": "$cat",
      "severity": "$sev",
      "rule_id": "$rule",
      "file": "$frel",
      "line": $line,
      "message": "$msg",
      "fingerprint": "${skill}:${cat}:${frel}:${rule}",
      "suppressed": $is_supp_bool
    }
ITEM
    done < "$TMP_FINDINGS"
  fi
  echo ""
  echo "  ]"
  echo "}"

else
  # Salida Humana para Consola
  echo "=============================================================================="
  echo "  🛡️  AGENT OS — INSPECTOR ESTÁTICO DE SKILLS (Port NVIDIA SkillSpector)"
  echo "=============================================================================="
  echo "  Target:   $TARGET_PATH ($TOTAL_SKILLS skills analizadas)"
  echo "  Baseline: $BASELINE_FILE"
  echo "  Score:    $AVG_SCORE / 100"
  echo "------------------------------------------------------------------------------"

  if [ "$TOTAL_FINDINGS" -eq 0 ]; then
    echo "  ✅ Catálogo limpio: 0 hallazgos detectados."
  else
    echo "  📋 Hallazgos encontrados ($TOTAL_FINDINGS total | $UNSUPPRESSED_FINDINGS activos | $SUPPRESSED_FINDINGS suprimidos):"
    echo ""
    while IFS='|' read -r skill cat sev rule frel line msg supp; do
      local_icon="ℹ️"
      case "$sev" in
        CRITICAL) local_icon="🔴" ;;
        HIGH)     local_icon="🟠" ;;
        MED)      local_icon="🟡" ;;
        LOW)      local_icon="🔵" ;;
      esac

      status_label=""
      if [ "$supp" -eq 1 ]; then
        status_label="[SUPPRESSED] "
        local_icon="⚪"
      fi

      echo "  $local_icon $status_label[$sev] $skill → $frel:$line ($rule)"
      echo "     Categoría: $cat"
      echo "     Detalle:   $msg"
      echo "     Fingerprint: ${skill}:${cat}:${frel}:${rule}"
      echo ""
    done < "$TMP_FINDINGS"
  fi

  echo "------------------------------------------------------------------------------"
  echo "  RESUMEN DE SEVERIDAD ACTIVA (Gate):"
  echo "    🔴 CRITICAL: $UNSUPP_CRITICAL"
  echo "    🟠 HIGH:     $UNSUPP_HIGH"
  echo "    🟡 MED:      $UNSUPP_MED"
  echo "    🔵 LOW:      $UNSUPP_LOW"
  echo "    ⚪ SUPPRESSED (Baseline): $SUPPRESSED_FINDINGS"
  echo "------------------------------------------------------------------------------"

  if [ "$GATE_PASSED" = true ]; then
    echo "  ✅ GATE PASADO: 0 hallazgos bloqueantes (CRITICAL/HIGH no suprimidos)."
    if [ "$UNSUPP_LOW" -gt 0 ] || [ "$UNSUPP_MED" -gt 0 ]; then
      echo "  ℹ️  Advertencias leves detectadas (LOW/MED): no bloquean por defecto."
    fi
  else
    echo "  ❌ GATE BLOQUEADO: $BLOCKER_COUNT hallazgo(s) bloqueante(s) (CRITICAL o HIGH no suprimidos)."
    echo "     Para resolver:"
    echo "     1. Corrige el código o prompt vulnerable en la skill."
    echo "     2. O si es un falso positivo justificado, regístralo en $BASELINE_FILE."
  fi
  echo "=============================================================================="
fi

# Exit codes según contrato del gate:
# 0 = Conforme (sin CRITICAL/HIGH activos)
# 1 = Bloqueado (≥1 CRITICAL o HIGH activo)
if [ "$GATE_PASSED" = true ]; then
  exit 0
else
  exit 1
fi
