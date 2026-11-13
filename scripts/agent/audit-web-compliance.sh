#!/usr/bin/env bash
# ==============================================================================
# audit-web-compliance.sh — Auditoría determinista de cumplimiento web y seguridad
# ==============================================================================
# Uso: bash scripts/agent/audit-web-compliance.sh [--path <dir>] [--json] [--strict]
#
# Inspecciona estáticamente un satélite web (Next.js, React, HTML) a coste $0
# verificando:
#   1. Cookies & CMP: Detección de trackers de terceros vs CMP (vanilla-cookieconsent).
#   2. Páginas Legales: Conformidad LSSI-CE y RGPD (/aviso-legal, /politica-privacidad, /politica-cookies).
#   3. Cabeceras HTTP: CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy.
#   4. Higiene SEO: robots.txt y sitemap.xml.
#
# Salida determinista y sin red.
# ==============================================================================

set -euo pipefail

SCRIPT_SRC="${BASH_SOURCE[0]}"
case "$SCRIPT_SRC" in
  /*) ;;
  *) SCRIPT_SRC="$PWD/$SCRIPT_SRC" ;;
esac
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SRC")" && pwd -P)"
CORE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

# shellcheck source=scripts/agent/lib/cli-help.sh
if [ -f "$SCRIPT_DIR/lib/cli-help.sh" ]; then
  source "$SCRIPT_DIR/lib/cli-help.sh"
else
  show_help() { echo "Uso: $2"; exit 0; }
fi

TARGET_DIR="."
JSON_MODE=false
STRICT_MODE=false

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help "audit-web-compliance.sh" \
        "bash scripts/agent/audit-web-compliance.sh [--path <dir>] [--json] [--strict]" \
        "Audita estaticamente a coste \$0 el cumplimiento normativo web (cookies, AEPD, paginas legales LSSI/RGPD y cabeceras HTTP de seguridad)." \
        "--path <dir>     Ruta al directorio de la aplicacion web satelite (defecto: .)" \
        "--json           Emite el reporte estructurado en formato JSON" \
        "--strict         Devuelve codigo de salida 1 ante cualquier advertencia o ausencia legal" \
        "-h, --help       Muestra este mensaje de ayuda" \
        "ejemplo: bash scripts/agent/audit-web-compliance.sh --path ~/Proyectos/mi-web" \
        "ejemplo: bash scripts/agent/audit-web-compliance.sh --json --strict"
      ;;
    --path)
      if [ $# -lt 2 ]; then
        echo "❌ ERROR: --path requiere una ruta de directorio." >&2
        exit 2
      fi
      TARGET_DIR="$2"
      shift 2
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --strict)
      STRICT_MODE=true
      shift
      ;;
    *)
      if [ -d "$1" ]; then
        TARGET_DIR="$1"
        shift
      else
        echo "❌ ERROR: Argumento desconocido o directorio inexistente: $1" >&2
        exit 2
      fi
      ;;
  esac
done

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd -P || echo "$TARGET_DIR")"

if [ ! -d "$TARGET_DIR" ]; then
  if [ "$JSON_MODE" = true ]; then
    echo "{\"error\": \"Directorio no encontrado: $TARGET_DIR\", \"status\": \"ERROR\"}"
  else
    echo "❌ ERROR: El directorio especificado no existe: $TARGET_DIR" >&2
  fi
  exit 2
fi

# ==============================================================================
# Variables de Diagnóstico
# ==============================================================================
TRACKERS_DETECTED=()
HAS_CMP=false
CMP_TYPE="none"

HAS_AVISO_LEGAL=false
HAS_POLITICA_PRIVACIDAD=false
HAS_POLITICA_COOKIES=false

HAS_CSP=false
HAS_HSTS=false
HAS_X_FRAME=false
HAS_NOSNIFF=false
HAS_REFERRER=false

HAS_ROBOTS=false
HAS_SITEMAP=false

VIOLATIONS=()
WARNINGS=()
RECOMMENDATIONS=()

# ==============================================================================
# 1. Inspección de Cookies & CMP
# ==============================================================================
# Detectar CMP en package.json o código
if [ -f "$TARGET_DIR/package.json" ]; then
  if grep -qi "vanilla-cookieconsent" "$TARGET_DIR/package.json"; then
    HAS_CMP=true
    CMP_TYPE="vanilla-cookieconsent"
  elif grep -qiE "cookieconsent|react-cookie-consent|cookie-consent" "$TARGET_DIR/package.json"; then
    HAS_CMP=true
    CMP_TYPE="generic-cmp"
  fi
fi

# Si no se detectó en package.json, buscar en código fuente
if [ "$HAS_CMP" = false ]; then
  if grep -rnEIq "CookieConsent\.run|data-cc=|vanilla-cookieconsent" \
    --exclude-dir={node_modules,.next,.git,dist,build,.agents} "$TARGET_DIR" 2>/dev/null; then
    HAS_CMP=true
    CMP_TYPE="vanilla-cookieconsent (code)"
  elif grep -rnEIq "cookieconsent|CookieBanner" \
    --exclude-dir={node_modules,.next,.git,dist,build,.agents} "$TARGET_DIR" 2>/dev/null; then
    HAS_CMP=true
    CMP_TYPE="custom-cmp (code)"
  fi
fi

# Detectar trackers externos
if grep -rnEIq "calendly\.com|assets\.calendly\.com" \
  --exclude-dir={node_modules,.next,.git,dist,build,.agents} "$TARGET_DIR" 2>/dev/null; then
  TRACKERS_DETECTED+=("calendly")
fi

if grep -rnEIq "googletagmanager\.com|google-analytics\.com|gtag\(" \
  --exclude-dir={node_modules,.next,.git,dist,build,.agents} "$TARGET_DIR" 2>/dev/null; then
  TRACKERS_DETECTED+=("google-analytics")
fi

if grep -rnEIq "connect\.facebook\.net|fbq\(" \
  --exclude-dir={node_modules,.next,.git,dist,build,.agents} "$TARGET_DIR" 2>/dev/null; then
  TRACKERS_DETECTED+=("meta-pixel")
fi

if grep -rnEIq "clarity\.ms" \
  --exclude-dir={node_modules,.next,.git,dist,build,.agents} "$TARGET_DIR" 2>/dev/null; then
  TRACKERS_DETECTED+=("ms-clarity")
fi

if grep -rnEIq "hotjar\.com" \
  --exclude-dir={node_modules,.next,.git,dist,build,.agents} "$TARGET_DIR" 2>/dev/null; then
  TRACKERS_DETECTED+=("hotjar")
fi

if [ ${#TRACKERS_DETECTED[@]} -gt 0 ] && [ "$HAS_CMP" = false ]; then
  VIOLATIONS+=("Detectados scripts de terceros (${TRACKERS_DETECTED[*]}) sin sistema de consentimiento de cookies (CMP) conforme a la AEPD/RGPD.")
  RECOMMENDATIONS+=("Instalar 'vanilla-cookieconsent' v3 e inyectar CookieBanner en layout principal (.agents/skills/web-compliance/).")
elif [ "$HAS_CMP" = false ]; then
  WARNINGS+=("No se detectó banner de consentimiento ni CMP activo en el proyecto.")
  RECOMMENDATIONS+=("Si la web utiliza analíticas o cookies en producción, implementar CMP simétrico.")
fi

# ==============================================================================
# 2. Inspección de Páginas Legales Obligatorias
# ==============================================================================
# Aviso Legal (LSSI-CE)
if find "$TARGET_DIR" -maxdepth 4 -type f \( -iname "*aviso-legal*" -o -iname "*legal-notice*" \) \
  ! -path "*/node_modules/*" ! -path "*/.next/*" ! -path "*/.git/*" ! -path "*/.agents/*" | grep -q .; then
  HAS_AVISO_LEGAL=true
fi

# Política de Privacidad (RGPD)
if find "$TARGET_DIR" -maxdepth 4 -type f \( -iname "*politica-privacidad*" -o -iname "*privacy-policy*" -o -iname "*privacidad*" \) \
  ! -path "*/node_modules/*" ! -path "*/.next/*" ! -path "*/.git/*" ! -path "*/.agents/*" | grep -q .; then
  HAS_POLITICA_PRIVACIDAD=true
fi

# Política de Cookies (ePrivacy)
if find "$TARGET_DIR" -maxdepth 4 -type f \( -iname "*politica-cookies*" -o -iname "*cookie-policy*" -o -iname "*cookies.tsx" -o -iname "*cookies.jsx" -o -iname "*cookies.html" \) \
  ! -path "*/node_modules/*" ! -path "*/.next/*" ! -path "*/.git/*" ! -path "*/.agents/*" | grep -q .; then
  HAS_POLITICA_COOKIES=true
fi

if [ "$HAS_AVISO_LEGAL" = false ]; then
  VIOLATIONS+=("Falta la página obligatoria de Aviso Legal (/aviso-legal) exigida por la LSSI-CE art. 10.")
  RECOMMENDATIONS+=("Crear app/aviso-legal/page.tsx usando la plantilla de web-compliance.")
fi

if [ "$HAS_POLITICA_PRIVACIDAD" = false ]; then
  VIOLATIONS+=("Falta la página obligatoria de Política de Privacidad (/politica-privacidad) exigida por el RGPD art. 13.")
  RECOMMENDATIONS+=("Crear app/politica-privacidad/page.tsx con información de responsable, derechos y fines.")
fi

if [ "$HAS_POLITICA_COOKIES" = false ]; then
  VIOLATIONS+=("Falta la página obligatoria de Política de Cookies (/politica-cookies) exigida por la directiva ePrivacy.")
  RECOMMENDATIONS+=("Crear app/politica-cookies/page.tsx con tabla de cookies y mecanismo de revocación.")
fi

# ==============================================================================
# 3. Inspección de Cabeceras HTTP de Seguridad
# ==============================================================================
CONFIG_FILES=$(find "$TARGET_DIR" -maxdepth 2 -type f \( -name "next.config.*" -o -name "vite.config.*" -o -name "astro.config.*" -o -name "nginx.conf" -o -name "vercel.json" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null || true)

if [ -n "$CONFIG_FILES" ]; then
  if grep -rq "Content-Security-Policy" $CONFIG_FILES 2>/dev/null; then
    HAS_CSP=true
  fi
  if grep -rq "Strict-Transport-Security" $CONFIG_FILES 2>/dev/null; then
    HAS_HSTS=true
  fi
  if grep -rq "X-Frame-Options" $CONFIG_FILES 2>/dev/null; then
    HAS_X_FRAME=true
  fi
  if grep -rq "X-Content-Type-Options" $CONFIG_FILES 2>/dev/null; then
    HAS_NOSNIFF=true
  fi
  if grep -rq "Referrer-Policy" $CONFIG_FILES 2>/dev/null; then
    HAS_REFERRER=true
  fi
fi

if [ "$HAS_CSP" = false ] || [ "$HAS_HSTS" = false ] || [ "$HAS_X_FRAME" = false ] || [ "$HAS_NOSNIFF" = false ]; then
  WARNINGS+=("Faltan una o varias cabeceras de endurecimiento HTTP en la configuración del servidor/framework.")
  RECOMMENDATIONS+=("Inyectar securityHeaders en next.config.* desde .agents/skills/web-compliance/templates/security-headers.snippet.ts.")
fi

# ==============================================================================
# 4. Inspección de Higiene SEO / Descubrimiento
# ==============================================================================
if find "$TARGET_DIR" -maxdepth 3 -type f \( -name "robots.txt" -o -name "robots.ts" -o -name "robots.js" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | grep -q .; then
  HAS_ROBOTS=true
fi

if find "$TARGET_DIR" -maxdepth 3 -type f \( -name "sitemap.xml" -o -name "sitemap.ts" -o -name "sitemap.js" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | grep -q .; then
  HAS_SITEMAP=true
fi

if [ "$HAS_ROBOTS" = false ]; then
  WARNINGS+=("No se detectó archivo robots.txt o generador app/robots.ts.")
  RECOMMENDATIONS+=("Añadir robots.txt o app/robots.ts para guiar la indexación.")
fi

if [ "$HAS_SITEMAP" = false ]; then
  WARNINGS+=("No se detectó sitemap.xml o generador app/sitemap.ts.")
  RECOMMENDATIONS+=("Añadir sitemap.xml para optimizar la descubribilidad por motores de búsqueda.")
fi

# ==============================================================================
# Cálculo de Puntuación y Veredicto
# ==============================================================================
SCORE=100
VIOLATION_PENALTY=25
WARNING_PENALTY=5

PENALTY=$(( (${#VIOLATIONS[@]} * VIOLATION_PENALTY) + (${#WARNINGS[@]} * WARNING_PENALTY) ))
SCORE=$(( SCORE - PENALTY ))
if [ "$SCORE" -lt 0 ]; then
  SCORE=0
fi

COMPLIANT=true
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  COMPLIANT=false
fi
if [ "$STRICT_MODE" = true ] && [ ${#WARNINGS[@]} -gt 0 ]; then
  COMPLIANT=false
fi

# ==============================================================================
# Emisión de Resultados
# ==============================================================================
if [ "$JSON_MODE" = true ]; then
  # Emisión JSON determinista
  python3 -c '
import sys, json

data = {
    "target_path": sys.argv[1],
    "compliant": sys.argv[2] == "true",
    "score": int(sys.argv[3]),
    "checks": {
        "cmp": {
            "has_cmp": sys.argv[4] == "true",
            "cmp_type": sys.argv[5],
            "trackers_detected": sys.argv[6].split(",") if sys.argv[6] else []
        },
        "legal_pages": {
            "aviso_legal": sys.argv[7] == "true",
            "politica_privacidad": sys.argv[8] == "true",
            "politica_cookies": sys.argv[9] == "true"
        },
        "security_headers": {
            "csp": sys.argv[10] == "true",
            "hsts": sys.argv[11] == "true",
            "x_frame_options": sys.argv[12] == "true",
            "x_content_type_options": sys.argv[13] == "true",
            "referrer_policy": sys.argv[14] == "true"
        },
        "seo": {
            "robots": sys.argv[15] == "true",
            "sitemap": sys.argv[16] == "true"
        }
    },
    "violations": json.loads(sys.argv[17]),
    "warnings": json.loads(sys.argv[18]),
    "recommendations": json.loads(sys.argv[19])
}
print(json.dumps(data, indent=2, ensure_ascii=False))
' \
    "$TARGET_DIR" \
    "$COMPLIANT" \
    "$SCORE" \
    "$HAS_CMP" \
    "$CMP_TYPE" \
    "$(IFS=,; echo "${TRACKERS_DETECTED[*]}")" \
    "$HAS_AVISO_LEGAL" \
    "$HAS_POLITICA_PRIVACIDAD" \
    "$HAS_POLITICA_COOKIES" \
    "$HAS_CSP" \
    "$HAS_HSTS" \
    "$HAS_X_FRAME" \
    "$HAS_NOSNIFF" \
    "$HAS_REFERRER" \
    "$HAS_ROBOTS" \
    "$HAS_SITEMAP" \
    "$(printf '%s\n' "${VIOLATIONS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")" \
    "$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")" \
    "$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")"
else
  # Emisión en Terminal Humana
  echo "=============================================================================="
  echo "  AUDITORÍA DETERMINISTA DE CUMPLIMIENTO WEB & SEGURIDAD"
  echo "=============================================================================="
  echo "  Target: $TARGET_DIR"
  echo "  Puntuación: $SCORE/100"
  if [ "$COMPLIANT" = true ]; then
    echo "  Estado: ✅ CONFORME"
  else
    echo "  Estado: ❌ NO CONFORME (Violaciones detectadas)"
  fi
  echo "------------------------------------------------------------------------------"
  echo "1. Consentimiento de Cookies (CMP & AEPD):"
  if [ "$HAS_CMP" = true ]; then
    echo "   ✅ Solución CMP detectada: $CMP_TYPE"
  else
    echo "   ⚠️  Sin CMP detectado"
  fi
  if [ ${#TRACKERS_DETECTED[@]} -gt 0 ]; then
    echo "   🔍 Trackers/Scripts externos detectados: ${TRACKERS_DETECTED[*]}"
  else
    echo "   ℹ️  No se detectaron trackers externos obvios"
  fi

  echo ""
  echo "2. Páginas Legales Obligatorias (LSSI-CE & RGPD):"
  [ "$HAS_AVISO_LEGAL" = true ] && echo "   ✅ /aviso-legal (LSSI-CE art. 10)" || echo "   ❌ /aviso-legal (Ausente)"
  [ "$HAS_POLITICA_PRIVACIDAD" = true ] && echo "   ✅ /politica-privacidad (RGPD art. 13)" || echo "   ❌ /politica-privacidad (Ausente)"
  [ "$HAS_POLITICA_COOKIES" = true ] && echo "   ✅ /politica-cookies (Directiva ePrivacy)" || echo "   ❌ /politica-cookies (Ausente)"

  echo ""
  echo "3. Cabeceras HTTP de Seguridad:"
  [ "$HAS_CSP" = true ] && echo "   ✅ Content-Security-Policy (CSP)" || echo "   ⚠️  Content-Security-Policy (Ausente)"
  [ "$HAS_HSTS" = true ] && echo "   ✅ Strict-Transport-Security (HSTS)" || echo "   ⚠️  Strict-Transport-Security (Ausente)"
  [ "$HAS_X_FRAME" = true ] && echo "   ✅ X-Frame-Options" || echo "   ⚠️  X-Frame-Options (Ausente)"
  [ "$HAS_NOSNIFF" = true ] && echo "   ✅ X-Content-Type-Options (nosniff)" || echo "   ⚠️  X-Content-Type-Options (Ausente)"
  [ "$HAS_REFERRER" = true ] && echo "   ✅ Referrer-Policy" || echo "   ℹ️  Referrer-Policy (Ausente)"

  echo ""
  echo "4. Higiene SEO & Descubrimiento:"
  [ "$HAS_ROBOTS" = true ] && echo "   ✅ robots.txt / app/robots" || echo "   ⚠️  robots.txt (Ausente)"
  [ "$HAS_SITEMAP" = true ] && echo "   ✅ sitemap.xml / app/sitemap" || echo "   ⚠️  sitemap.xml (Ausente)"

  if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "🚨 VIOLACIONES DETECTADAS:"
    for v in "${VIOLATIONS[@]}"; do
      echo "   • $v"
    done
  fi

  if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
    echo ""
    echo "💡 RECOMENDACIONES DE MITIGACIÓN:"
    for r in "${RECOMMENDATIONS[@]}"; do
      echo "   → $r"
    done
  fi
  echo "=============================================================================="
fi

if [ "$COMPLIANT" = false ]; then
  exit 1
else
  exit 0
fi
