# detect-stack.sh — detecta stack y configura variables de entorno para otros scripts
#
# Propósito:
#   Este script actúa como el motor de detección de stack tecnológico del core de Agent OS.
#   Identifica si el proyecto destino es Python, JavaScript (ES6+) o TypeScript (React),
#   y configura variables de entorno estandarizadas usadas por scripts de auditoría,
#   generación de resúmenes (digest), e inventario.
#
# Variables Exportadas:
#   SRC_DIR: Ruta al código fuente principal (ej: src/ o agents/).
#   CODE_EXTS_FIND: Array de argumentos para el comando 'find' (ej: -name "*.py").
#   CODE_EXTS_GREP: Array de argumentos para 'grep' (ej: --include=*.py).
#   TYPES_PATTERNS: Array de patrones de archivos de modelos/tipos (ej: models.py).
#   SERVICES_DIR: Ruta al directorio de servicios o hooks.
#   SERVICES_LABEL: Etiqueta descriptiva para el reporte de servicios.
#   DIGEST_LANG: Nombre del lenguaje para el formateador del digest.
#   DIGEST_EXCLUDE: Patrones de archivos a excluir en la generación del digest.
#   PROJECT_NAME: Nombre del proyecto (obtenido del directorio raíz).
#   COMPLEXITY_LAYERS: Array de patrones de complejidad específicos del stack.
#   COMPLEXITY_LABELS: Etiquetas descriptivas para las capas de complejidad.
#   HOT_FOLDER_REGEX: Expresión regular para identificar carpetas calientes de desarrollo.
#
# Prioridad de Resolución:
#   1. Override manual: Si existe el archivo '.agents/context/stack.env' y define 'AGENT_OS_STACK'.
#   2. Autodetección heurística: Busca archivos clave (pyproject.toml, package.json, tsconfig.json).
#   3. Fallback: Configura TypeScript/React por defecto.

detect_stack() {
  local root="${1:-$(pwd)}"
  local env_file="$root/.agents/context/stack.env"
  
  # =========================================================================
  # 1. VALORES POR DEFECTO (TypeScript / React)
  # =========================================================================
  # TypeScript es el stack de referencia del ecosistema. Se preconfiguran
  # estas variables como base antes de evaluar overrides o autodetección.
  SRC_DIR="$root/src"
  CODE_EXTS_FIND=(-name "*.ts" -o -name "*.tsx")
  CODE_EXTS_GREP=("--include=*.ts" "--include=*.tsx")
  TYPES_PATTERNS=("_types.ts")
  SERVICES_DIR="$root/src/hooks"
  SERVICES_LABEL="Hooks relacionados en src/hooks"
  DIGEST_LANG="typescript"
  DIGEST_EXCLUDE=("*.test.*" "*.spec.*" "*.stories.*")
  PROJECT_NAME=$(basename "$root")
  
  # Capas de complejidad por defecto (TypeScript/React) para auditoría
  COMPLEXITY_LAYERS=(".tsx\|component" "use[A-Z]\|hook" "_types\|interface\|type ")
  COMPLEXITY_LABELS="componentes / hooks / tipos"
  HOT_FOLDER_REGEX="src/[^/]+/[^/]+"
  
  # =========================================================================
  # 2. CARGAR OVERRIDE EXPLÍCITO (stack.env)
  # =========================================================================
  # Permite al desarrollador forzar un stack en proyectos híbridos, políglotas
  # o con estructuras personalizadas que confunden a la autodetección.
  local AGENT_OS_STACK=""
  if [[ -f "$env_file" ]]; then
    # Lee stack.env de manera segura extrayendo solo la línea AGENT_OS_STACK=...
    # y eliminando comillas simples/dobles para evitar inyección de código.
    AGENT_OS_STACK=$(grep -E "^AGENT_OS_STACK=" "$env_file" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
  fi

  # =========================================================================
  # 3. AUTODETECCIÓN HEURÍSTICA
  # =========================================================================
  # Si no existe un override en stack.env, se examina la presencia de archivos
  # de configuración clave en la raíz del proyecto para deducir el stack.
  if [[ -z "$AGENT_OS_STACK" ]]; then
    if [[ -f "$root/pyproject.toml" || -f "$root/requirements.txt" || -f "$root/setup.py" || -f "$root/Pipfile" ]]; then
      AGENT_OS_STACK="python"
    elif [[ -f "$root/package.json" ]] && ! [[ -f "$root/tsconfig.json" ]]; then
      AGENT_OS_STACK="javascript"
    else
      # Fallback secundario si no coincide con los anteriores
      AGENT_OS_STACK="typescript"
    fi
  fi

  # =========================================================================
  # 4. CONFIGURAR VARIABLES SEGÚN EL STACK SELECCIONADO
  # =========================================================================
  case "$AGENT_OS_STACK" in
    python)
      # Configuración específica para entornos Python (Django, FastAPI, Flask, etc.)
      SRC_DIR="$root/agents"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root/src"  # Fallback si agents/ no existe
      CODE_EXTS_FIND=(-name "*.py")
      CODE_EXTS_GREP=("--include=*.py")
      TYPES_PATTERNS=("models.py" "schemas.py" "*_types.py")
      SERVICES_DIR="$root/agents/application"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$root/src/application" # Fallback si agents/ no existe
      SERVICES_LABEL="Servicios/Casos de uso"
      DIGEST_LANG="python"
      DIGEST_EXCLUDE=("*.pyc" "__pycache__" "*.test.py" "test_*.py")
      COMPLEXITY_LAYERS=("application/" "models.py\|schemas.py" "scripts/")
      COMPLEXITY_LABELS="aplicación / datos / scripts"
      HOT_FOLDER_REGEX="(agents|src|scripts)/[^/]+/[^/]+"
      ;;
    javascript)
      # Configuración para JavaScript puro (Node.js, React sin TypeScript)
      SRC_DIR="$root/src"
      CODE_EXTS_FIND=(-name "*.js" -o -name "*.jsx")
      CODE_EXTS_GREP=("--include=*.js" "--include=*.jsx")
      TYPES_PATTERNS=("*.js")
      SERVICES_DIR="$root/src/services"
      SERVICES_LABEL="Servicios relacionados en src/services"
      DIGEST_LANG="javascript"
      DIGEST_EXCLUDE=("*.test.js" "*.spec.js" "*.stories.js")
      COMPLEXITY_LAYERS=(".jsx\|component" "service" "route")
      COMPLEXITY_LABELS="componentes / servicios / rutas"
      HOT_FOLDER_REGEX="src/[^/]+/[^/]+"
      ;;
    typescript|*)
      # Mantiene los defaults de TypeScript preconfigurados en la sección 1.
      ;;
  esac
}
