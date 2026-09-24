# Idea: Gestión Segura de Secretos con Infisical y Skill Dedicada

**Fecha**: 2026-09-24  
**Estado**: 💡 Capturada en Idea Inbox  
**Área**: Seguridad / Infraestructura / DX  

---

## 1. Contexto y Problema Actual
Actualmente, las credenciales, tokens y API keys de desarrollo e infraestructura se encuentran almacenados de forma manual y fragmentada (por ejemplo, notas en Notion en texto plano). Esta práctica presenta riesgos significativos:
- **Ausencia de cifrado Zero-Knowledge**: Las claves quedan expuestas en un servicio SaaS de terceros sin aislamiento criptográfico cliente.
- **Riesgo de fuga en repositorios**: Obliga a copiar y pegar credenciales a mano en archivos `.env` locales, aumentando la probabilidad de commits accidentales de secretos.
- **Falta de inyección dinámica**: Los agentes de IA (Antigravity, Hermes, OpenCode, Orca) y los scripts de despliegue no disponen de una forma estándar de solicitar o inyectar secretos en tiempo de ejecución.

---

## 2. Propuesta de Solución: Infisical en Coolify (`oracle`)

### Propuesta 1: Despliegue autoalojado de Infisical en Coolify (`oracle`)
- Desplegar la Community Edition de Infisical en el VPS `oracle` mediante Coolify (PostgreSQL + Redis + Infisical Backend/Frontend).
- Oportunidad de automatización: Aprovechar el **MCP de Coolify instalado en Hermes Agent** en `datamanager` para que Hermes aprovisione el servicio de forma declarativa.

### Propuesta 2: Skill dedicada en agent-os (`infisical-secrets`)
- Instrucciones y comandos para que cualquier agente sepa interactuar con la bóveda.
- Uso de `infisical run -- <comando>` o exportación temporal efímera en memoria para evitar escribir secretos en disco o `.env`.
- Políticas de permisos L3 para rotación o creación de nuevas claves.

---

## 3. Plan de Acción Propuesto

1. **Fase de Despliegue (Infraestructura)**:
   - Crear el stack de Infisical en Coolify en `oracle` (vía web de Coolify o delegando la instrucción a Hermes Agent mediante su Coolify MCP).
   - Proteger el acceso al dashboard a través de dominio con HTTPS (Traefik) o binding restringido a Tailscale (`100.96.20.7`).
2. **Fase de Integración en el Core**:
   - Crear la skill `.agents/skills/infisical-secrets/SKILL.md` con los comandos CLI para login, exportación e inyección de entorno.
   - Configurar el cliente CLI de Infisical en el entorno de desarrollo local.
3. **Fase de Migración**:
   - Migrar de forma progresiva las API keys de Notion a Infisical, eliminando el texto plano.

---

## 4. Criterio de Éxito
- Cero API keys almacenadas en texto plano en Notion o archivos `.env` sin cifrar.
- Los agentes pueden ejecutar tareas con variables de entorno inyectadas en memoria mediante `infisical run`.
