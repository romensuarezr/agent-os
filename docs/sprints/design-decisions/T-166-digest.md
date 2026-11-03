# Executive Design Digest — T-166

## 🎯 Objetivo
Diseñar, formalizar y verificar la plantilla declarativa Docker Compose de Nango (`templates/nango/docker-compose.yml` y `templates/nango/.env.example`) validada contra el spec oficial self-hosted de Nango, desplegar en vivo el stack en el servidor de orquestación (<nodo-orquestacion>) verificando respuesta del health check real sin filtrar secretos, declarar el esquema en `.agents/config/fleet.example.yaml`, elaborar el runbook de administración `docs/runbooks/nango-oauth-service.md`, y añadir las validaciones como subchecks en `tests/validate-control-plane.sh` manteniendo el denominador inmutable en 38/38.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico presentado para T-166 respeta con total fidelidad el diseño macro aprobado en Sprint Planning (Sprint 30) y los principios de arquitectura de Agent OS. La delimitación de la caja de archivos es exacta, la composición Compose se adhiere a la especificación oficial self-hosted de Nango (server + postgres + redis, puertos canónicos 3003/3009 y límites de recursos), y se respeta la inviolabilidad del despliegue en vivo en VPS con verificación obligatoria del endpoint de salud y política fail-closed ante anomalías.

Asimismo, se garantiza el aislamiento estricto de secretos y parámetros privados (generación local en host y uso exclusivo de placeholders en plantillas/fleet), y se preserva el control plane manteniendo el denominador rígidamente inmutable en 38/38 mediante subchecks integrados. El plan califica para avance desatendido bajo el régimen de Opción D.
- **Prospección Scout**: `CONFORME (sprint-30-research.md)`
  - Alternativa detectada:** `NangoHQ/nango` (13101⭐ | Open Source / Source-Available), CLI oficial `nango` (v0.71.14 npm), `Anil-matcha/open-agent-connector` (849⭐ Apache-2.0).
  - Recomendación del agente:** Adoptar `NangoHQ/nango` oficial como plataforma de autenticación unificada OAuth y token broker para la flota de Agent OS.
  - Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada con despliegue vivo obligatorio. Se añade como criterio de done desplegar en vivo su propia plantilla en el VPS y verificar que el health check real responde, con evidencia en el reporte y sin secretos en el repo. Si el despliegue vivo resulta inviable, eso es aborto a humano (fail-closed), no cierre con solo plantilla. Además, la composición Compose debe validarse contra la especificación oficial de Nango self-hosted antes de sellarla (no asumir que server + postgres basten, y el puerto no queda fijo en 4004 si el spec oficial define otro; la versión del CLI npm no determina la imagen Docker).
  - Notas de integración:**
- **Mensaje de Cierre**: `merge: feat/T-166-nango-vps-deployment (plantilla de despliegue soberano de nango en vps, despliegue en vivo y runbook)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/fleet.example.yaml`
- `.agents/tasks/_archived/task-166.md`
- `docs/runbooks/nango-oauth-service.md`
- `docs/sprints/sprint-30-core.md`
- `templates/nango/.env.example`
- `templates/nango/docker-compose.yml`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `coolify-admin`
- `remote-admin`
- `infisical-secrets`
