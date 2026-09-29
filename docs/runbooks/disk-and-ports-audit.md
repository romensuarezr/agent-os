# Auditoría de Capacidad de Disco y Exposición de Puertos en Servidores Remotos (Host VPS)

> **Fecha**: 2026-09-24  
> **Host**: `<infra-node>` (IP Tailscale `<TAILSCALE_IP>`, configurado en `config/fleet.yaml` o `~/.ssh/config`)  
> **Objetivo**: Diagnóstico integral y no destructivo del almacenamiento y superficie de ataque del VPS de infraestructura.  
> **Herramienta utilizada**: `.agents/skills/remote-admin/scripts/audit-host.sh`

---

## 1. Resumen Ejecutivo

| Métrica | Estado Actual | Diagnóstico | Potencial de Recuperación / Remediación |
| :--- | :--- | :--- | :--- |
| **Uso de Disco (`/dev/sda1`)** | 139 GB usados de 193 GB (**72%**) | 83 GB en descargas residuales + 33 GB en Docker | **~116 GB recuperables** (el uso caería de 72% a **~12%**) |
| **Salud de Docker** | 33 contenedores activos, 0 caídos | 30.91 GB de imágenes recuperables (91%), 25 volúmenes huérfanos | 31 GB imágenes + 480 MB volúmenes + 2.18 GB build cache |
| **Firewall del Host (UFW)** | **No instalado** / Inactivo | Iptables en `-P INPUT ACCEPT`. Docker expone directo a WAN | Requiere política de firewall o blindaje en `DOCKER-USER` |
| **Superficie de Red** | Múltiples servicios en `0.0.0.0` | Puertos administrativos expuestos en WAN | Restringir a `127.0.0.1` o IP Tailscale (`<TAILSCALE_IP>`) |

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
Dentro del directorio de usuario:
- **`~/downloads`**: **83 GB** (archivos de medios residuales).
- **`~/.hermes`**: 1.7 GB (contexto operativo / memoria de agentes).
- **`~/.cache`**: 894 MB.
- Resto de directorios: < 100 MB.

### 2.4 Estado del Almacenamiento en Docker (`docker system df`)
```text
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          35        31        33.74GB   30.91GB (91%)
Containers      33        33        658.1MB   0B (0%)
Local Volumes   39        14        3.44GB    480.4MB (13%)
Build Cache     9         9         2.183GB   0B
```

- **Imágenes residuales/intermedias**: 30.91 GB marcadas como recuperables por Docker (capas de compilaciones antiguas).
- **Volúmenes huérfanos (`dangling=true`)**: 25 volúmenes locales sin contenedor asociado de aplicaciones retiradas.
- **Logs de contenedores (`*-json.log`)**: Se encuentran acotados de forma saludable, demostrando rotación de logs efectiva.

---

## 3. Diagnóstico Detallado de Red y Puertos

### 3.1 Estado del Firewall
- **UFW**: No instalado (`ufw: command not found`).
- **Iptables base**: Cadena `INPUT` en política `ACCEPT` abierta.
- **Docker Bypass**: La cadena `DOCKER-USER` no tiene reglas configuradas. Cuando un contenedor publica un puerto con `-p 8000:8000`, Docker inserta reglas de prerouting que **saltan cualquier restricción local**, exponiendo el puerto directamente al exterior.

### 3.2 Clasificación de Puertos en Escucha

| Puerto / Protocolo | Proceso / Contenedor | Destino de Enlace | Nivel de Riesgo | Recomendación |
| :--- | :--- | :--- | :---: | :--- |
| `0.0.0.0:80`, `443` | Reverse Proxy (Traefik) | Público (WAN) | 🟢 Esperado | Tráfico web público con certificados SSL |
| `0.0.0.0:22` | OpenSSH daemon | Público (WAN) | 🟡 Medio | Autenticado por clave. Se recomienda mover a Tailscale o endurecer |
| `0.0.0.0:111` | `rpcbind` (SunRPC) | Público (WAN) | 🔴 Alto | Innecesario en VPS web; vector de amplificación DDoS. Deshabilitar servicio `rpcbind` |
| `0.0.0.0:5800` | UI de descargas | Público (WAN) | 🔴 Alto | Interfaz gráfica Web/VNC accesible sin cifrado desde internet. Enlazar a `127.0.0.1` o `<TAILSCALE_IP>` |
| `0.0.0.0:8000` | Admin Dashboard PaaS | Público (WAN) | 🔴 Alto | Panel de control de infraestructura accesible en crudo. Acceder sólo vía dominio con TLS o VPN |
| `0.0.0.0:5050` | TTS Service | Público (WAN) | 🔴 Alto | Motor de síntesis expuesto públicamente. Enlazar a Tailscale o red interna Docker |
| `127.0.0.1:5432` | Postgres interno | Localhost | 🟢 Seguro | Correctamente aislado en loopback |
| `<TAILSCALE_IP>:53444` | Tailscale | VPN Privada | 🟢 Seguro | Conexión segura de la malla interna |

---

## 4. Plan de Remediación Propuesto (Decision Gates Requeridos)

> ⚠️ **IMPORTANTE**: Ninguna acción destructiva debe ejecutarse sin aprobación humana expresa.

### 4.1 Remediación de Almacenamiento (Recuperación de hasta 116 GB)

#### Acción 1: Limpieza del directorio de descargas huérfanas (~83 GB)
- **Impacto**: Libera 83 GB de inmediato en `/dev/sda1`.
- **Riesgo**: Pérdida de archivos si no han sido respaldados previamente por el usuario.
- **Comando de verificación previo**:
  ```bash
  ssh <infra-node> "ls -la ~/downloads | head -20"
  ```
- **Comando propuesto tras aprobación**:
  ```bash
  ssh <infra-node> "rm -rf ~/downloads/*"
  ```

#### Acción 2: Poda de imágenes Docker y caché de construcción huérfana (~33 GB)
- **Impacto**: Libera ~31 GB de capas de compilación antiguas sin detener ningún contenedor en ejecución.
- **Riesgo**: Mínimo. Docker no borra imágenes en uso por contenedores activos.
- **Comando propuesto tras aprobación**:
  ```bash
  ssh <infra-node> "docker image prune -a -f"
  ssh <infra-node> "docker builder prune -f"
  ```

#### Acción 3: Poda de volúmenes huérfanos (`dangling`) (~480 MB)
- **Impacto**: Elimina volúmenes de proyectos destruidos.
- **Riesgo**: Ninguno para contenedores activos; los volúmenes en uso están protegidos.
- **Comando propuesto tras aprobación**:
  ```bash
  ssh <infra-node> "docker volume prune -f"
  ```

---

### 4.2 Remediación de Seguridad de Red y Puertos

#### Acción 1: Deshabilitar el servicio `rpcbind` (Puerto 111)
- **Impacto**: Cierra el puerto 111 y elimina el vector de ataque UDP.
- **Comando propuesto tras aprobación**:
  ```bash
  ssh <infra-node> "sudo systemctl stop rpcbind rpcbind.socket && sudo systemctl disable rpcbind rpcbind.socket"
  ```

#### Acción 2: Re-enlazar puertos de servicios administrativos a Tailscale (`<TAILSCALE_IP>`)
- **Impacto**: Los puertos administrativos dejan de responder en la IP pública y sólo son accesibles a través de la red privada Tailscale de dispositivos autorizados.
- **Procedimiento**: En la configuración de Docker Compose, cambiar la publicación de puertos de:
  `- "5800:5800"`  ➡️  `- "<TAILSCALE_IP>:5800:5800"`
  `- "8000:8080"`  ➡️  `- "<TAILSCALE_IP>:8000:8080"`

#### Acción 3: Instalación y configuración de UFW con salvaguarda de Docker
- **Impacto**: Proteger el host a nivel de kernel mediante reglas por defecto `DEFAULT_FORWARD_POLICY="DROP"` y allowlist explícito en `DOCKER-USER` para puertos públicos (80, 443, 22) y allow total en interfaz `tailscale0`.

---

## 5. Conclusión y Estado de la Tarea

La auditoría permite diagnosticar:
1. La causa raíz de la alerta de disco (archivos huérfanos en disco + capas de imágenes Docker intermedias).
2. La topología de exposición de puertos y el estado del firewall en el host.
3. El script reutilizable `.agents/skills/remote-admin/scripts/audit-host.sh` queda integrado en el core de `agent-os` y en la skill `remote-admin`, permitiendo auditar cualquier servidor en 1 sola llamada rápida de solo lectura para ahorrar tokens.
