# Executive Design Digest — T-167

## 🎯 Objetivo
Robustecer el generador determinista `scripts/agent/generate-homepage-config.sh` como fallback transparente para esquemas simplificados de overlays privados (`fleet.yaml`), sanear `templates/homepage/config/services.yaml` eliminando URLs inventadas, regenerar la configuración con el generador y redesplegar en vivo la instancia de Homepage en VPS (<nodo-orquestacion>), verificando tarjeta por tarjeta desde el contenedor y con pase visual final, resolviendo Docker socket proxy y Glances según la realidad viva.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-167 aborda de forma robusta y determinista las fragilidades de parsing en `scripts/agent/generate-homepage-config.sh` (normalización tipológica de servicios integer/dict, fallback `ip` -> `host` y saneamiento de URLs de localhost/placeholder en nodos remotos) sin acoplamientos rígidos ni fuga de secretos hacia el core.

La estrategia de testing encapsulada dentro del Check 11 en `tests/validate-control-plane.sh` garantiza la preservación inmutable del denominador de control plane en 38/38 mediante fixtures aislados. Asimismo, el protocolo de sincronización y validación en vivo en el VPS vía volumen Docker de Coolify y su debida trazabilidad en `docs/runbooks/coolify-homepage-deployment.md` cumplen estrictamente con la Definition of Done y la frontera portable de Agent OS.
- **Prospección Scout**: `CONFORME (sprint-30-research.md)`
  - Alternativa detectada:** Paquete `gethomepage.dev`, `0xN1nja/homepagectl` (207⭐), generador nativo determinista `scripts/agent/generate-homepage-config.sh`.
  - Recomendación del agente:** Desarrollo a medida justificado sobre el generador nativo existente del core (`generate-homepage-config.sh`) para asegurar tolerancia a esquemas heterogéneos de `fleet.yaml` sin añadir dependencias runtime.
  - Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada con remediación viva obligatoria y dependencia de T-166. Criterio de done: regenerar la configuración con el generador ya tolerante y redesplegar en la instancia viva, con verificación tarjeta por tarjeta desde el contenedor y pase visual. Corrección estrictamente vía generador y redespliegue, nunca editando a mano el volumen Docker. El proxy de Docker y Glances se resuelven según la realidad viva (Glances solo se reactiva si responde, si no queda documentado). La tolerancia al esquema abreviado queda como fallback con defaults transparentes (el esquema estándar sigue siendo el preferido y documentado, y los fixtures en tests deben cubrir casos estándar, abreviado y mixto). En la plantilla, nada de URLs inventadas: placeholders reconocibles por el filtro de omisión, Orca configurable u omitida (no localhost rígido), y la tarjeta de Ollama reflejando la realidad viva verificada.
  - Notas de integración:**
- **Mensaje de Cierre**: `merge: feat/T-167-homepage-remediation-and-live-deploy (remediacion determinista de compatibilidad en generate-homepage-config.sh y puesta a punto en vivo de homepage dashboard)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-167.md`
- `docs/runbooks/coolify-homepage-deployment.md`
- `docs/sprints/sprint-30-core.md`
- `scripts/agent/generate-homepage-config.sh`
- `templates/homepage/config/services.yaml`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `coolify-admin`
- `remote-admin`
- `agent-os-scripts`
