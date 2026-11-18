# T-229 — Despliegue de Glances Web en VPS DataManager vía Tailscale
Sprint: Sprint 43 | Estado: ✅ Hecho | Tamaño: S | Rama propuesta: feat/T-229-vps-glances-telemetry | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 43 — 2026-11-18
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Utilizar la plantilla Docker Compose `templates/homepage/glances-compose.yml` para desplegar Glances en DataManager VPS (`<TAILSCALE_IP_DATAMANAGER>`).
  - Puerto amarrado estrictamente a la IP de Tailscale: `<TAILSCALE_IP_DATAMANAGER>:61208:61208` para prevenir exposición WAN pública en cumplimiento estricto de ADR 004.
  - Ejecutar el despliegue de forma remota vía SSH sobre `<nodo-inferencia>` asegurando `restart: unless-stopped`.
  - Verificar que el endpoint HTTP responde con la API v4 de Glances (`curl -s http://<TAILSCALE_IP_DATAMANAGER>:61208/api/4/all` o `/status`).
  - Actualizar el runbook operativo `docs/runbooks/glances-setup.md` documentando el despliegue en vivo en DataManager.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Aprovisionar la telemetría de hardware (CPU, RAM, Disco) en el nodo de inferencia DataManager mediante Glances Web Server, permitiendo que el dashboard Homepage en Oracle VPS consuma sus métricas sin exponer puertos a Internet.

## 2. Contexto técnico
- Host remoto: `<nodo-inferencia>` (IP Tailscale `<TAILSCALE_IP_DATAMANAGER>`, IP pública `<nodo-inferencia-ip>`).
- Plantilla Compose: `templates/homepage/glances-compose.yml`.
- Runbook: `docs/runbooks/glances-setup.md`.

## 3. Caja de archivos
- `templates/homepage/glances-compose.yml`
- `docs/runbooks/glances-setup.md`
- `.agents/tasks/task-229.md`
- `docs/sprints/sprint-43.md`

## 4. Plan de implementación
1. Ajustar `templates/homepage/glances-compose.yml` si se requiere configuración específica de Tailscale bind.
2. Transferir la definición compose a DataManager VPS (`/home/ubuntu/services/glances/` o directorio estándar).
3. Levantar el servicio con `docker compose up -d` en DataManager.
4. Validar conectividad de socket y respuesta API desde Oracle VPS y desde local a través de Tailscale (`<TAILSCALE_IP_DATAMANAGER>:61208`).
5. Documentar el procedimiento y estado de salud en `docs/runbooks/glances-setup.md`.

## 5. Criterios de aceptación
- Contenedor Glances Web activo y saludable en DataManager VPS.
- Puerto `61208` abierto exclusivamente en `<TAILSCALE_IP_DATAMANAGER>` (cerrado en `0.0.0.0` y en la IP pública).
- Llamada a `http://<TAILSCALE_IP_DATAMANAGER>:61208/api/4/cpu` retorna métricas JSON válidas con HTTP 200.
