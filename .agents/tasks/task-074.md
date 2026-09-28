# Task-074: detect-stack.sh universal con fallback explícito

## Objetivo
`detect-stack.sh` reconoce Go, Rust, Java, PHP, Ruby, .NET, Bun y sitios estáticos; cuando no reconoce el stack devuelve `unknown` declarado con mensaje accionable. Nunca más degradación silenciosa a TypeScript.

## Contexto técnico
Auditoría 2026-09-28 (A5, M12): el detector solo conoce Python y JavaScript/TypeScript; cualquier otro stack cae en silencio al fallback TypeScript, violando el principio #1 de AGENTS.md ("ningún script asume un stack concreto"). Además asume layout `agents/` para Python. Consumidores: `generate-digest.sh`, `audit-repo.sh`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/detect-stack.sh`
- `scripts/agent/generate-digest.sh` (manejo del nuevo `unknown`)
- `scripts/agent/audit-repo.sh` (manejo del nuevo `unknown`)

## Criterios de done
- [ ] Matriz de detección documentada en la cabecera del script (marcadores por stack: `go.mod`, `Cargo.toml`, `pom.xml`/`build.gradle`, `composer.json`, `*.csproj`, `bun.lock`, `index.html` sin manifiestos, etc.).
- [ ] Salida `unknown` explícita con mensaje "Guía:" accionable cuando no hay match; ningún path del código degrada en silencio a otro stack.
- [ ] Sin asunción de layout (`agents/`, `src/`): detecta por marcadores, no por carpetas esperadas.
- [ ] Verificación manual registrada: un repo Go, uno Rust y uno estático devuelven su stack; un repo vacío/devuelve `unknown`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
