# detect-stack.sh — detecta stack y configura variables de entorno para otros scripts
detect_stack() {
  local root="${1:-$(pwd)}"
  local env_file="$root/.agents/context/stack.env"
  
  # 1. Valores por defecto (TypeScript / React)
  SRC_DIR="$root/src"
  CODE_EXTS_FIND=(-name "*.ts" -o -name "*.tsx")
  CODE_EXTS_GREP=("--include=*.ts" "--include=*.tsx")
  TYPES_PATTERNS=("_types.ts")
  SERVICES_DIR="$root/src/hooks"
  SERVICES_LABEL="Hooks relacionados en src/hooks"
  DIGEST_LANG="typescript"
  DIGEST_EXCLUDE=("*.test.*" "*.spec.*" "*.stories.*")
  PROJECT_NAME=$(basename "$root")
  
  # Capas de complejidad por defecto (TS/React)
  COMPLEXITY_LAYERS=(".tsx\|component" "use[A-Z]\|hook" "_types\|interface\|type ")
  COMPLEXITY_LABELS="componentes / hooks / tipos"
  HOT_FOLDER_REGEX="src/[^/]+/[^/]+"

  # 2. Cargar override explícito si existe
  local AGENT_OS_STACK=""
  if [[ -f "$env_file" ]]; then
    # Leer stack.env de manera segura sin ejecutar código arbitrario
    # Esperamos una línea de tipo: AGENT_OS_STACK="python" o AGENT_OS_STACK=python
    AGENT_OS_STACK=$(grep -E "^AGENT_OS_STACK=" "$env_file" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
  fi

  # 3. Autodetección si no hay override
  if [[ -z "$AGENT_OS_STACK" ]]; then
    if [[ -f "$root/pyproject.toml" || -f "$root/requirements.txt" || -f "$root/setup.py" || -f "$root/Pipfile" ]]; then
      AGENT_OS_STACK="python"
    elif [[ -f "$root/package.json" ]] && ! [[ -f "$root/tsconfig.json" ]]; then
      AGENT_OS_STACK="javascript"
    else
      AGENT_OS_STACK="typescript"
    fi
  fi

  # 4. Configurar variables según el stack
  case "$AGENT_OS_STACK" in
    python)
      SRC_DIR="$root/agents"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root/src"  # fallback si agents/ no existe
      CODE_EXTS_FIND=(-name "*.py")
      CODE_EXTS_GREP=("--include=*.py")
      TYPES_PATTERNS=("models.py" "schemas.py" "*_types.py")
      SERVICES_DIR="$root/agents/application"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$root/src/application" # fallback si agents/ no existe
      SERVICES_LABEL="Servicios/Casos de uso"
      DIGEST_LANG="python"
      DIGEST_EXCLUDE=("*.pyc" "__pycache__" "*.test.py" "test_*.py")
      COMPLEXITY_LAYERS=("application/" "models.py\|schemas.py" "scripts/")
      COMPLEXITY_LABELS="aplicación / datos / scripts"
      HOT_FOLDER_REGEX="(agents|src|scripts)/[^/]+/[^/]+"
      ;;
    javascript)
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
      # Mantiene los defaults de TypeScript
      ;;
  esac
}
