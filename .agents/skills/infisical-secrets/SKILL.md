---
name: infisical-secrets
description: Inyección efímera de secretos en memoria y gestión centralizada con Infisical Community Edition y Universal Auth en la flota de Agent OS.
---

# 🔐 Infisical Secrets Management (Inyección Efímera de Secretos)

Esta habilidad proporciona el protocolo operativo, runbooks y comandos necesarios para inyectar variables de entorno y secretos confidenciales directamente en la memoria de los procesos (`infisical run`), eliminando por completo la necesidad de almacenar archivos `.env` en disco o exponer tokens en repositorios.

Infisical opera como el gestor centralizado de secretos de la flota de **Agent OS**, alojado en el nodo de infraestructura `oracle` tras Coolify.

---

## 🌐 Topología del Servicio y Conectividad

- **Nodo**: `oracle` (Ubuntu 24.04 / Coolify PaaS)
- **URL Base / Backend**: `http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io`
- **Consola Web Administrativa**: `http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/admin`
- **API Endpoint**: `http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/api`
- **Contenedores**: `infisical:v0.154.6`, `postgres:14-alpine`, `redis:7` (modo lite <500MB RAM)

---

## 🔑 Autenticación: Machine Identity (Universal Auth)

Para la interacción automatizada de agentes de IA, CLI local y scripts desatendidos (CI/CD o cron jobs), Infisical emplea **Universal Auth** (Machine Identities), evitando el login interactivo de usuario humano.

### 1. Creación de la Identidad en la Consola Web

1. Acceder a la consola administrativa: `http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/admin`.
2. Crear o seleccionar la Organización y el Proyecto: **`Agent OS`**.
3. Navegar a **Access Control** → **Machine Identities** → **Add Machine Identity**.
4. Nombre de la identidad: `agent-os-flota` (o `runner-local`).
5. Configurar el método de autenticación: **Universal Auth**.
6. En la pestaña del Proyecto `Agent OS`, asociar la Machine Identity con el rol adecuado (`Developer` para lectura de secretos de desarrollo/staging o `Admin` para gestión integral).
7. Generar las credenciales:
   - **Client ID**: Identificador público de la máquina.
   - **Client Secret**: Secreto de un solo visionado.
8. Obtener el **Project ID** desde la URL o la configuración del proyecto:
- **Project Name**: `Agent OS`
- **Project ID**: `87e37a5c-e1a7-4285-be4e-c9913527533a`
- **Project Slug**: `agent-os-kz-vq`

### 2. Autenticación Universal Auth con el CLI

Para ejecuciones desatendidas de agentes o runners, se canjean las credenciales de la Machine Identity (`INFISICAL_CLIENT_ID` e `INFISICAL_CLIENT_SECRET`) por un token efímero de acceso (válido por 30 días / 2,592,000s):

```bash
# 1. Variables de Machine Identity en el host o runner
export INFISICAL_API_URL="http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/api"
export INFISICAL_CLIENT_ID="<tu-client-id>"
export INFISICAL_CLIENT_SECRET="<tu-client-secret>"

# 2. Canje del token Universal Auth en memoria (sin interacción humana)
export INFISICAL_TOKEN=$(infisical login \
  --domain="http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/api" \
  --method=universal-auth \
  --client-id="$INFISICAL_CLIENT_ID" \
  --client-secret="$INFISICAL_CLIENT_SECRET" \
  --plain)
```

---

## ⚡ Comandos de Operación y Runbooks

El CLI de Infisical está disponible en el entorno local (bien como binario nativo, npm global o vía `npx -y @infisical/cli`).

### 1. Inyección de Secretos en Memoria (`infisical run`)

Este es el comando primordial para agentes. Ejecuta el proceso hijo inyectando los secretos descifrados en su memoria (`process.env`) sin escribir ningún archivo en el disco:

```bash
# Inyección usando INFISICAL_TOKEN y apuntando al proyecto Agent OS
infisical run \
  --domain="http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/api" \
  --env=prod \
  --projectId="87e37a5c-e1a7-4285-be4e-c9913527533a" \
  -- <comando_a_ejecutar>

# Ejemplo con OpenCode o tests
infisical run --env=dev --projectId="87e37a5c-e1a7-4285-be4e-c9913527533a" -- npm test
```

### 2. Inicialización en un Proyecto Hijo (`infisical init`)

En un proyecto hijo gestionado por Agent OS:

```bash
# Conectar el directorio local con el proyecto en Infisical
infisical init \
  --domain="http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/api"
```
Esto genera un archivo `.infisical.json` que contiene únicamente el `projectId` y la configuración de workspace (sin ningún secreto ni token sensible).

### 3. Consulta de Secretos sin Exposición

```bash
# Listar claves de secretos disponibles (sin mostrar valores)
infisical secrets \
  --domain="http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/api" \
  --env=prod
```

### 4. Volcado Efímero por Pipe (Nunca a archivo rastreado)

Si un script legacy o docker-compose requiere variables en formato dotenv, se realiza por pipe o proceso temporal, **NUNCA** redireccionando a un archivo `.env` persistido en git:

```bash
# Lectura en memoria para un subshell
eval $(infisical export --env=prod --format=dotenv-export --domain="http://backend-vcg80040ogcgsskkw08k48w4.158.179.213.240.sslip.io/api")
```

---

## 🛡️ Reglas de Seguridad y Buenas Prácticas

1. **Principio de Secreto Cero en Git**:
   - Queda terminantemente prohibido generar archivos `.env`, `.env.production` o similares dentro del árbol de trabajo que puedan ser accidentalmente añadidos a git.
   - La suite `tests/validate-control-plane.sh` audita activamente que ningún archivo `.env` esté rastreado.
2. **Aislamiento por Entornos**:
   - `dev`: Claves para tests y desarrollo local.
   - `staging`: Claves para tests de integración en `datamanager` u `oracle`.
   - `prod`: Claves de producción de servicios desplegados en Coolify.
3. **Rotación Rápida**:
   - En caso de sospecha de compromiso de un token (ej. GitHub PAT o API key de LLM), la rotación se ejecuta en la consola de Infisical; todos los agentes y servicios consumen el nuevo valor en la siguiente ejecución sin necesidad de re-desplegar ni tocar código fuente.
