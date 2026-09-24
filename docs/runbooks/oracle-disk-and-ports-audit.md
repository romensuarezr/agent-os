# Auditoría de Capacidad de Disco y Exposición de Puertos en `oracle`

> **Fecha**: 2026-09-24  
> **Host**: `oracle` (`vnic-rsr` / `100.96.20.7`)  
> **Objetivo**: Diagnóstico integral y no destructivo del almacenamiento y superficie de ataque del VPS de infraestructura.  
> **Herramienta utilizada**: `.agents/skills/remote-admin/scripts/audit-host.sh`

---

## 1. Resumen Ejecutivo

| Métrica | Estado Actual | Diagnóstico | Potencial de Recuperación / Remediación |
| :--- | :--- | :--- | :--- |
| **Uso de Disco (`/dev/sda1`)** | 139 GB usados de 193 GB (**72%**) | 83 GB en descargas residuales de seedbox + 33 GB en Docker | **~116 GB recuperables** (el uso caería de 72% a **~12%**) |
| **Salud de Docker** | 33 contenedores activos, 0 caídos | 30.91 GB de imágenes recuperables (91%), 25 volúmenes huérfanos | 31 GB imágenes + 480 MB volúmenes + 2.18 GB build cache |
| **Firewall del Host (UFW)** | **No instalado** / Inactivo | Iptables en `-P INPUT ACCEPT`. Docker expone directo a WAN | Requiere política de firewall o blindaje en `DOCKER-USER` |
| **Superficie de Red** | Múltiples servicios en `0.0.0.0` | Puertos `5800` (JDownloader), `8000` (Coolify), `5050`, `8888`, `111` expuestos | Restringir a `127.0.0.1` o IP Tailscale (`100.96.20.7`) |

---

## 2. Diagnóstico Detallado de Almacenamiento

### 2.1 Desglose de Partición Raíz (`/dev/sda1`)
```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       193G  139G   55G  72% /
```

### 2.2 Desglose por Directorio Raíz
El análisis reveló que el grueso del espacio consumido **no está en los contenedores de Docker ni en el sistema operativo**, sino en `/home`:

```text
87G     /home
3.6G    /var (Docker + Logs del sistema)
3.5G    /usr
888M    /snap
789M    /opt
147M    /boot
```

### 2.3 Localización Exacta del Consumo en `/home`
Dentro de `/home/ubuntu`:
- **`/home/ubuntu/seedbox/downloads`**: **83 GB** (miles de archivos de vídeo `.mp4` residuales descargados en julio de 2024, pertenecientes al usuario `opc`).
- **`/home/ubuntu/.hermes`**: 1.7 GB (contexto operativo / memoria de Hermes).
- **`/home/ubuntu/.cache`**: 894 MB.
- Resto de directorios: < 100 MB.

### 2.4 Estado del Almacenamiento en Docker (`docker system df`)
```text
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          35        31        33.74GB   30.91GB (91%)
Containers      33        33        658.1MB   0B (0%)
Local Volumes   39        14        3.44GB    480.4MB (13%)
Build Cache     9         9         2.183GB   0B
```

- **Imágenes residuales/intermedias**: 30.91 GB marcadas como recuperables por Docker (capas de compilaciones antiguas de Coolify).
- **Volúmenes huérfanos (`dangling=true`)**: 25 volúmenes locales sin contenedor asociado (antiguas apps de Coolify como `evolution-api_*`, `surfsense-*`, `grafana-*`, `minio-*`).
- **Logs de contenedores (`*-json.log`)**: Se encuentran acotados de forma saludable (el mayor mide 9.5 MB), lo que demuestra que la rotación de logs de Coolify/Docker está funcionando correctamente.

---

## 3. Diagnóstico Detallado de Red y Puertos

### 3.1 Estado del Firewall
- **UFW**: No instalado (`ufw: command not found`).
- **Iptables base**: Cadena `INPUT` en política `ACCEPT` abierta.
- **Docker Bypass**: La cadena `DOCKER-USER` no tiene reglas configuradas. Cuando un contenedor publica un puerto con `-p 8000:8000`, Docker inserta reglas de prerouting que **saltan cualquier restricción local**, exponiendo el puerto directamente al exterior.

### 3.2 Clasificación de Puertos en Escucha

| Puerto / Protocolo | Proceso / Contenedor | Destino de Enlace | Nivel de Riesgo | Recomendación |
| :--- | :--- | :--- | :---: | :--- |
| `0.0.0.0:80`, `443` | `coolify-proxy` (Traefik) | Público (WAN) | 🟢 Esperado | Tráfico web público con certificados Let's Encrypt |
| `0.0.0.0:22` | OpenSSH daemon | Público (WAN) | 🟡 Medio | Autenticado por clave. Se recomienda mover a Tailscale o endurecer |
| `0.0.0.0:111` | `rpcbind` (SunRPC) | Público (WAN) | 🔴 Alto | Innecesario en VPS web; vector de amplificación DDoS. Deshabilitar servicio `rpcbind` |
| `0.0.0.0:5800` | `jdownloader2-vps` | Público (WAN) | 🔴 Alto | Interfaz gráfica Web/VNC de descargas accesible sin cifrado desde internet. Enlazar a `127.0.0.1` o `100.96.20.7` |
| `0.0.0.0:8000` | `coolify` (Admin Dashboard) | Público (WAN) | 🔴 Alto | Panel de control de infraestructura accesible en crudo. Acceder sólo vía dominio Traefik o VPN |
| `0.0.0.0:5050` | `piper-tts-server` | Público (WAN) | 🔴 Alto | Motor de síntesis de voz expuesto públicamente. Enlazar a Tailscale o red interna Docker |
| `0.0.0.0:8888` | `bot-zk8csgs040w8wscg4...` | Público (WAN) | 🟡 Medio | Mapeo de puerto directo de bot. Evaluar si debe ser público o pasar por Traefik |
| `0.0.0.0:3000` | `dashboard-zk8csgs...` | Público (WAN) | 🟡 Medio | Dashboard mapeado a `0.0.0.0`. Enrutar por Traefik o aislar |
| `0.0.0.0:6001-6002` | `coolify-realtime` | Público (WAN) | 🟡 Medio | WebSockets de Coolify. Deberían estar proxificados bajo HTTPS |
| `127.0.0.1:5432` | `db-zk8csgs040w8...` (Postgres) | Localhost | 🟢 Seguro | Correctamente aislado en loopback |
| `100.96.20.7:53444` | Tailscale | VPN Privada | 🟢 Seguro | Conexión segura de la malla interna |

---

## 4. Plan de Remediación Propuesto (Decision Gates Requeridos)

> ⚠️ **IMPORTANTE**: Ninguna de estas acciones se ejecutó en esta tarea T-035 (estricto modo solo lectura). Quedan formuladas aquí con su comando exacto para aprobación humana expresa.

### 4.1 Remediación de Almacenamiento (Recuperación de hasta 116 GB)

#### Acción 1: Limpieza del directorio de descargas huérfanas de seedbox (~83 GB)
- **Impacto**: Libera 83 GB de inmediato en `/dev/sda1`.
- **Riesgo**: Pérdida de vídeos antiguos si no han sido respaldados por el usuario.
- **Comando de verificación previo**:
  ```bash
  ssh oracle "ls -la /home/ubuntu/seedbox/downloads | head -20"
  ```
- **Comando propuesto tras aprobación**:
  ```bash
  ssh oracle "rm -rf /home/ubuntu/seedbox/downloads/*"
  ```

#### Acción 2: Poda de imágenes Docker y caché de construcción huérfana (~33 GB)
- **Impacto**: Libera ~31 GB de capas de compilación antiguas sin detener ningún contenedor en ejecución.
- **Riesgo**: Mínimo. Docker no borra imágenes en uso por contenedores activos.
- **Comando propuesto tras aprobación**:
  ```bash
  ssh oracle "docker image prune -a -f"
  ssh oracle "docker builder prune -f"
  ```

#### Acción 3: Poda de volúmenes huérfanos (`dangling`) (~480 MB)
- **Impacto**: Elimina los 25 volúmenes de proyectos destruidos de Coolify.
- **Riesgo**: Ninguno para contenedores activos; los 14 volúmenes en uso están protegidos.
- **Comando propuesto tras aprobación**:
  ```bash
  ssh oracle "docker volume prune -f"
  ```

---

### 4.2 Remediación de Seguridad de Red y Puertos

#### Acción 1: Deshabilitar el servicio `rpcbind` (Puerto 111)
- **Impacto**: Cierra el puerto 111 y elimina el vector de ataque UDP.
- **Comando propuesto tras aprobación**:
  ```bash
  ssh oracle "sudo systemctl stop rpcbind rpcbind.socket && sudo systemctl disable rpcbind rpcbind.socket"
  ```

#### Acción 2: Re-enlazar puertos de servicios administrativos a Tailscale (`100.96.20.7`)
- **Impacto**: `jdownloader2` (5800) y `coolify` (8000) dejan de responder en la IP pública y sólo son accesibles a través de la red privada Tailscale de nuestros dispositivos autorizados.
- **Procedimiento**: En la configuración de Coolify / Docker Compose, cambiar la publicación de puertos de:
  `- "5800:5800"`  ➡️  `- "100.96.20.7:5800:5800"`
  `- "8000:8080"`  ➡️  `- "100.96.20.7:8000:8080"`

#### Acción 3: Instalación y configuración de UFW con salvaguarda de Docker
- **Impacto**: Proteger el host a nivel de kernel mediante reglas por defecto `DEFAULT_FORWARD_POLICY="DROP"` y allowlist explícito en `DOCKER-USER` para puertos públicos (80, 443, 22) y allow total en interfaz `tailscale0`.

---

## 5. Conclusión y Estado de la Tarea

La auditoría T-035 ha identificado con precisión quirúrgica:
1. La causa raíz de la alerta de disco al 72% (no es Coolify, sino 83 GB de vídeos descargados en `seedbox/downloads` + 31 GB de capas de imágenes Docker huérfanas).
2. La topología de exposición de puertos y la ausencia de firewall en el host.
3. El script reutilizable `.agents/skills/remote-admin/scripts/audit-host.sh` queda integrado en el core de `agent-os` y en la skill `remote-admin`, permitiendo auditar cualquier servidor en 1 sola llamada rápida de solo lectura para ahorrar tokens.
