# Runbook: Diagnóstico Determinista de Flota (fleet-doctor.sh)

> **Fecha**: 2026-09-28  
> **Objetivo**: Guía de referencia operativa y especificación técnica de `scripts/agent/fleet-doctor.sh`.  
> **Coste de tokens**: 0 tokens de inferencia (resolución determinista local).  
> **Compatibilidad**: Linux / POSIX, Python 3.8+, Bash 4+.  
> **Requisitos**: PyYAML opcional — solo necesario para parsear fleet.yaml; sin él, el diagnóstico de flota se omite con aviso.

---

## 1. Propósito y Principios de Diseño

`fleet-doctor.sh` es la herramienta de diagnóstico de primer nivel en Agent OS. Proporciona una comprobación determinista de:
1. **Tooling CLI local**: Presencia y estado de binarios críticos (`git`, `gh`, `docker`, `infisical`, `tailscale`).
2. **Autenticación funcional**: Validación en tiempo de ejecución de sesiones activas (cuenta `gh`, perfiles de `infisical`, demonio Docker, conexión Tailscale).
3. **Conectividad viva de servicios de la flota**: Probes TCP directos y comprobaciones HTTP rápidas contra los servicios declarados en la flota con timeout estricto de 2s por socket.

### Principios Fundamentales

- **0 tokens de inferencia**: Ejecutado enteramente mediante lógica local Bash y Python (`socket`, `urllib`, `subprocess`). No requiere llamadas a LLMs.
- **Enmascaramiento estricto de privacidad e infraestructura**: Ninguna dirección IP, hostname interno o token de autenticación se expone en texto plano ni en modo texto ni en modo `--json`.
- **Digest de texto acotado**: El modo texto estándar está limitado rígidamente a un máximo de 20 líneas legibles para consumo inmediato por agentes y humanos.
- **Agnosticismo y desacoplamiento**: Si `.agents/config/fleet.yaml` no existe en el entorno (por ser un archivo gitignored específico del operador), el script opera contra `.agents/config/fleet.example.yaml` en modo documentación (`SKIPPED-NO-FLEET`), evitando falsos positivos en pipelines de CI o máquinas nuevas.

---

## 2. Sintaxis y Opciones de CLI

```bash
bash scripts/agent/fleet-doctor.sh [OPCIONES]
```

| Opción | Argumento | Valor por defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `--fleet` | `<ruta>` | `.agents/config/fleet.yaml` (o `fleet.example.yaml`) | Archivo declarativo de topología de flota a auditar. |
| `--json` | Flag booleano | `false` | Emite la telemetría en JSON estructurado para agentes u orquestadores (`Orca ADE`, `Hermes`). |
| `--timeout` | `<segundos>` | `2` | Timeout máximo no bloqueante para probes TCP o peticiones HTTP por endpoint. |
| `--strict` | Flag booleano | `false` | Retorna código de salida `1` si hay servicios caídos (`DOWN`) o CLIs esenciales rotos. |
| `--check` | Flag booleano | `false` | Comprobación rápida de integridad de sintaxis y entorno sin probes prolongados. |
| `-h`, `--help` | — | — | Muestra la ayuda y resumen de opciones. |

---

## 3. Política de Enmascaramiento Estricto (IPs y Credenciales)

Por directiva de gobernanza de Agent OS, ningún log o digest de diagnóstico puede filtrar direcciones privadas o secretos de infraestructura hacia repositorios, transcripciones de agentes o consolas compartidas.

### Reglas de Enmascaramiento

1. **Direcciones IPv4**:
   - Se procesan con sustitución regular para enmascarar los octetos centrales:
     `100.99.88.77` ➔ `100.***.***.77`
   - En direcciones genéricas o de prueba: `[MASKED]`
2. **Hostnames y Dominios**:
   - Nombres de dominio internos o sufijos DNS:
     `worker-node-01.mesh.local` ➔ `worker-node-01.[MASKED-DOMAIN]`
3. **Endpoints y URLs**:
   - Esquemas y puertos preservados para diagnóstico de conectividad, pero host enmascarado:
     `http://100.99.88.77:3001/v1` ➔ `http://[MASKED-HOST]:3001/v1`
4. **Tokens y Secretos de Autenticación**:
   - Todo campo que contenga tokens Bearer, contraseñas o API keys es reportado como:
     `[auth:masked]` o `bearer_masked` en JSON.
   - Tokens detectados en texto se reducen a prefijo de 4 caracteres y máscara: `gho_***` o `[MASKED]`.

---

## 4. Ejemplos de Salida

### 4.1 Modo Texto Estándar (Digest ≤ 20 líneas)

#### Con `.agents/config/fleet.yaml` activo (entorno con flota configurada):
```text
=== FLEET DOCTOR DIGEST ===
Fleet: .agents/config/fleet.yaml (active overlay)
CLIs: git:CLEAN | gh:AUTH (romensuarezr) | docker:UP | infisical:PROFILE-ACTIVE | tailscale:CONNECTED
• [worker-node-01] (inference-and-data): freellmapi:3001:UP (HTTP 200) [auth:masked], ollama:11434:UP, glances:61208:UP
• [saas-node-02] (orchestration-and-paas): coolify:UP, orca_gateway:8000:UP, bytebox:UP, homepage:UP
Summary: CLIs 5/5 OK | Services: 7 UP, 0 DOWN, 0 SKIPPED
=== FIN FLEET DOCTOR (0 tokens inferidos, 0 IPs expuestas) ===
```

#### Sin `.agents/config/fleet.yaml` (modo agnóstico / documentación con `fleet.example.yaml`):
```text
=== FLEET DOCTOR DIGEST ===
Fleet: .agents/config/fleet.example.yaml [MODE: SKIPPED-NO-FLEET]
CLIs: git:DIRTY | gh:AUTH (romensuarezr) | docker:DOWN | infisical:NO-PROFILE | tailscale:CONNECTED
Nodes: (Sin fleet.yaml local — conectividad de flota omitida en modo agnóstico)
Summary: CLIs 3/5 OK | Services: 0 UP, 0 DOWN, 10 SKIPPED
=== FIN FLEET DOCTOR (0 tokens inferidos, 0 IPs expuestas) ===
```

### 4.2 Modo Estructurado `--json`

Invocación: `bash scripts/agent/fleet-doctor.sh --json`

```json
{
  "doctor_version": "1.0.0",
  "summary": {
    "overall_healthy": true,
    "fleet_mode": "ACTIVE",
    "clis_checked": 5,
    "clis_ok": 5,
    "services_checked": 7,
    "services_up": 7,
    "services_down": 0
  },
  "clis": {
    "git": { "installed": true },
    "gh": { "installed": true },
    "docker": { "installed": true },
    "infisical": { "installed": true },
    "tailscale": { "installed": true }
  },
  "authentication": {
    "git": { "ok": true, "status": "CLEAN" },
    "gh": { "ok": true, "status": "AUTH (romensuarezr)", "user": "romensuarezr" },
    "infisical": { "ok": true, "status": "PROFILE-ACTIVE" },
    "tailscale": { "ok": true, "status": "CONNECTED" },
    "docker": { "ok": true, "status": "UP" }
  },
  "fleet": {
    "source": ".agents/config/fleet.yaml",
    "mode": "ACTIVE",
    "nodes": {
      "worker-node-01": {
        "role": "inference-and-data",
        "host_masked": "100.***.***.77",
        "services": {
          "freellmapi": {
            "status": "UP (HTTP 200)",
            "port": 3001,
            "endpoint_masked": "http://[MASKED-HOST]:3001/v1",
            "auth": "bearer_masked"
          },
          "ollama": {
            "status": "UP",
            "port": 11434,
            "endpoint_masked": "http://[MASKED-HOST]:11434",
            "auth": "none"
          }
        }
      }
    }
  }
}
```

---

## 5. Tabla de Códigos de Salida

| Código | Significado | Comportamiento |
| :---: | :--- | :--- |
| `0` | **HEALTHY / OK** | Entorno operativo saludable. En modo agnóstico (`SKIPPED-NO-FLEET`), siempre retorna `0`. En modo estándar sin `--strict`, siempre reporta el diagnóstico sin romper pipelines. |
| `1` | **DEGRADED / STRICT FAIL** | Retornado **únicamente** cuando se especifica `--strict` y se detecta al menos un servicio caído (`DOWN`) o menos de 3 CLIs locales operativos. También retornado ante parámetros inválidos o errores fatales de parseo de archivos. |

---

## 6. Integración en `tests/validate-control-plane.sh` (Check 12)

`fleet-doctor.sh` está integrado como el **Check 12** dentro de la suite de validación del control plane:

```bash
🔍 [12/12] Verificando diagnóstico determinista de flota (fleet-doctor.sh)...
  ✅ fleet-doctor.sh valida sintaxis y procesa .agents/config/fleet.example.yaml deterministamente.
  ℹ️  [SKIP CONDICIONAL] .agents/config/fleet.yaml no existe en este entorno: conectividad viva omitida de forma segura.
```

- **Si `.agents/config/fleet.yaml` existe**: Ejecuta el chequeo completo de flota y reporta estado en vivo (12/12 checks).
- **Si `.agents/config/fleet.yaml` no existe**: Valida la sintaxis del parser y las opciones agnósticas contra `.agents/config/fleet.example.yaml`, emite un `[SKIP CONDICIONAL]` informativo y concluye la suite con 11/12 aprobados + 1 SKIP (código de salida `0`).

---

*Última actualización: 28 Sep 2026*
