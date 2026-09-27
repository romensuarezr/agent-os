# Idea: Observabilidad Avanzada y Catálogo Exhaustivo de Integraciones en Homepage para Agent OS

**Fecha**: 2026-09-26  
**Origen**: Evaluación post-despliegue T-051 (Homepage Fleet Dashboard en Coolify)  
**Estado**: 💡 Capturada para diseño y descomposición en roadmap / sprint  

---

## 1. Visión y Propósito

Homepage ya está desplegado en Coolify (`oracle`) y cuenta con un generador CLI determinista (`generate-homepage-config.sh`). Sin embargo, su configuración actual es un directorio estático de enlaces con pings básicos y recursos del host local.

El propósito de esta iniciativa es transformar Homepage en el **Centro de Comando y Observabilidad Unificado de la Flota**, aprovechando los más de 100 widgets y servicios oficiales que soporta nativamente. Esto permitirá monitorizar en una sola pantalla:
1. Rendimiento del hardware de todos los nodos (`oracle` + `datamanager`).
2. Estado de los contenedores Docker en tiempo real sin abrir la consola de Coolify.
3. Telemetría de los motores de inferencia IA ($0).
4. Seguridad perimetral, túneles y red mallada (Tailscale / Cloudflare).
5. Productividad dev y repositorios (GitHub, ByteBox, SearXNG).

---

## 2. Catálogo Exhaustivo de Integraciones Candidatas

### A. Monitorización Multi-Nodo y Hardware (OS & Telemetría)
* **Glances (API multi-host)**:
  - *Arquitectura*: Contenedor mínimo o servicio systemd `glances -w` en `datamanager` (nodo de inferencia).
  - *Visualización en Homepage*: Banner doble en cabecera (`Oracle VPS` + `DataManager Node`) mostrando CPU, RAM, uso de disco y temperaturas/GPU vía red privada Tailscale (`100.77.82.13:61208`).
* **Scrutiny (S.M.A.R.T.)**:
  - Estado de salud y vida útil de los discos NVMe/SSD de los servidores para prevención de fallos catastróficos.
* **Prometheus / Node Exporter**:
  - Alternativa si se requiere histórico de métricas a largo plazo sin sobrecargar la RAM.

### B. Contenedores y Orquestación (Docker & Coolify)
* **Docker Socket Integration (Métricas en vivo por app)**:
  - *Mecanismo*: Montaje seguro de `/var/run/docker.sock` (o mediante `tecnativa/docker-socket-proxy` para modo sólo lectura).
  - *Funcionalidad*:
    - Cada tarjeta en Homepage (ByteBox, Infisical, Homepage, Traefik) muestra dinámicamente: estado del contenedor (`running`, `unhealthy`), consumo exacto de CPU (%) y RAM (MB).
    - Botones de acción opcionales con control de acceso (reiniciar contenedor desde la UI).
* **Portainer / Watchtower**:
  - Insignia de notificación automática cuando existan imágenes de contenedores con actualizaciones pendientes en Docker Hub o GHCR.
* **Coolify API Widget**:
  - Tarjeta o widget que consulte `/api/v1/applications` para reportar el estado de los despliegues de Coolify.

### C. Inferencia IA y Pasarelas Locales ($0)
* **Widget Oficial de Ollama**:
  - Conexión directa contra `http://100.77.82.13:11434`.
  - *Visualización*: Muestra el listado de modelos instalados (`qwen2.5:7b`, `llama3.1:8b`, `deepseek-r1:8b`), estado del daemon y VRAM consumida.
* **OmniRoute & FreeLLMAPI (Custom API Widget)**:
  - Uso del widget genérico `customapi` de Homepage consultando `/models` y `/health`.
  - Muestra el número de proveedores activos, latencia media de respuesta y estado de los modelos gratuitos.

### D. Red, Perímetro y Seguridad
* **Tailscale**:
  - Widget nativo de Tailscale que verifique qué nodos de la malla están online/offline (workstation local, `datamanager`, `oracle`).
* **Cloudflare Zero Trust & Tunnels**:
  - Monitorización del estado de los túneles Cloudflare (`cloudflared`), peticiones bloqueadas en el WAF y tráfico diario.
* **Uptime Kuma / Ping Services**:
  - Incorporar gráficos sparkline o barras de disponibilidad de los últimos 90 días para APIs críticas.
* **Speedtest Tracker**:
  - Medición programada de ancho de banda y latencia desde los nodos hacia internet.

### E. Productividad de Desarrollo y Operaciones del Agente
* **Buscador Integrado SearXNG**:
  - Campo de búsqueda integrado en la cabecera de Homepage que despache consultas directamente a la instancia autoalojada en `http://100.77.82.13:8080`.
* **GitHub Widget**:
  - Conectado al repo `romensuarezr/agent-os` con token personal:
  - Muestra ramas abiertas, PRs pendientes de revisión, último commit y estado de GitHub Actions.
* **ByteBox Quick-Access**:
  - Acceso directo y tarjeta de estado para el gestor de comandos y snippets recién desplegado.
* **Sentry**:
  - Widget que reporta el conteo de errores no controlados en producción para las apps de la flota.

---

## 3. Seguridad y Control de Acceso

1. **Protección Perimetral**:
   - Actualmente Homepage está abierto en su dominio público o sslip.io.
   - Integrar autenticación por cabeceras (`remote-user`) mediante **Cloudflare Zero Trust (Access)** o un Basic Auth ligero en Traefik, evitando exponer el panel de control a internet abierto.
2. **Aislamiento del Docker Socket**:
   - Nunca montar `/var/run/docker.sock` con permisos de escritura sin intermediario.
   - Utilizar el contenedor `docker-socket-proxy` restringido a endpoints GET (`CONTAINERS=1`, `INFO=1`, `POST=0`) para máxima seguridad contra escalada de privilegios.

---

## 4. Estrategia de Implementación en Agent OS

* **Generador Unificado**: Extender `scripts/agent/generate-homepage-config.sh` para que lea bloques opcionales en `config/fleet.yaml` (ej. `monitoring: { glances: true, docker_socket: true, widgets: [ollama, searxng] }`) y genere los bloques correspondientes en `widgets.yaml` y `services.yaml`.
* **Despliegue por Fases**:
  - **Fase 1 (Inmediata / Telemetría y Docker)**: Docker socket proxy en `oracle` + Glances en `datamanager` + Widget Ollama.
  - **Fase 2 (Red y Seguridad)**: Cloudflare Access / Zero Trust + Widget Tailscale.
  - **Fase 3 (Agentes y DX)**: Buscador SearXNG + Widget GitHub repo + ByteBox quick-access.
