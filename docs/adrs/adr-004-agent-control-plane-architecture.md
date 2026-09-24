# ADR 004: Arquitectura del Control Plane de Agentes 24/7 y Federación de Repositorios

**Estado:** Accepted  
**Fecha:** 2026-09-24  
**Contexto:** Sprint 05 — Core / Control Plane Foundation  

---

## 1. Contexto y Problema

El ecosistema de desarrollo y operaciones ha crecido incorporando múltiples nodos (host local, VPS `datamanager`, VPS `oracle`), múltiples agentes con distintos ciclos de vida (Antigravity CLI, Hermes Agent 24/7, Orca Desktop/Remote, OpenCode) y una pasarela de inferencia unificada (FreeLLMAPI + Ollama local).

Sin un marco arquitectónico estandarizado, existían riesgos de:
- Acoplamiento caótico entre especificaciones de agentes y configuraciones de servidores específicos.
- Modificaciones no autorizadas en entornos de producción con alto riesgo (como `oracle` con un 72% de disco ocupado).
- Ruptura de la integración probada donde Hermes en `datamanager` consume skills de `agent-os` mediante enlaces simbólicos.
- Dependencia frágil de proveedores cloud comerciales o de una sola ruta de inferencia.

---

## 2. Decisiones Arquitectónicas Fundamentales

### 2.1 Por qué `agent-os` es el repositorio núcleo
`agent-os` actúa como la **única fuente de verdad declarativa** para el ecosistema global:
- Alberga los perfiles abstractos de agentes (`.agents/profiles/`), las reglas globales (`.agents/rules/`), los workflows de ciclo de vida (`.agents/workflows/`), las skills universales (`.agents/skills/`) y las políticas de permisos y routing.
- Es completamente **agnóstico de la infraestructura concreta**: no contiene IPs fijas, credenciales, sesiones de mensajería ni unidades de systemd locales.
- Se distribuye a proyectos hijos y hosts mediante `scripts/agent/sync.sh`.

### 2.2 Por qué `hermes-vps-config` permanece separado
`hermes-vps-config` es un **repositorio de configuración de host e infraestructura**:
- Versiona la parte no sensible de los servicios que corren en los VPS: unidades systemd (`hermes-gateway.service`, `rag-service.service`), configuración no sensible de Hermes (`config.yaml`), parches de los bridges de WhatsApp y runbooks operativos del servidor.
- Mantenerlo separado previene contaminar el core de `agent-os` con scripts acoplados a rutas absolutas del VPS (`/home/ubuntu/.hermes`) o particularidades del daemon.

### 2.3 Por qué Hermes es el "Front Door" 24/7
Hermes Agent se mantiene como el cerebro conversacional y puerta de enlace continua:
- Ya corre de forma estable y probada como daemon systemd en `datamanager`, integrado con WhatsApp y RAG vectorial local en Qdrant.
- Proporciona atención inmediata a mensajes humanos, triage de alertas y memoria operativa persistente sin consumir recursos interactivos de la estación de trabajo local.
- No sustituye al desarrollador humano ni a Antigravity: actúa como coordinador inicial que delega el trabajo técnico pesado.

### 2.4 Por qué Orca es el "Execution Plane"
Orca se designa como el entorno de ejecución técnica supervisada:
- Cuenta con una base de datos relacional nativa (`orchestration.db`) estructurada para gestionar `runs`, `tasks`, `worker_dispatches` y `decision_gates`.
- Opera mediante Git worktrees aislados, evitando que los agentes ensucien las ramas principales (`main`/`master`).
- Los relés remotos ya activos en `datamanager` y `oracle` permiten orquestar tareas en los servidores bajo canales seguros sin requerir shells interactivas descontroladas.

### 2.5 Por qué FreeLLMAPI es fallback y ruta por clase de tarea, no dependencia única
FreeLLMAPI ofrece ventajas económicas y resiliencia pero no puede ser la única vía:
- Su rendimiento depende de proveedores gratuitos externos cuyos límites de tasa (RPM/RPD) y disponibilidad varían en el tiempo.
- Se utiliza como ruta primaria para operaciones de lectura, resúmenes, marketing y triage (con fallback automático a Ollama local).
- Las tareas críticas de arquitectura, seguridad y refactor masivo siguen reservadas a modelos de alta fiabilidad (`primary-reliable`) con supervisión humana.

### 2.6 Por qué `oracle` no debe recibir workers masivos (Restricción de Disco al 72%)
El VPS `oracle` (`vnic-rsr`) alberga la infraestructura de producción web (Coolify 4, Traefik, bases de datos PostgreSQL, Redis y ~25 contenedores de clientes y bots):
- El disco `/dev/sda1` se encuentra al **72% de uso (139 GiB ocupados de 193 GiB)**.
- Desplegar workers masivos de Orca, builds descontroladas de Docker o múltiples worktrees en `oracle` saturaría el almacenamiento restante, provocando caídas críticas en las bases de datos de producción.
- **Regla estricta:** `oracle` solo actúa como target supervisado para despliegues aprobados y tareas operativas acotadas de lectura.

---

## 3. Consecuencias y Mitigaciones

### Positivas
- **Aislamiento de responsabilidades**: Cada agente y herramienta opera en su dominio óptimo sin colisiones.
- **Seguridad multicapa**: Todo cambio destructivo en infraestructura o producción queda sujeto a Decision Gates humanos.
- **Preservación de integraciones**: Los enlaces simbólicos de Hermes en `datamanager` (`/home/ubuntu/.hermes/skills/agent-os`) continúan intactos.
- **Resiliencia operativa**: La combinación de FreeLLMAPI y Ollama local asegura que el sistema siga operando incluso ante caídas de proveedores cloud.

### Negativas / Sobrecarga
- Requiere mantener sincronizados los perfiles declarativos en `agent-os` y las configuraciones de host en `hermes-vps-config`.
- La necesidad de Decision Gates en acciones L3 introduce latencia humana en operaciones de infraestructura.

---

## 4. Referencias
- [docs/architecture/control-plane-topology.md](file:///home/romen/Proyectos/agent-os/docs/architecture/control-plane-topology.md)
- [config/agent-registry.yaml](file:///home/romen/Proyectos/agent-os/config/agent-registry.yaml)
- [config/routing-policy.yaml](file:///home/romen/Proyectos/agent-os/config/routing-policy.yaml)
- [.agents/rules/global/agent-permissions.md](file:///home/romen/Proyectos/agent-os/.agents/rules/global/agent-permissions.md)
