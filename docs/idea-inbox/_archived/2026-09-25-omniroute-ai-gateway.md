# Idea: Despliegue de OmniRoute como Pasarela de Inferencia Multi-Proveedor y Compresión de Tokens

> **Fecha**: 2026-09-25  
> **Estado**: 💡 Capturada en Idea Inbox (Candidata Sprint 08)  
> **Área**: Inferencia $0 / Optimización de Tokens / Infraestructura  
> **Origen**: Prospección técnica pre-código (T-046) y análisis de credenciales (`Agencia_IA/.env:21:OMNIROUTER_API_KEY`)  

---

## 1. Contexto y Oportunidad

En el stack actual disponemos de FreeLLMAPI en el VPS `datamanager` (`http://100.77.82.13:3001/v1`) y modelos locales en Ollama. No obstante, ante picos de demanda o límites de ratio por minuto (RPM) en modelos específicos, el sistema requiere redundancia multi-proveedor sin coste.

Además, el mayor coste en sesiones de desarrollo con agentes radica en el volumen de tokens de contexto (prompts repetitivos, diffs extensos y lectura de archivos).

**OmniRoute** (creado por Diego Souza, MIT) resuelve ambos problemas simultáneamente.

---

## 2. Referencias Técnicas Exhaustivas (Sin necesidad de búsquedas adicionales)

- **Repositorio Oficial**: [diegosouzapw/OmniRoute](https://github.com/diegosouzapw/OmniRoute)
- **Licencia**: MIT (Permisiva)
- **Popularidad**: ⭐ 70.000+ GitHub Stars
- **Paquete NPM Core**: `omniroute` (v3.8.50) — `npm i -g omniroute` o imagen Docker oficial
- **Plugin de Autenticación OpenCode**: `opencode-omniroute-auth` (v1.2.2 en npm)
  - Repositorio del plugin: [Alph4d0g/opencode-omniroute-auth](https://github.com/Alph4d0g/opencode-omniroute-auth)
  - Comando de conexión: `/connect` directo desde OpenCode para autenticar y autodescubrir modelos.
- **Tecnología de Compresión de Tokens**:
  - Compresión semántica RTK + Caveman integrada (reduce entre un 50% y un 70% los tokens de entrada en prompts).
  - Repositorio complementario: [diegosouzapw/OmniGlyph](https://github.com/diegosouzapw/OmniGlyph)
- **Credencial existente en el entorno**:
  - `OMNIROUTER_API_KEY` (presente en `/home/romen/Proyectos/Agencia_IA/.env:21`).

---

## 3. Propuesta de Arquitectura y Despliegue (Sprint 08)

### Opción Recomendada: Servicio Docker en `datamanager`
1. **Topología**:
   - Desplegar contenedor Docker de OmniRoute en el nodo VPS `datamanager` expuesto en el puerto `3002`.
   - Conectado a la red privada de Tailscale (`http://100.77.82.13:3002/v1`).
2. **Integración con Agentes**:
   - **Antigravity (`agy` / `agy2`)**: Endpoint OpenAI-compatible adicional en `config/routing-policy.yaml`.
   - **OpenCode**: Instalación del plugin `opencode-omniroute-auth` para failover automático cuando la cuota de FreeLLMAPI se agote.
   - **Hermes Agent**: Conexión como upstream secundario para tareas no críticas de lectura y resumen.
3. **Configuración en `config/fleet.yaml`**:
   ```yaml
   nodes:
     datamanager:
       services:
         omniroute:
           endpoint: "http://100.77.82.13:3002/v1"
           description: "OmniRoute AI gateway with 150+ free providers and RTK compression"
           cost_per_token: 0.00
   ```

---

## 4. Criterios de Éxito
- OmniRoute levantado en contenedor Docker en `datamanager` accesible vía Tailscale.
- Endpoint `/v1/chat/completions` validado respondiendo con $0 de coste a peticiones OpenAI estándar.
- OpenCode consumiendo OmniRoute como segundo fallback tras FreeLLMAPI.
- Reducción medible del consumo de tokens en tareas pesadas de contexto.
