# T-231 — Despliegue en Vivo y Validación en Homepage (`http://g8o4sgwsw8k4c0cscoskkks8...`)
Sprint: Sprint 43 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-231-homepage-live-deploy-and-verify | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 43 — 2026-11-18
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Utilizar el mecanismo determinista `generate-homepage-config.sh --remote-push <nodo-orquestacion>` para sincronizar los archivos YAML en el volumen de Homepage en Oracle VPS.
  - Salvaguarda mandatoria: crear backup fechado previo del directorio de configuración en el VPS (`${REMOTE_DATA_DIR}.bak.YYYYMMDDHHMMSS`).
  - Reiniciar el contenedor de Homepage en Oracle VPS y verificar que levanta saludablemente (`docker inspect` con status running/healthy).
  - Verificar visualmente o mediante curl desde el host que la URL operativa confirmada por el usuario (`http://g8o4sgwsw8k4c0cscoskkks8.<nodo-orquestacion-ip>.sslip.io/`) devuelve HTTP 200 con el HTML de Homepage renderizado.
  - Comprobar que el widget de Glances muestra los datos de DataManager VPS en tiempo real sin errores de conexión.
  - Actualizar `docs/runbooks/coolify-homepage-deployment.md` reflejando la configuración viva y el procedimiento de mantenimiento.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Desplegar en producción en Oracle VPS la nueva configuración de Homepage y validar que el dashboard queda 100% operativo con todos los enlaces funcionales y la telemetría multi-host activa.

## 2. Contexto técnico
- Host remoto: `<nodo-orquestacion>` (IP Tailscale `<TAILSCALE_IP_ORACLE>`, IP pública `<nodo-orquestacion-ip>`).
- URL de acceso confirmada: `http://g8o4sgwsw8k4c0cscoskkks8.<nodo-orquestacion-ip>.sslip.io/`.
- Volumen Docker: volumen persistente montado en `/app/config` de `homepage-g8o4sgwsw8k4c0cscoskkks8-155730908242`.
- Runbook: `docs/runbooks/coolify-homepage-deployment.md`.

## 3. Caja de archivos
- `docs/runbooks/coolify-homepage-deployment.md`
- `.agents/tasks/task-231.md`
- `docs/sprints/sprint-43.md`

## 4. Plan de implementación
1. Ejecutar `bash scripts/agent/generate-homepage-config.sh --remote-push <nodo-orquestacion>`.
2. Inspeccionar la salida para confirmar la creación del backup fechado previo y la copia atómica de archivos.
3. Verificar el reinicio del contenedor Homepage en Oracle VPS.
4. Ejecutar consulta HTTP a `http://g8o4sgwsw8k4c0cscoskkks8.<nodo-orquestacion-ip>.sslip.io/` validando respuesta 200 OK.
5. Comprobar que no hay errores en los logs de Homepage (`docker logs --tail 50 homepage...`).
6. Actualizar el runbook con las evidencias y el estado verificado.

## 5. Criterios de aceptación
- Backup fechado del volumen creado en Oracle VPS antes del despliegue.
- Homepage responde con HTTP 200 en su FQDN operativo.
- El panel renderiza los 4 grupos de servicios con sus enlaces operativos y ambos widgets de recursos en la cabecera.
