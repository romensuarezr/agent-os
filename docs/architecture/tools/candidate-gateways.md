# 🧭 Prospección Tecnológica: Pasarelas de Inferencia y Routers LLM Candidatos

> **Documento de Prospección Técnica (Determinista — Coste 0 Tokens)**  
> **Fecha de prospección**: 2026-09-25  
> **Herramienta de prospección**: `scripts/agent/scout.sh` (GitHub API + NPM Registry + HN Algolia)  
> **Criterios de elegibilidad**: Licencia permisiva (MIT/Apache), compatibilidad con OpenAI API, soporte de fallback automático, optimización de tokens y capacidad self-hosted.

---

## 1. Contexto y Diagnóstico: El Caso OmniRouter / FreeLLMAPI

### ¿Por qué no aparecían inicialmente en el digest de la flota?

1. **FreeLLMAPI**:
   - **Estado real**: Está completamente instalado y operativo en el nodo remoto `datamanager` (`http://100.77.82.13:3001/v1`).
   - **Causa del desajuste inicial**: La primera versión de `discover-fleet.sh` únicamente auditaba el entorno local (Capa 1: binarios en PATH, marcadores de navegador y peers de Tailscale). No leía la sección `nodes` de `config/fleet.yaml`.
   - **Solución implementada**: `discover-fleet.sh` ahora lee bidireccionalmente `config/fleet.yaml`, unificando en el reporte (`local-environment.local.md`) tanto las herramientas locales como los gateways de inferencia remotos configurados.

2. **OmniRouter / OmniRoute**:
   - **Estado real**: Se confirmó la existencia de la credencial `OMNIROUTER_API_KEY` en `/home/romen/Proyectos/Agencia_IA/.env:21`.
   - **Causa del desajuste inicial**: Fue evaluado vía API / SaaS web. No existe una instalación local de CLI (ej. `npm install -g omniroute`), ni un contenedor Docker en el host o en los VPS `datamanager`/`oracle`, ni un marcador de navegador indexado bajo ese dominio.
   - **Solución implementada**: Se añadieron las firmas de dominio a `config/known-web-tools.yaml` y se realizó la presente prospección tecnológica determinista para evaluar su adopción formal en el stack de Agent OS.

---

## 2. Matriz Comparativa de Routers y Pasarelas Candidatas

| Proyecto | Licencia | GitHub / Ecosistema | Ventajas Clave | Desventajas / Consideraciones | Encaje Agent OS |
| :--- | :---: | :---: | :--- | :--- | :---: |
| **OmniRoute**  <br>*(Diego Souza)* | **MIT** | ⭐ **70.000+** <br>📦 `omniroute` (npm) | • **150+ proveedores gratuitos** de 350+ soportados.<br>• Compresión de contexto RTK + Caveman (reduce tokens en 50-70%).<br>• Fallback automático ante rate-limits o errores.<br>• Plugin nativo para OpenCode (`opencode-omniroute-auth`). | Proyecto muy activo con releases frecuentes; requiere fijar versiones estables en producción. | 🟢 **10 / 10** <br>*(Máxima afinidad)* |
| **Portkey AI Gateway** | **MIT** | ⭐ **13.000+** <br>Docker / Edge | • Pasarela ultra-rápida (diseñada para baja latencia).<br>• Más de 1.600 LLMs soportados.<br>• 50+ guardrails integrados, balanceo de carga y reintentos automáticos. | Orientado a infraestructura cloud/edge con mayor complejidad de configuración. | 🟡 **8 / 10** <br>*(Ideal para producción)* |
| **LiteLLM Proxy** <br>*(BerriAI)* | **MIT** | ⭐ **15.000+** <br>📦 `litellm` (PyPI) | • Estándar de facto en el ecosistema Python.<br>• Proxy OpenAI unificado para más de 100 proveedores.<br>• Control de presupuestos y cuotas por usuario/agente. | Mayor consumo de memoria que implementaciones en Go o Node; recientes avisos de seguridad que exigen parcheo continuo. | 🟡 **8 / 10** <br>*(Maduro pero más pesado)* |
| **Plano** <br>*(Katanemo)* | **Apache-2.0** | ⭐ **7.000+** <br>Binario / Proxy | • Plano de datos y proxy nativo para aplicaciones agénticas.<br>• Enrutamiento inteligente de LLMs y observabilidad.<br>• Diseñado para flujos multi-agente complejos. | Ecosistema más reciente y menor cantidad de adaptadores listos para usar de inmediato. | 🔵 **7 / 10** <br>*(Prometedor para multi-agente)* |

---

## 3. Análisis en Profundidad: OmniRoute (Candidato Recomendado)

### ¿Qué aporta a la arquitectura de Agent OS?

1. **Alineación con el Mandato de Coste Cero ($0 Inference)**:
   - Agrega más de 150 proveedores y modelos gratuitos bajo una única API compatible con OpenAI.
   - Si un proveedor gratuito satura su cuota horaria o límite por minuto (RPM), conmuta transparentemente al siguiente proveedor disponible sin interrumpir la sesión del agente.

2. **Ahorro Radical de Tokens de Contexto (RTK + Caveman Compression)**:
   - Incorpora algoritmos de compresión semántica y eliminación de redundancias sintácticas en los prompts antes del envío.
   - Reduce entre un **50% y un 70%** el consumo de tokens en tareas repetitivas de lectura de contexto y diffs de código.

3. **Interoperabilidad con OpenCode y Antigravity**:
   - Dispone de plugin publicado en npm: `opencode-omniroute-auth`. Permite que OpenCode (nuestro runtime de fallback) consuma directamente el router con auto-descubrimiento dinámico de modelos.
   - Antigravity y Hermes pueden consumirlo simplemente apuntando su endpoint base (`base_url: http://.../v1`).

---

## 4. Opciones de Despliegue para Futuros Sprints

Si se decide incorporar OmniRoute al stack operativo:

1. **Opción A (Recomendada): Servicio Docker en `datamanager`**:
   - Desplegarlo junto a `freellmapi` y `ollama` en la red privada de Tailscale (`100.77.82.13:3002`).
   - Todos los agentes de la flota (locales o remotos) acceden sin exponer puertos públicos a internet.

2. **Opción B: Demonio Ligero Local en Workstation**:
   - Ejecutable vía CLI/Node (`npx omniroute` o systemd user service en `localhost:3002`).
   - Máxima velocidad para desarrollo desconectado.

---

## 5. Resumen de Decisiones

- [x] Documentar el diagnóstico técnico de `freellmapi` y `omnirouter`.
- [x] Añadir dominios y firmas de routers a `config/known-web-tools.yaml`.
- [x] Unificar la visibilidad de pasarelas remotas y locales en `discover-fleet.sh`.
- [ ] *(Opcional para próximo sprint)*: Evaluar despliegue de contenedor de OmniRoute en `datamanager` como backend secundario de inferencia gratuita.
