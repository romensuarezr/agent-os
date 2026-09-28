# detect-stack.sh — detecta stack y configura variables de entorno para otros scripts
#
# Propósito:
#   Este script actúa como el motor universal de detección de stack tecnológico
#   del core de Agent OS. Identifica el lenguaje/ecosistema del proyecto destino
#   sin asumir un stack concreto (Principio #1 de AGENTS.md), y configura
#   variables de entorno estandarizadas usadas por scripts de auditoría,
#   generación de resúmenes (digest), e inventario.
#
# Matriz de Detección y Marcadores Canónicos:
#   -------------------------------------------------------------------------
#   Stack        Marcadores clave              Extensiones  Exclusiones
#   -------------------------------------------------------------------------
#   bun          bun.lock, bun.lockb           .ts, .tsx,   node_modules/*,
#                                              .js, .jsx    *.test.*, *.spec.*
#   typescript   tsconfig.json                .ts, .tsx    node_modules/*,
#                                                           *.test.*, *.spec.*
#   javascript   package.json                  .js, .jsx    node_modules/*,
#                                                           *.test.*, *.spec.*
#   go           go.mod, go.sum                .go          vendor/*, *_test.go
#   rust         Cargo.toml, Cargo.lock        .rs          target/*, *_test.rs
#   java         pom.xml, build.gradle,        .java, .kt   target/*, build/*,
#                build.gradle.kts                           *Test.java
#   php          composer.json, composer.lock  .php         vendor/*, *Test.php
#   ruby         Gemfile, Gemfile.lock         .rb          vendor/*, spec/*
#   dotnet       *.csproj, *.sln               .cs          bin/*, obj/*
#   python       pyproject.toml, requirements  .py          __pycache__/*, *.pyc,
#                setup.py, Pipfile                          venv/*, .venv/*
#   static       index.html, index.htm         .html, .css  dist/*, *.min.*
#   unknown      (sin marcadores reconocibles) *            .git/*, .agents/*
#   -------------------------------------------------------------------------
#
# Orden de Precedencia (cuando coexisten múltiples marcadores):
#   1. Override manual en entorno: variable exportada AGENT_OS_STACK
#   2. Override manual en archivo: <repo>/.agents/context/stack.env (AGENT_OS_STACK=...)
#   3. Ecosistema JavaScript / TypeScript / Bun:
#      - bun.lock / bun.lockb       -> bun (prevalece sobre ts/js)
#      - tsconfig.json              -> typescript (prevalece sobre package.json solo)
#      - package.json               -> javascript
#   4. Ecosistemas compilados y backend (sin solape):
#      - go.mod / go.sum            -> go
#      - Cargo.toml / Cargo.lock    -> rust
#      - pom.xml / build.gradle     -> java
#      - composer.json              -> php
#      - Gemfile / Gemfile.lock     -> ruby
#      - *.csproj / *.sln           -> dotnet
#      - pyproject.toml / etc.      -> python
#   5. Sitios web estáticos puros (sin backend ni manifiestos compilados):
#      - index.html / index.htm     -> static
#   6. Fallback honesto:
#      - Si ningún marcador coincide -> unknown (emite STACK_GUIDE accionable)
#
# Variables Exportadas:
#   AGENT_OS_STACK:    Nombre del stack ('go', 'rust', 'python', 'unknown', etc.)
#   STACK_GUIDE:       Mensaje de orientación cuando AGENT_OS_STACK es 'unknown'
#   SRC_DIR:           Ruta al directorio de código fuente principal
#   CODE_EXTS_FIND:    Array de argumentos para find (ej: -name "*.go")
#   CODE_EXTS_GREP:    Array de argumentos para grep (ej: --include=*.go)
#   TYPES_PATTERNS:    Array de nombres/patrones de modelos o tipos
#   SERVICES_DIR:      Ruta al directorio de servicios, paquetes o controladores
#   SERVICES_LABEL:    Etiqueta descriptiva para el reporte de servicios
#   DIGEST_LANG:       Identificador del lenguaje para digests
#   DIGEST_EXCLUDE:    Array de exclusiones para digests y escaneos
#   PROJECT_NAME:      Nombre del proyecto (directorio raíz)
#   COMPLEXITY_LAYERS: Array de patrones de complejidad para auditoría
#   COMPLEXITY_LABELS: Etiquetas descriptivas para las capas de complejidad
#   HOT_FOLDER_REGEX:  Expresión regular para carpetas calientes de desarrollo

detect_stack() {
  local root="${1:-$(pwd)}"
  local env_file="$root/.agents/context/stack.env"
  PROJECT_NAME=$(basename "$root")
  STACK_GUIDE=""

  local SUPPORTED_STACKS="python typescript javascript go rust java php ruby dotnet bun static"

  _is_supported_stack() {
    local candidate="$1"
    for s in $SUPPORTED_STACKS; do
      if [[ "$s" == "$candidate" ]]; then
        return 0
      fi
    done
    return 1
  }

  local detected_stack=""

  # =========================================================================
  # 1. OVERRIDE MANUAL: VARIABLE DE ENTORNO AGENT_OS_STACK
  # =========================================================================
  if [[ -n "${AGENT_OS_STACK:-}" ]]; then
    if _is_supported_stack "$AGENT_OS_STACK"; then
      detected_stack="$AGENT_OS_STACK"
    fi
  fi

  # =========================================================================
  # 2. OVERRIDE MANUAL: FICHERO stack.env
  # =========================================================================
  if [[ -z "$detected_stack" && -f "$env_file" ]]; then
    local file_stack
    file_stack=$(grep -E "^AGENT_OS_STACK=" "$env_file" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr -d '[:space:]')
    if [[ -n "$file_stack" ]] && _is_supported_stack "$file_stack"; then
      detected_stack="$file_stack"
    fi
  fi

  # =========================================================================
  # 3. AUTODETECCIÓN HEURÍSTICA POR PRECEDENCIA DE MARCADORES
  # =========================================================================
  if [[ -z "$detected_stack" ]]; then
    # 3.1 Bun (prevalece sobre tsconfig/package.json)
    if [[ -f "$root/bun.lock" || -f "$root/bun.lockb" ]]; then
      detected_stack="bun"
    # 3.2 TypeScript (prevalece sobre package.json solo)
    elif [[ -f "$root/tsconfig.json" ]]; then
      detected_stack="typescript"
    # 3.3 JavaScript
    elif [[ -f "$root/package.json" ]]; then
      detected_stack="javascript"
    # 3.4 Go
    elif [[ -f "$root/go.mod" || -f "$root/go.sum" ]]; then
      detected_stack="go"
    # 3.5 Rust
    elif [[ -f "$root/Cargo.toml" || -f "$root/Cargo.lock" ]]; then
      detected_stack="rust"
    # 3.6 Java / Kotlin
    elif [[ -f "$root/pom.xml" || -f "$root/build.gradle" || -f "$root/build.gradle.kts" ]]; then
      detected_stack="java"
    # 3.7 PHP
    elif [[ -f "$root/composer.json" || -f "$root/composer.lock" ]]; then
      detected_stack="php"
    # 3.8 Ruby
    elif [[ -f "$root/Gemfile" || -f "$root/Gemfile.lock" ]]; then
      detected_stack="ruby"
    # 3.9 .NET / C#
    elif compgen -G "$root/*.csproj" >/dev/null 2>&1 || compgen -G "$root/*.sln" >/dev/null 2>&1 || compgen -G "$root/*/*.csproj" >/dev/null 2>&1; then
      detected_stack="dotnet"
    # 3.10 Python
    elif [[ -f "$root/pyproject.toml" || -f "$root/requirements.txt" || -f "$root/setup.py" || -f "$root/Pipfile" || -f "$root/Pipfile.lock" ]]; then
      detected_stack="python"
    # 3.11 Sitios estáticos puros (sin manifiestos de compilación)
    elif [[ -f "$root/index.html" || -f "$root/index.htm" ]]; then
      detected_stack="static"
    else
      # 3.12 Fallback honesto: unknown declarado
      detected_stack="unknown"
    fi
  fi

  AGENT_OS_STACK="$detected_stack"

  # =========================================================================
  # 4. CONFIGURAR VARIABLES ESPECÍFICAS SEGÚN EL STACK RESUELTO
  # =========================================================================
  case "$AGENT_OS_STACK" in
    go)
      SRC_DIR="$root"
      [[ -d "$root/cmd" ]] && SRC_DIR="$root/cmd"
      [[ -d "$root/pkg" ]] && SRC_DIR="$root/pkg"
      CODE_EXTS_FIND=(-name "*.go")
      CODE_EXTS_GREP=("--include=*.go")
      TYPES_PATTERNS=("types.go" "models.go" "*_types.go")
      SERVICES_DIR="$root"
      [[ -d "$root/internal" ]] && SERVICES_DIR="$root/internal"
      [[ -d "$root/pkg" ]] && SERVICES_DIR="$root/pkg"
      SERVICES_LABEL="Paquetes y servicios Go"
      DIGEST_LANG="go"
      DIGEST_EXCLUDE=("*_test.go" "vendor/*")
      COMPLEXITY_LAYERS=("func " "type .* struct" "interface")
      COMPLEXITY_LABELS="funciones / structs / interfaces"
      HOT_FOLDER_REGEX="(cmd|pkg|internal)/[^/]+/[^/]+"
      ;;

    rust)
      SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.rs")
      CODE_EXTS_GREP=("--include=*.rs")
      TYPES_PATTERNS=("types.rs" "models.rs")
      SERVICES_DIR="$SRC_DIR/services"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Módulos y servicios Rust"
      DIGEST_LANG="rust"
      DIGEST_EXCLUDE=("target/*" "*_test.rs")
      COMPLEXITY_LAYERS=("fn " "struct " "enum " "impl ")
      COMPLEXITY_LABELS="funciones / structs / enums / impls"
      HOT_FOLDER_REGEX="(src|crates)/[^/]+/[^/]+"
      ;;

    java)
      SRC_DIR="$root/src/main/java"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.java" -o -name "*.kt")
      CODE_EXTS_GREP=("--include=*.java" "--include=*.kt")
      TYPES_PATTERNS=("*DTO.java" "*Model.java" "*Entity.java")
      SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Servicios y componentes Java"
      DIGEST_LANG="java"
      DIGEST_EXCLUDE=("*/test/*" "*Test.java" "target/*" "build/*")
      COMPLEXITY_LAYERS=("class " "interface " "@Service\|@RestController")
      COMPLEXITY_LABELS="clases / interfaces / servicios"
      HOT_FOLDER_REGEX="src/main/[^/]+/[^/]+"
      ;;

    php)
      SRC_DIR="$root/app"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.php")
      CODE_EXTS_GREP=("--include=*.php")
      TYPES_PATTERNS=("*.php")
      SERVICES_DIR="$SRC_DIR/Services"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Servicios y controladores PHP"
      DIGEST_LANG="php"
      DIGEST_EXCLUDE=("vendor/*" "*Test.php")
      COMPLEXITY_LAYERS=("class " "function " "interface ")
      COMPLEXITY_LABELS="clases / funciones / interfaces"
      HOT_FOLDER_REGEX="(app|src)/[^/]+/[^/]+"
      ;;

    ruby)
      SRC_DIR="$root/app"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root/lib"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.rb")
      CODE_EXTS_GREP=("--include=*.rb")
      TYPES_PATTERNS=("*.rb")
      SERVICES_DIR="$SRC_DIR/services"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Servicios y modelos Ruby"
      DIGEST_LANG="ruby"
      DIGEST_EXCLUDE=("spec/*" "test/*" "vendor/*")
      COMPLEXITY_LAYERS=("def " "class " "module ")
      COMPLEXITY_LABELS="métodos / clases / módulos"
      HOT_FOLDER_REGEX="(app|lib)/[^/]+/[^/]+"
      ;;

    dotnet)
      SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.cs")
      CODE_EXTS_GREP=("--include=*.cs")
      TYPES_PATTERNS=("*Model.cs" "*Dto.cs" "*Entity.cs")
      SERVICES_DIR="$SRC_DIR/Services"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Servicios y controladores .NET"
      DIGEST_LANG="csharp"
      DIGEST_EXCLUDE=("bin/*" "obj/*" "*Test*.cs")
      COMPLEXITY_LAYERS=("class " "interface " "record ")
      COMPLEXITY_LABELS="clases / interfaces / records"
      HOT_FOLDER_REGEX="src/[^/]+/[^/]+"
      ;;

    bun)
      SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx")
      CODE_EXTS_GREP=("--include=*.ts" "--include=*.tsx" "--include=*.js" "--include=*.jsx")
      TYPES_PATTERNS=("_types.ts" "types.ts")
      SERVICES_DIR="$SRC_DIR/services"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Servicios y rutas Bun"
      DIGEST_LANG="typescript"
      DIGEST_EXCLUDE=("*.test.*" "*.spec.*" "node_modules/*")
      COMPLEXITY_LAYERS=("function " "export " "interface\|type ")
      COMPLEXITY_LABELS="funciones / exports / tipos"
      HOT_FOLDER_REGEX="src/[^/]+/[^/]+"
      ;;

    python)
      # Sin asunción de layout fija agents/: busca src, app o la raíz
      SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" && -d "$root/app" ]] && SRC_DIR="$root/app"
      [[ ! -d "$SRC_DIR" && -d "$root/agents" ]] && SRC_DIR="$root/agents"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.py")
      CODE_EXTS_GREP=("--include=*.py")
      TYPES_PATTERNS=("models.py" "schemas.py" "*_types.py")
      SERVICES_DIR="$SRC_DIR/services"
      [[ ! -d "$SERVICES_DIR" && -d "$SRC_DIR/application" ]] && SERVICES_DIR="$SRC_DIR/application"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Servicios/Casos de uso Python"
      DIGEST_LANG="python"
      DIGEST_EXCLUDE=("*.pyc" "__pycache__" "*.test.py" "test_*.py" ".venv/*" "venv/*")
      COMPLEXITY_LAYERS=("def " "class " "router\|route")
      COMPLEXITY_LABELS="funciones / clases / rutas"
      HOT_FOLDER_REGEX="(src|app|agents|lib)/[^/]+/[^/]+"
      ;;

    javascript)
      SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.js" -o -name "*.jsx")
      CODE_EXTS_GREP=("--include=*.js" "--include=*.jsx")
      TYPES_PATTERNS=("*.js")
      SERVICES_DIR="$SRC_DIR/services"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Servicios JavaScript en src/services"
      DIGEST_LANG="javascript"
      DIGEST_EXCLUDE=("*.test.js" "*.spec.js" "*.stories.js" "node_modules/*")
      COMPLEXITY_LAYERS=(".jsx\|component" "service" "route")
      COMPLEXITY_LABELS="componentes / servicios / rutas"
      HOT_FOLDER_REGEX="src/[^/]+/[^/]+"
      ;;

    typescript)
      SRC_DIR="$root/src"
      [[ ! -d "$SRC_DIR" ]] && SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.ts" -o -name "*.tsx")
      CODE_EXTS_GREP=("--include=*.ts" "--include=*.tsx")
      TYPES_PATTERNS=("_types.ts" "types.ts")
      SERVICES_DIR="$SRC_DIR/hooks"
      [[ ! -d "$SERVICES_DIR" && -d "$SRC_DIR/services" ]] && SERVICES_DIR="$SRC_DIR/services"
      [[ ! -d "$SERVICES_DIR" ]] && SERVICES_DIR="$SRC_DIR"
      SERVICES_LABEL="Hooks y servicios TypeScript"
      DIGEST_LANG="typescript"
      DIGEST_EXCLUDE=("*.test.*" "*.spec.*" "*.stories.*" "node_modules/*")
      COMPLEXITY_LAYERS=(".tsx\|component" "use[A-Z]\|hook" "_types\|interface\|type ")
      COMPLEXITY_LABELS="componentes / hooks / tipos"
      HOT_FOLDER_REGEX="src/[^/]+/[^/]+"
      ;;

    static)
      SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*.html" -o -name "*.htm" -o -name "*.css" -o -name "*.js")
      CODE_EXTS_GREP=("--include=*.html" "--include=*.htm" "--include=*.css" "--include=*.js")
      TYPES_PATTERNS=("*.css")
      SERVICES_DIR="$root"
      SERVICES_LABEL="Archivos estáticos web"
      DIGEST_LANG="html"
      DIGEST_EXCLUDE=("dist/*" "*.min.*")
      COMPLEXITY_LAYERS=("<script" "<link" "class=")
      COMPLEXITY_LABELS="scripts / estilos / clases"
      HOT_FOLDER_REGEX="(assets|css|js)/[^/]+"
      ;;

    unknown|*)
      AGENT_OS_STACK="unknown"
      SRC_DIR="$root"
      CODE_EXTS_FIND=(-name "*")
      CODE_EXTS_GREP=()
      TYPES_PATTERNS=()
      SERVICES_DIR="$root"
      SERVICES_LABEL="Código fuente general"
      DIGEST_LANG="plaintext"
      DIGEST_EXCLUDE=(".git/*" ".agents/*" "node_modules/*" "vendor/*" "target/*")
      COMPLEXITY_LAYERS=()
      COMPLEXITY_LABELS="sin métricas específicas de stack"
      HOT_FOLDER_REGEX="[^/]+/[^/]+"
      STACK_GUIDE="Guía: Stack no reconocido automáticamente. Puedes declarar el stack exportando la variable AGENT_OS_STACK o creando el archivo '.agents/context/stack.env' con 'AGENT_OS_STACK=<stack>' (valores soportados: python, typescript, javascript, go, rust, java, php, ruby, dotnet, bun, static)."
      ;;
  esac
}
