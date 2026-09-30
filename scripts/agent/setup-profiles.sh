#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/setup-profiles.sh — Setup determinista de perfiles según stack
# ==============================================================================
# Uso: bash scripts/agent/setup-profiles.sh [opciones]
# Opciones:
#   --check        Modo simulación (dry-run): inspecciona y muestra cambios sin escribir.
#   --apply        Aplica las adaptaciones en disco de forma idempotente.
#   --path <dir>   Ruta al proyecto destino (por defecto: directorio actual).
#   --stack <name> Fuerza un stack soportado como override (ej: python, rust, go).
#   -h, --help     Muestra este mensaje de ayuda.
#
# POLÍTICA DE ARTEFACTO REGENERABLE:
# Los perfiles adaptados son regenerables vía --apply. La configuración inyectada
# está estrictamente delimitada entre marcadores:
#   # BEGIN AGENT-OS-GENERATED-STACK
#   # END AGENT-OS-GENERATED-STACK
# ==============================================================================

set -euo pipefail

APPLY_MODE=false
CHECK_MODE=true
TARGET_DIR=""
OVERRIDE_STACK=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)
      APPLY_MODE=true
      CHECK_MODE=false
      shift
      ;;
    --check)
      CHECK_MODE=true
      APPLY_MODE=false
      shift
      ;;
    --path)
      if [ -n "${2:-}" ]; then
        TARGET_DIR="$2"
        shift 2
      else
        echo "❌ Error: --path requiere una ruta como argumento." >&2
        exit 1
      fi
      ;;
    --path=*)
      TARGET_DIR="${1#*=}"
      shift
      ;;
    --stack)
      if [ -n "${2:-}" ]; then
        OVERRIDE_STACK="$2"
        shift 2
      else
        echo "❌ Error: --stack requiere el nombre de un stack." >&2
        exit 1
      fi
      ;;
    --stack=*)
      OVERRIDE_STACK="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Uso: setup-profiles.sh [opciones]"
      echo ""
      echo "Generación y especialización determinista de perfiles adaptados al stack."
      echo ""
      echo "Opciones:"
      echo "  --check        Modo simulación (dry-run): muestra adaptaciones sin escribir en disco (default)"
      echo "  --apply        Escribe y actualiza los perfiles de forma idempotente"
      echo "  --path <dir>   Ruta al directorio del proyecto objetivo (default: .)"
      echo "  --stack <name> Fuerza un stack específico (ej: typescript, python, rust, go)"
      echo "  -h, --help     Muestra este mensaje de ayuda"
      exit 0
      ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$1"
      fi
      shift
      ;;
  esac
done

# Resolver TARGET_DIR
if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="$(pwd -P)"
else
  if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ ERROR: El directorio destino no existe: $TARGET_DIR" >&2
    exit 1
  fi
  TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd -P || echo "$TARGET_DIR")"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || pwd)"

# Localizar detect-stack.sh (en TARGET_DIR o en el propio core)
DETECT_STACK_PATH=""
if [ -f "$TARGET_DIR/scripts/agent/lib/detect-stack.sh" ]; then
  DETECT_STACK_PATH="$TARGET_DIR/scripts/agent/lib/detect-stack.sh"
elif [ -f "$SCRIPT_DIR/lib/detect-stack.sh" ]; then
  DETECT_STACK_PATH="$SCRIPT_DIR/lib/detect-stack.sh"
fi

if [ -z "$DETECT_STACK_PATH" ]; then
  echo "❌ ERROR: No se encontró scripts/agent/lib/detect-stack.sh." >&2
  exit 1
fi

# Validar y ejecutar detección de stack
source "$DETECT_STACK_PATH"

SUPPORTED_STACKS="python typescript javascript go rust java php ruby dotnet bun static"

if [ -n "$OVERRIDE_STACK" ]; then
  # Validar que el stack solicitado esté soportado
  IS_VALID=false
  for supported in $SUPPORTED_STACKS; do
    if [ "$supported" = "$OVERRIDE_STACK" ]; then
      IS_VALID=true
      break
    fi
  done
  if [ "$IS_VALID" = false ]; then
    echo "❌ ERROR: Stack '$OVERRIDE_STACK' no soportado." >&2
    echo "Stacks soportados: $SUPPORTED_STACKS" >&2
    exit 1
  fi
  AGENT_OS_STACK="$OVERRIDE_STACK" detect_stack "$TARGET_DIR" >/dev/null 2>&1 || true
else
  unset AGENT_OS_STACK AGENT_OS_PACKAGE_MANAGER AGENT_OS_DETECTED_LOCKFILE
  detect_stack "$TARGET_DIR" >/dev/null 2>&1 || true
fi

DETECTED_STACK="${AGENT_OS_STACK:-unknown}"
DETECTED_PM="${AGENT_OS_PACKAGE_MANAGER:-none}"
DETECTED_LOCK="${AGENT_OS_DETECTED_LOCKFILE:-none}"

echo "=================================================="
echo "⚙️  SETUP DE PERFILES ADAPTADOS AL STACK"
echo "Directorio objetivo: $TARGET_DIR"
echo "Stack detectado:     $DETECTED_STACK"
echo "Gestor de paquetes:  $DETECTED_PM (lockfile: $DETECTED_LOCK)"
if [[ "$APPLY_MODE" == true ]]; then
  echo "Modo:                APPLY (escritura idempotente activa)"
else
  echo "Modo:                CHECK (dry-run / simulación)"
fi
echo "=================================================="

# Definir comandos y herramientas recomendadas por stack
COMMAND_DEV=""
COMMAND_BUILD=""
COMMAND_TEST=""
COMMAND_LINT=""
COMMAND_TYPECHECK=""
RUNTIME_NAME=""

case "$DETECTED_STACK" in
  typescript)
    pm="${DETECTED_PM}"
    [[ "$pm" == "none" || -z "$pm" ]] && pm="npm"
    COMMAND_DEV="$pm run dev"
    COMMAND_BUILD="$pm run build"
    COMMAND_TEST="$pm test"
    COMMAND_LINT="$pm run lint"
    COMMAND_TYPECHECK="npx tsc --noEmit"
    RUNTIME_NAME="Node.js / TypeScript"
    ;;
  javascript)
    pm="${DETECTED_PM}"
    [[ "$pm" == "none" || -z "$pm" ]] && pm="npm"
    COMMAND_DEV="$pm start"
    COMMAND_BUILD="$pm run build"
    COMMAND_TEST="$pm test"
    COMMAND_LINT="$pm run lint"
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="Node.js / JavaScript"
    ;;
  bun)
    COMMAND_DEV="bun run dev"
    COMMAND_BUILD="bun run build"
    COMMAND_TEST="bun test"
    COMMAND_LINT="bun run lint"
    COMMAND_TYPECHECK="bun x tsc --noEmit"
    RUNTIME_NAME="Bun Runtime"
    ;;
  python)
    pm="${DETECTED_PM}"
    [[ "$pm" == "none" || -z "$pm" ]] && pm="pip"
    COMMAND_DEV="python main.py"
    COMMAND_BUILD="python -m build"
    COMMAND_TEST="pytest"
    COMMAND_LINT="ruff check"
    COMMAND_TYPECHECK="mypy ."
    RUNTIME_NAME="Python 3"
    ;;
  go)
    COMMAND_DEV="go run ."
    COMMAND_BUILD="go build ./..."
    COMMAND_TEST="go test ./..."
    COMMAND_LINT="golangci-lint run"
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="Go Runtime"
    ;;
  rust)
    COMMAND_DEV="cargo run"
    COMMAND_BUILD="cargo build"
    COMMAND_TEST="cargo test"
    COMMAND_LINT="cargo clippy -- -D warnings"
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="Rust / Cargo"
    ;;
  java)
    pm="${DETECTED_PM}"
    [[ "$pm" == "none" || -z "$pm" ]] && pm="mvn"
    COMMAND_DEV="$pm spring-boot:run"
    COMMAND_BUILD="$pm clean package"
    COMMAND_TEST="$pm test"
    COMMAND_LINT="$pm checkstyle:check"
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="Java / JVM"
    ;;
  php)
    COMMAND_DEV="php -S localhost:8000"
    COMMAND_BUILD="composer install"
    COMMAND_TEST="vendor/bin/phpunit"
    COMMAND_LINT="vendor/bin/phpcs"
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="PHP / Composer"
    ;;
  ruby)
    COMMAND_DEV="bundle exec rails server"
    COMMAND_BUILD="bundle install"
    COMMAND_TEST="bundle exec rspec"
    COMMAND_LINT="bundle exec rubocop"
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="Ruby / Bundler"
    ;;
  dotnet)
    COMMAND_DEV="dotnet run"
    COMMAND_BUILD="dotnet build"
    COMMAND_TEST="dotnet test"
    COMMAND_LINT="dotnet format --verify-no-changes"
    COMMAND_TYPECHECK=""
    RUNTIME_NAME=".NET Core / C#"
    ;;
  static)
    COMMAND_DEV="python3 -m http.server 8000"
    COMMAND_BUILD=""
    COMMAND_TEST=""
    COMMAND_LINT=""
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="HTML5 / CSS3 / Static Web"
    ;;
  *)
    COMMAND_DEV=""
    COMMAND_BUILD=""
    COMMAND_TEST=""
    COMMAND_LINT=""
    COMMAND_TYPECHECK=""
    RUNTIME_NAME="Generic / Polyglot"
    ;;
esac

# Generar bloque YAML especializado delimitado por marcadores canónicos
GENERATED_BLOCK=$(cat << EOF
# BEGIN AGENT-OS-GENERATED-STACK
stack_context:
  stack: "$DETECTED_STACK"
  package_manager: "$DETECTED_PM"
  detected_lockfile: "$DETECTED_LOCK"
  runtime: "$RUNTIME_NAME"
  commands:
    dev: "$COMMAND_DEV"
    build: "$COMMAND_BUILD"
    test: "$COMMAND_TEST"
    lint: "$COMMAND_LINT"
    typecheck: "$COMMAND_TYPECHECK"
# END AGENT-OS-GENERATED-STACK
EOF
)

PROFILES_DIR="$TARGET_DIR/.agents/profiles"
DEV_YAML="$PROFILES_DIR/developer.yaml"

echo ""
echo "▶ Bloque de especialización de perfil generado:"
echo "--------------------------------------------------"
echo "$GENERATED_BLOCK"
echo "--------------------------------------------------"

if [ ! -f "$DEV_YAML" ]; then
  if [ -d "$PROFILES_DIR" ]; then
    echo "⚠️  Aviso: $DEV_YAML no existe en $PROFILES_DIR."
  else
    echo "⚠️  Aviso: Carpeta de perfiles $PROFILES_DIR no encontrada."
  fi
fi

if [[ "$CHECK_MODE" == true ]]; then
  echo ""
  echo "🔍 [CHECK] Simulación completada. Cero archivos modificados en disco."
  echo "💡 Para persistir la especialización, ejecuta: bash scripts/agent/setup-profiles.sh --apply"
  exit 0
fi

# ==============================================================================
# MODO APPLY: Modificación idempotente con marcadores
# ==============================================================================
if [[ "$APPLY_MODE" == true ]]; then
  if [ ! -d "$PROFILES_DIR" ]; then
    mkdir -p "$PROFILES_DIR"
  fi

  if [ -f "$DEV_YAML" ]; then
    # Limpiar cualquier bloque previo de marcadores si existía
    CLEANED_CONTENT=$(awk '
      /# BEGIN AGENT-OS-GENERATED-STACK/ { in_block=1; next }
      /# END AGENT-OS-GENERATED-STACK/ { in_block=0; next }
      !in_block { print }
    ' "$DEV_YAML")
    
    # Escribir contenido base limpio y añadir el bloque especializado al final
    printf "%s\n\n%s\n" "$CLEANED_CONTENT" "$GENERATED_BLOCK" > "$DEV_YAML"
    echo "✅ [APPLY] Perfil developer.yaml actualizado exitosamente con bloque delimitado."
  else
    # Si developer.yaml no existía, crear uno conforme al esquema canónico
    cat << EOF > "$DEV_YAML"
id: developer
name: "Lead Software Engineer & Code Implementer"
purpose: "Diseño, implementación y refactorización de código siguiendo principios DRY, TDD y rituales de ciclo de vida de agent-os."
version: "1.0.0"

allowed_tools:
  - implementar-feature-dry
  - testing-flows
  - workflow-designer
  - git-gardener
  - tech-scout
  - structure-guardian
  - doe-framework

allowed_hosts:
  - local

preferred_model_tier: "primary-reliable"
fallback_model_tier: "freellmapi"

forbidden_actions:
  - "Commit o push directo a main sin pasar por rama de feature y workflow"
  - "Modificar código fuera de la 'Caja de archivos autorizados'"
  - "Instalar paquetes o binarios globales a nivel de sistema operativo sin validación previa del usuario"
  - "Escribir secretos en código fuente o archivos versionados"

escalation_triggers:
  - "Cambios estructurales o breaking changes en APIs/scripts compartidos"
  - "Conflictos de merge o dependencias incompatibles"
  - "Tests fallidos no resolubles sin cambiar especificaciones"
  - "Necesidad de modificar archivos fuera de la Caja de la sesión"

human_approval_required: true

$GENERATED_BLOCK
EOF
    echo "✅ [APPLY] Perfil developer.yaml creado y especializado conforme al esquema canónico."
  fi

  # Opcional: Actualizar comandos frecuentes en AGENT_ONBOARDING.md si existe
  ONBOARDING_FILE="$TARGET_DIR/.agents/AGENT_ONBOARDING.md"
  if [ -f "$ONBOARDING_FILE" ] && [ -n "$COMMAND_DEV" ]; then
    if grep -q "\[npm run dev\]" "$ONBOARDING_FILE" 2>/dev/null || grep -q "npm run dev" "$ONBOARDING_FILE" 2>/dev/null; then
      # Actualizar líneas de comandos si estaban con la plantilla genérica
      sed -i "s|npm run dev|$COMMAND_DEV|g" "$ONBOARDING_FILE" 2>/dev/null || true
      [ -n "$COMMAND_BUILD" ] && sed -i "s|npm run build|$COMMAND_BUILD|g" "$ONBOARDING_FILE" 2>/dev/null || true
      [ -n "$COMMAND_TEST" ] && sed -i "s|npm test|$COMMAND_TEST|g" "$ONBOARDING_FILE" 2>/dev/null || true
      echo "✅ [APPLY] Comandos frecuentes actualizados en .agents/AGENT_ONBOARDING.md."
    fi
  fi

  echo ""
  echo "✨ Especialización determinista de perfiles completada exitosamente."
  exit 0
fi
