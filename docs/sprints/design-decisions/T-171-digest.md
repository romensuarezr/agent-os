# Executive Design Digest — T-171

## 🎯 Objetivo
Ejecutar un re-ensayo técnico riguroso de Vane partiendo de la imagen exacta `itzcrazykns1337/vane:latest` antes de sondear cualquier otra variante, descartando terminantemente `pythops/vane` y variantes `slim`. La tarea cuenta con una compuerta estricta inicial (**Gate 0**): `docker pull itzcrazykns1337/vane:latest` debe funcionar de forma verificada antes de desplegar nada en la infraestructura; si el pull falla, la tarea aborta inmediatamente a humano (fail-closed), quedando prohibido cerrar con meras plantillas. Superado el Gate 0, el ensayo consiste en desplegar el contenedor y ejecutar una investigación profunda real a través de la ruta autónoma. La compuerta de cierre exige la obtención de un **informe útil** y estructurado (no únicamente una respuesta corta con citas); en caso de no generar dicho informe útil, abortar inmediatamente a humano sin forzar la integración. Solo si el ensayo lo justifica de forma concluyente, se integrará la instancia preexistente de SearXNG (sin uso actual) como backend del motor de búsqueda profunda, sin desplegar en ningún caso un segundo SearXNG. La tarea se ejecuta bajo el régimen estándar de **Opción D**, sin tocar `main`, sin tags y con denominador de suite inmutable en **38/38**.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan de T-171 cumple con total fidelidad el diseño macro acordado en Sprint 30: superación estricta de Gate 0 con la imagen exacta autorizada (itzcrazykns1337/vane:latest), verificación previa de almacenamiento (131 GiB libres) y ejecución de ensayos empíricos reales sin tocar main ni mutar tags. La aplicación del principio fail-closed bajo Opción D es impecable: al demostrarse una latencia inviable de 20 minutos y una arquitectura acoplada a UI/browser, se rechaza la integración forzada protegiendo la flota y preservando intacta la instancia preexistente de SearXNG sin duplicidades.
- **Prospección Scout**: `CONFORME (sprint-30-research.md)`
  - Alternativa detectada:** `itzcrazykns1337/vane:latest` (Docker Hub oficial de Vane, 3.91 GB amd64 / 3.43 GB arm64), SearXNG preexistente de la flota (`searxng/searxng`).
  - Recomendación del agente:** Probar estrictamente la imagen exacta `itzcrazykns1337/vane:latest` descartando cualquier variante `slim` o repositorios inexistentes como `pythops/vane`.
  - Dictamen del Relé (Enmienda vinculante):** Ratificado. Gate 0 determinista: pull previo obligatorio; si falla, aborto inmediato a humano sin cierre de plantilla. El ensayo exige despliegue y una investigación real autónoma con generación de informe útil (no solo citas). Si no hay informe útil, aborto a humano sin forzar integración. Solo si se justifica, conectar el SearXNG preexistente (sin duplicar instancias). Denominador inmutable en 38/38.
  - Alternativas rechazadas y motivos:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-171-vane-live-trial' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-171.md`
- `.agents/tasks/task-171.md`
- `docs/sprints/sprint-30-core.md`

## 🧠 Skills Declaradas y Aplicadas
- `remote-admin`
- `tech-scout`
- `agent-os-scripts`
- `coolify-admin`
