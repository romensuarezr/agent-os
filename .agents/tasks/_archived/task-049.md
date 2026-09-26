# Task-049: Script CLI determinista import-secrets.sh para escaneo, validación liveness de APIs y migración masiva (.env -> Infisical)

## Objetivo
Desarrollar una herramienta CLI determinista (`scripts/agent/import-secrets.sh`) con motor de validación (`scripts/agent/lib/verify-secrets.py`) que escanee árboles de proyectos en busca de archivos `.env*`, descarte duplicados y placeholders, valide la vigencia real de tokens (OpenAI, GitHub, Anthropic, Groq, etc.) contra sus APIs, y vuelque los secretos válidos organizados jerárquicamente por carpeta de proyecto (`secretPath`) en Infisical sin colisiones.

## Contexto técnico
- Infisical Community Edition activo en `oracle` y accesible por Universal Auth mediante variables del host (`INFISICAL_API_URL`, `INFISICAL_CLIENT_ID`, `INFISICAL_CLIENT_SECRET`, `INFISICAL_PROJECT_ID`).
- Infisical CLI y API soportan jerarquías por carpetas (`secretPath: /<nombre_proyecto>`), evitando colisiones de variables genéricas (`PORT`, `DATABASE_URL`, `NODE_ENV`).
- Principio no destructivo por defecto (Principio 2 de AGENTS.md):
  - Modo `--dry-run` por defecto: escanea, parsea, prueba tokens en APIs y genera reporte en consola o JSON sin escribir en Infisical ni alterar archivos.
  - Modo `--apply`: realiza las peticiones a Infisical para subir las claves válidas agrupadas por proyecto.
- Detección de vigencia (liveness):
  - Filtro 1: Limpieza sintáctica (ignora comentarios, vacíos y placeholders como `your-key-here`, `xxx`, `CHANGE_ME`, etc.).
  - Filtro 2: Pings concurrentes a endpoints de salud / autenticación con timeout estricto de 2s para proveedores conocidos (OpenAI, GitHub, Anthropic, Groq, Google). Claves revocadas (401/403) son señaladas y omitidas.
  - Filtro 3: Secretos internos u opacos (`DATABASE_URL`, `JWT_SECRET`, etc.) se catalogan bajo su proyecto (`/<repo>`).
- Agnóstico y universal: el comando acepta cualquier directorio (`scripts/agent/import-secrets.sh [DIRECTORIO]`), sin paths absolutos fijados.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/import-secrets.sh`
- `scripts/agent/lib/verify-secrets.py`
- `.agents/skills/infisical-secrets/SKILL.md`
- `.agents/skills/repo-onboarding/SKILL.md`
- `docs/sprints/sprint-08-core.md`
- `.agents/tasks/task-049.md`
- `tests/validate-control-plane.sh`

## Criterios de done
- [x] Script CLI determinista `scripts/agent/import-secrets.sh` y motor `scripts/agent/lib/verify-secrets.py` implementados con modos `--dry-run` y `--apply`.
- [x] Detección recursiva de archivos `.env*` ignorando directorios de dependencias (`.git`, `node_modules`, `.next`, `venv`, `target`, etc.).
- [x] Módulo de validación liveness con comprobación sintáctica y verificación concurrente de APIs conocidas (OpenAI, GitHub, Anthropic, Groq, Google).
- [x] Asignación jerárquica de secretos en Infisical por carpeta de proyecto (`secretPath: /<nombre_repo>`) para evitar colisiones.
- [x] Ejecución de prueba auditando `/home/romen/Proyectos` en `--dry-run` con informe claro de secretos válidos vs caducados.
- [x] Documentación del flujo de migración en `.agents/skills/infisical-secrets/SKILL.md` y `.agents/skills/repo-onboarding/SKILL.md`.
- [x] Suite `tests/validate-control-plane.sh` pasando con 0 errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-26T15:15:20+01:00
- [x] Rama creada: feat/T-049-import-secrets-cli
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
