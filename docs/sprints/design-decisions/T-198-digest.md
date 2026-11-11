# Executive Design Digest — T-198

## 🎯 Objetivo
Formalizar el rol de modelo Asesor (`advisor`) en la política de enrutamiento de inferencia y declarar los proveedores DeepSeek MoE y Nvidia NIM en la plantilla de configuración de FreeLLMAPI, reduciendo el sobrecoste de generación de código.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-198 respeta rigurosamente el diseño macro aprobado y el principio de no mutación fuera del alcance sellado. La formalización del rol `/advisor` bajo `architecture_advisory` preserva las claves existentes del esquema en `routing-policy.yaml`, manteniendo blindadas las rutas críticas de deliberación (`deliberation_and_review`) y privacidad (`private_data_tasks`). Asimismo, la reordenación de prioridad en `code_implementation` hacia workers rápidos optimiza el consumo de cuota manteniendo `primary-reliable` como fallback defensivo.

La extensión del template `freellmapi.config.json` para DeepSeek MoE y Nvidia NIM mantiene compatibilidad con la especificación OpenAI sin inyectar secretos ni dependencias activas, empleando placeholders conformes (`***`). Los pasos de verificación aseguran el determinismo sintáctico (Python JSON/YAML) y la ejecución de la suite de control plane antes de la integración C1b.
- **Prospección Scout**: `CONFORME (sprint-36-research.md)`
  - Consulta scout**: `openai compatible gateway provider catalog deepseek nvidia nim freellmapi`
  - Alternativas detectadas**: sin repos ni paquetes relevantes en NPM/GitHub para un catálogo de conectores.
  - Recomendación**: `Desarrollo a medida justificado` — declaración de proveedores en `templates/freellmapi/config/freellmapi.config.json` (existente, se enriquece) y del rol `advisor` en `.agents/config/routing-policy.yaml` (existente, 118 líneas, sin rol advisor hoy).
- **Mensaje de Cierre**: `Merge branch 'feat/T-198-advisor-routing-freellmapi' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/routing-policy.yaml`
- `.agents/tasks/_archived/task-198.md`
- `docs/sprints/sprint-36.md`
- `templates/freellmapi/config/freellmapi.config.json`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
