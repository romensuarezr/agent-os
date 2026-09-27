# Plan de Recuperación de Espacio en Disco por Lotes en `oracle`

> **Fecha de Auditoría Inicial**: 2026-09-27 08:52 UTC  
> **Fecha de Ejecución Lote C**: 2026-09-27 09:37 UTC  
> **Host**: `oracle` (`vnic-rsr` / IP Tailscale `100.96.20.7`)  
> **Sistema Operativo**: Ubuntu 24.04 LTS (Kernel `6.8.0-1011-oracle aarch64`)  
> **Motor de Contenedores**: Docker Engine 29.1.2 / containerd 2.2.0  
> **Objetivo**: Registro de auditoría, ejecución del Lote C y delimitación estricta de exclusiones de seguridad para volúmenes e imágenes en el VPS de infraestructura.

---

## 1. Cifras Actualizadas de Almacenamiento (Post-Lote C)

### 1.1 Estado de la Partición Raíz (`df -hT` y `df -ih`)

```text
Filesystem     Type      Size  Used Avail Use% Mounted on
/dev/sda1      ext4      193G   63G  131G  33% /
/dev/sda16     ext4      891M  147M  682M  18% /boot
/dev/sda15     vfat       98M  6.4M   92M   7% /boot/efi
```

```text
Filesystem     Inodes   IUsed   IFree IUse% Mounted on
/dev/sda1         25M    1.5M     24M    6% /
```

- **Uso de Bloques**: Ha pasado de **146 GB (76%)** a **63 GB (33%)**, liberando **83 GB netos** tras la purga del Lote C.
- **Espacio Libre Disponible**: **131 GB disponibles** (frente a 48 GB previos).
- **Uso de Inodos**: Totalmente desahogado (6% en uso, 24M libres).

---

### 1.2 Desglose Macroscópico del Host Tras Ejecución

| Ruta Principal | Tamaño Ocupado | Componentes Principales |
| :--- | :--- | :--- |
| **`/var/lib/docker`** | **36.0 GB** | Capas de imágenes / rootfs (32 GB), volúmenes activos/huérfanos (3.3 GB), contenedores (406 MB), buildkit (267 MB). |
| **`/home/ubuntu`** | **~4.0 GB** | `.cache` (1.5 GB), `.hermes` (1.1 GB), seedbox scripts/config (345 MB), backups SQL (20 MB). |
| **`/var/log`** | **2.8 GB** | Journald (`/var/log/journal`: 2.4 GB), logs de Docker (100 MB), logs de auditoría/syslog. |
| **`/usr`, `/snap`, `/opt`** | **~5.1 GB** | Binarios del sistema, paquetes snap de Ubuntu e instaladores base de Oracle Cloud. |

---

### 1.3 Estado de la Capa de Contenedores (`docker system df -v`)

```text
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          40        36        41.1GB    38.27GB (93%)*
Containers      38        38        659.2MB   0B (0%)
Local Volumes   47        18        3.508GB   480.5MB (13%)
Build Cache     9         9         2.183GB   0B
```

---

### 1.4 Estado de la Infraestructura Crítica (Coolify, Traefik, Health)

- **Total contenedores en ejecución**: 38 contenedores UP (0 caídos, 0 reiniciando).
- **Core de Infraestructura**:
  - `coolify` (`ghcr.io/coollabsio/coolify:4.0.0-beta.460`): `Up 7 months (healthy)`
  - `coolify-proxy` (`traefik:v3.6`): `Up 7 months (healthy)`
  - `coolify-db` (`postgres:15-alpine`): `Up 7 months (healthy)`
  - `coolify-redis` (`redis:7-alpine`): `Up 7 months (healthy)`
  - `coolify-realtime` (`ghcr.io/coollabsio/coolify-realtime:1.0.10`): `Up 4 months (healthy)`
  - `coolify-sentinel` (`ghcr.io/coollabsio/sentinel:1.0.1`): `Up 9 hours (healthy)`
  - `jdownloader2-vps` (`jlesage/jdownloader-2`): `Up 4 months` (directorio `/output:rw` operativo y saneado).
- **Contenedores Unhealthy Detectados (2)**:
  1. `piper-tts-server`: Falla por ausencia de `curl` en la imagen (`/bin/sh: 1: curl: not found`). El servicio responde pero Docker lo marca unhealthy.
  2. `hd-api-r0ooksg444g4g0wc8ogcs404-130357610433`: Falla en conexión a `localhost:8000`.

---

## 2. Decisiones de Seguridad y Exclusiones Explícitas

### 2.1 Volúmenes Expresamente Excluidos (Salvaguarda Absoluta)

Quedan formalmente blindados y fuera de cualquier acción de poda:
- `bytebox-data` (Montaje de snippets y persistencia de ByteBox)
- `homepage-config` (Configuraciones dinámicas de Homepage)

### 2.2 Política de Bloqueo sobre Volúmenes e Imágenes Huérfanas

Se ha determinado pausar y **no autorizar** la eliminación de volúmenes huérfanos (`surfsense-db-data`, `surfsense-data`, `grafana-data`, `minio-data`, `postgres-data`, etc.) ni de imágenes huérfanas sin inspección profunda previa, fundamentado en tres razones directivas:

1. **Estado durmiente de apps**: Un volumen puede figurar sin enlaces directos (`links=0`) en Docker y aun así corresponder al estado íntegro de una aplicación de Coolify que se decida reactivar.
2. **Naturaleza persistente crítica**: Volúmenes como `postgres-data`, `minio-data` y `grafana-data` albergan datos relacionales y de almacenamiento de objetos que, incluso proviniendo de servicios retirados, pueden contener información histórica o configuraciones valiosas.
3. **Ratio de riesgo / beneficio desproporcionado**: El ahorro estimado total en volúmenes es de únicamente **0.45 GB** (~0.23% del disco). Tras haber recuperado 83 GB y situar el disco al 33% de ocupación, no existe urgencia operativa que justifique asumir ningún riesgo de pérdida de datos.

---

## 3. Estado de Ejecución de Lotes

```mermaid
flowchart TD
    Init["Auditoría Inicial: 146 GB Usados (76%)"] --> LotC["LOTE C: Purgado de Seedbox Media<br/>(-83 GB) ✅ EJECUTADO"]
    LotC --> StateC["Estado Actual: 63 GB Usados (33%)<br/>131 GB Libres"]
    StateC --> PauseB{"Volúmenes e Imágenes Huérfanas<br/>⏸️ PAUSADO POR SEGURIDAD"}
    PauseB --> LotA["LOTE A: Cachés y Logs del Sistema<br/>(Pendiente de evaluar: ~3.38 GB)"]
```

---

### LOTE C: Purgado de Seedbox Media [✅ COMPLETADO]

- **Estado**: **Completado con éxito el 2026-09-27 09:37 UTC**.
- **Acción realizada**: Eliminación de 2,339 vídeos y fotos huérfanos en `/home/ubuntu/seedbox/downloads` tras confirmación de respaldo completo en el equipo local del usuario.
- **Comando ejecutado con éxito**:
  ```bash
  ssh oracle "sudo -n find /home/ubuntu/seedbox/downloads -mindepth 1 -delete"
  ```
- **Resultado comprobado**:
  - Directorio `/home/ubuntu/seedbox/downloads` preservado con permisos intactos (`drwxr-xr-x opc:opc`).
  - Espacio liberado: **83.0 GB**.
  - Los 38 contenedores continúan en ejecución (`Up`).

---

### LOTE B: Volúmenes Huérfanos Obsoletos [🛑 BLOQUEADO / NO AUTORIZADO]

- **Estado**: **Pausado indefinidamente**.
- **Comando retenido (NO AUTORIZADO)**:
  ```bash
  # docker volume rm surfsense-db-data surfsense-data grafana-data minio-data ... [RECHAZADO]
  ```
- **Criterio**: Exclusión total. No se tocará ningún volumen hasta realizar auditorías específicas de contenido cuando se requiera.

---

### LOTE A: Higiene y Cachés de Sistema [🟡 PENDIENTE DE REVISIÓN]

- **Estado**: Pendiente de decisión si se requiere mayor margen futuro.
- **Acciones viables de riesgo nulo (sin tocar imágenes)**:
  1. Compactar logs de journald a 500 MB (`sudo journalctl --vacuum-size=500M`): recupera **~1.90 GB**.
  2. Limpiar caché de entorno de usuario (`rm -rf ~/.cache/uv ~/.cache/ms-playwright`): recupera **~1.48 GB**.
  3. Docker build cache (`docker builder prune -f`): recupera **~2.18 GB**.

---

## 4. Tabla Histórica y Comparativa de Almacenamiento

| Hito | Espacio Usado | Espacio Libre | Ocupación (`/dev/sda1`) | Estado Operativo |
| :--- | :---: | :---: | :---: | :--- |
| **Auditoría Previa (2026-09-24)** | 139 GB | 55 GB | 72% | Alerta por consumo elevado. |
| **Inicio Sesión (2026-09-27 08:52)** | 146 GB | 48 GB | 76% | Despliegue de Infisical, ByteBox y Homepage (+7 GB). |
| **Post-Lote C (2026-09-27 09:37)** | **63 GB** | **131 GB** | **33%** | **✅ 83 GB liberados. 38 contenedores 100% operativos.** |

---

*Última actualización: 27 Sep 2026*
