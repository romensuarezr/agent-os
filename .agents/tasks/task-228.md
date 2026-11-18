# T-228 — Declaración Integral del Stack Auditado en `fleet.yaml`
Sprint: Sprint 43 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-228-fleet-stack-declaration | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 43 — 2026-11-18
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Incorporar a `.agents/config/fleet.yaml` y `.agents/config/fleet.example.yaml` todo el inventario de servicios y aplicaciones en producción verificado en la base de datos de Coolify (`coolify-db`) y Traefik.
  - Endpoints reales:
    - Coolify: `https://coolify.romensuarez.com`
    - Homepage: `http://g8o4sgwsw8k4c0cscoskkks8.<nodo-orquestacion-ip>.sslip.io/`
    - SearXNG: `http://searxng-lswo0woww0sswwsk0wkcc4o0.<nodo-orquestacion-ip>.sslip.io`
    - n8n: `https://n8n.romensuarez.com`
    - Umami: `https://umami.romensuarez.com`
    - Ghost: `https://blog.romensuarez.com`
    - WhatsApp Bridge: `https://whatsapp.romensuarez.com`
    - ByteBox: `https://bytebox.romensuarez.com`
    - Twenty CRM: `http://j44wc80o8oc04w08880sgw00.<nodo-orquestacion-ip>.sslip.io`
    - Calibre Web: `http://calibre-fggk84oowsw888cw4sgcc8k4.<nodo-orquestacion-ip>.sslip.io:8083`
    - Satélites: Outbid (`https://outbid.romensuarez.com`), Kanarii (`http://lwwcgo8kggokcwcgc0kkk0kc.<nodo-orquestacion-ip>.sslip.io`), Finca Adama (`https://fincaadama.com`), HD-API (`https://hd-api.romensuarez.com`).
    - Nango OAuth: `http://<TAILSCALE_IP_ORACLE>:3009` (Connect UI) / `http://<TAILSCALE_IP_ORACLE>:3003` (API).
    - DataManager services: declarar `glances: 61208` bajo `nodes.<nodo-inferencia>.services`.
  - Cero secretos commiteados; estructura declarativa YAML estricta y portable.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Alinear el modelo declarativo de la flota (`fleet.yaml`) con la realidad física y operativa del VPS de orquestación y el VPS de inferencia, sustituyendo placeholders genéricos por las URLs y servicios reales verificados.

## 2. Contexto técnico
- Archivos del repositorio: `.agents/config/fleet.yaml`, `.agents/config/fleet.example.yaml`.
- Validación determinista: `tests/validate-control-plane.sh` y `scripts/agent/fleet-doctor.sh`.

## 3. Caja de archivos
- `.agents/config/fleet.yaml`
- `.agents/config/fleet.example.yaml`
- `.agents/tasks/task-228.md`
- `docs/sprints/sprint-43.md`

## 4. Plan de implementación
1. Actualizar `.agents/config/fleet.yaml` con las URLs y metadatos verificados para cada servicio de Oracle y DataManager.
2. Añadir la declaración de `glances` en DataManager (`port: 61208`, `bind: <TAILSCALE_IP_DATAMANAGER>`).
3. Reflejar la misma estructura esquemática en `.agents/config/fleet.example.yaml` con marcadores genéricos.
4. Validar sintaxis con `python3 -c "import yaml; yaml.safe_load(open('.agents/config/fleet.yaml'))"`.
5. Ejecutar `scripts/agent/fleet-doctor.sh` para comprobar la detección del nuevo catálogo.

## 5. Criterios de aceptación
- `fleet.yaml` contiene todas las URLs reales verificadas del stack.
- `fleet.example.yaml` mantiene paridad estructural sin fugas de dominios privados.
- `fleet-doctor.sh` procesa el archivo sin errores.
