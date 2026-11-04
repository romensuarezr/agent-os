# Executive Design Digest — T-168

## 🎯 Objetivo
Reparar de forma definitiva y en vivo el dashboard de Homepage en el VPS de orquestación (<nodo-orquestacion>), desacoplando el descubrimiento residual de Docker (`docker.yaml`), dotando al generador de soporte para pings de salud configurables o con fallback a `/` (para servicios como OmniRoute que carecen de `/health`), integrando Glances del VPS de inferencia si responde vivo con su widget, triando las tarjetas faltantes mediante endpoints reales verificados en el overlay privado, realizando un backup previo fechado con timestamp (`.bak`) antes de sobrescribir el volumen persistente en vivo, y condicionando el cierre de la tarea al **pase visual del usuario en navegador**.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-168 satisface rigurosamente todas las directrices operativas del macro (Enmienda 5 de Sprint 30) y los principios de diseño del core. Resuelve de raíz las causas de fallo en producción: desacopla el ping granular para OmniRoute (evitando 404 en /health), desactiva el descubrimiento Swarm en docker.yaml (eliminando ruidos 403 y ECONNREFUSED) e implementa la salvaguarda obligatoria de backup timestamped antes de la sincronización del volumen.

Adicionalmente, se preserva la invariante estricta del control plane manteniendo el denominador de validación en 38/38 sin regresiones, se garantiza la frontera de confidencialidad sin volcado de IPs o secretos en git, y se subordina el cierre a la compuerta humana vinculante de validación visual en navegador.
- **Prospección Scout**: `CONFORME (sprint-30-research.md)`
  - Alternativa detectada:** Docker Swarm Service Discovery integrado en Homepage, API manual de comprobación, generador determinista `generate-homepage-config.sh` con overlay privado `fleet.yaml`.
  - Recomendación del agente:** Eliminar el socket proxy Swarm discovery (`docker.yaml`) que causa fallos continuos 403 Forbidden y `ECONNREFUSED` al estar configurado `SERVICES: '0'`. Fundamentar el descubrimiento enteramente en el overlay privado `fleet.yaml`. Implementar soporte para `ping_path` granular por servicio (permitiendo `/` para OmniRoute y resolviendo el 404 de `/health`). Integrar Glances si responde vivo en nodo secundario. Garantizar backup fechado (`.bak.<timestamp>`) previo a la sobrescritura y compuerta estricta de pase visual por el usuario en navegador.
  - Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada. El descubrimiento se mantiene portable: mismo generador y plantillas en cualquier repo hijo, cada repo con su overlay privado, 0 datos privados en git. Triage riguroso de tarjetas faltantes (Ollama en su nodo real, clarificación de Open-WebUI y Hermes). Cierre solo con pase visual del usuario en navegador, no con HTTP del agente.
  - Alternativas rechazadas y motivos:**
- **Mensaje de Cierre**: `merge: feat/T-168-homepage-live-remediation (arreglo en vivo de Homepage, ping granular y descubrimiento portable multi-repo)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-168.md`
- `docs/runbooks/coolify-homepage-deployment.md`
- `docs/sprints/sprint-30-core.md`
- `scripts/agent/generate-homepage-config.sh`
- `templates/homepage/config/docker.yaml`
- `templates/homepage/config/services.yaml`
- `templates/homepage/config/widgets.yaml`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `coolify-admin`
- `remote-admin`
- `agent-os-scripts`
