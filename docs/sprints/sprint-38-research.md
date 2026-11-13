# Sprint 38 Research — Descubrimiento Dinámico de Capacidades, Enrutamiento por Dificultad × Cuota y Telemetría

## Estado de la Investigación
- **Fecha**: 2026-11-13
- **Gate Scout-First**: Verificado (`scout.sh "dynamic model routing llm quota effort"`).
- **Prospección en tiempo real**: Verificado mediante inspección viva del arnés actual (Antigravity `swarm action: models`), revelando catálogos reales con niveles de esfuerzo (`low`, `medium`, `high`, `thinking`) y cuotas dinámicas (`claude-sonnet-4-6` al 48%, `gemini-3.8-flash-*` al 98%).

## Hallazgos Clave
1. **Antipatrón de nombres fijos**: Los nombres de modelos comerciales cambian constantemente (ej. `flash_lite` no existe en la versión actual; existen familias de modelos con niveles de esfuerzo configurables).
2. **Descubrimiento en tiempo de ejecución (Runtime Discovery)**: El Coordinador no debe asumir catálogos estáticos; debe consultar las capacidades y cuotas vivas del arnés en el momento del arranque o despacho.
3. **Matriz Dificultad × Cuota**: La asignación de modelos debe cruzar la complejidad del código con el estado de las cuotas para proteger los modelos de razonamiento profundo para tareas críticas.
4. **Rendición de cuentas**: Toda orquestación debe culminar con un informe estructurado que justifique qué modelo y arnés se utilizó en cada tarea.

## Descubrimientos Scout (por tarea)

### T-205: Protocolo de descubrimiento dinámico de modelos/cuotas, matriz de esfuerzo y reporte de rendición de cuentas en Coordinador
- **Scout OSS**: Evaluadas librerías de catálogo dinámico (`@oh-my-pi/pi-catalog`, `@deepseek-ai/dsh-agent`).
- **Veredicto**: `Desarrollo a medida justificado` dentro de las reglas y perfiles nativos de Agent OS.

### T-206: Telemetría de arnés/modelo en orchestration-report.sh y sincronización a la flota
- **Scout OSS**: Integración de métricas de arnés y modelo en scripts deterministas Bash/Python existentes.
- **Veredicto**: `Desarrollo a medida justificado` evolucionando `orchestration-report.sh`.
