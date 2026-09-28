# Task-053: Plan de recuperación de espacio en disco por lotes e inventario de capacidad de oracle

## Objetivo
Actualizar el inventario de capacidad y utilización de disco en el VPS `oracle`, elaborar el plan de recuperación de almacenamiento con compuertas de decisión humanas (HITL), ejecutar el Lote C (seedbox media respaldado) tras aprobación explícita y registrar las exclusiones formales de volúmenes e imágenes para garantizar la seguridad de los datos.

## Contexto técnico
- Host: `oracle` (`vnic-rsr`, Ubuntu 24.04 ARM64, Tailscale `192.0.2.11`).
- Estado inicial: `/dev/sda1` al 76% de uso (146 GB ocupados de 193 GB, 48 GB libres).
- Estado post-ejecución Lote C: `/dev/sda1` al 33% de uso (63 GB ocupados de 193 GB, **131 GB libres**). **83 GB liberados**.
- Motor de infraestructura: Docker Engine 29.1.2 con 38 contenedores activos y sanos (Coolify v4, Traefik v3.6, bases de datos y microservicios).
- Decisiones estratégicas del usuario:
  - Lote C (Seedbox downloads, 83 GB): Aprobado y ejecutado tras confirmarse copia de seguridad en equipo local.
  - Volúmenes huérfanos e imágenes huérfanas: Pausados para inspección profunda.
  - Exclusiones críticas blindadas: `bytebox-data` y `homepage-config`.
  - Rechazo de poda en volúmenes obsoletos (`surfsense-db-data`, `grafana-data`, `minio-data`, etc.) por tres motivos: potencial recuperación de apps de Coolify durmientes, persistencia de datos valiosos y bajo retorno (solo 0.45 GB).

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/runbooks/oracle-disk-recovery-plan.md`
- `docs/sprints/sprint-08-core.md`
- `.agents/tasks/task-053.md`

## Criterios de done
- [x] Recopilación no destructiva de métricas de host, Docker, volúmenes, rutas de `/home/ubuntu` y logs.
- [x] Identificación exacta de la ruta real del seedbox (`/home/ubuntu/seedbox/downloads`: 83 GB, 2,339 archivos).
- [x] Elaboración del runbook integral `docs/runbooks/oracle-disk-recovery-plan.md` con compuertas de decisión humanas.
- [x] Recepción de aprobación humana para Lote C (respaldo completado en local).
- [x] Ejecución controlada y limpia de purga en `/home/ubuntu/seedbox/downloads` (83 GB liberados sin romper el punto de montaje del contenedor `jdownloader2-vps`).
- [x] Comprobación de salud post-ejecución: 38 contenedores permanecen activos y sanos; partición al 33% de ocupación (131 GB libres).
- [x] Documentación formal de exclusión para `bytebox-data` y `homepage-config`, y bloqueo de poda en volúmenes/imágenes huérfanas.
- [x] Suite de validación local (`tests/validate-control-plane.sh`) pasando con 0 errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido para Lote C — fecha/hora: 2026-09-27T10:36:56+01:00
- [x] Rama creada: feat/T-053-oracle-disk-recovery-plan
- [x] Lote C ejecutado: 83 GB liberados
- [x] Volúmenes e imágenes excluidos según directiva del usuario
- [x] Tarea documentada
