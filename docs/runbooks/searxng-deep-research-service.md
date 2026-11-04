# Runbook Operativo: Servicio de Meta-Búsqueda Soberano (SearXNG)

> **Servicio**: SearXNG Meta-Search Engine  
> **Puerto Canónico**: `8080` (HTTP)  
> **Rol en la Flota**: Motor de búsqueda abierta y privacidad estricta ($0 tokens) para flujos de `deep-research`.  
> **Cliente Determinista**: `scripts/agent/lib/searxng-client.sh`  

---

## 1. Visión General

SearXNG actúa como el motor soberano de búsqueda web para los agentes de la flota de Agent OS. Proporciona:
- Agregación anónima de resultados de múltiples motores (Google, Brave, DuckDuckGo, Bing, etc.) sin rastreo.
- API REST nativa que devuelve resultados estructurados en JSON (`/search?q=...&format=json`).
- Cero costes recurrentes por token de búsqueda ($0) frente a proveedores SaaS comerciales.
- Resiliencia y privacidad: los agentes no interactúan directamente con buscadores comerciales ni exponen cookies de usuario.

---

## 2. Arquitectura de Despliegue

El servicio opera como una composición desacoplada de dos contenedores:

```text
[ Agente / Workflow ]
         │ (HTTP GET /search?q=...&format=json)
         ▼
┌───────────────────────────────┐
│     searxng/searxng:latest    │ (Puerto 8080)
└──────────────┬────────────────┘
               │ (Cache & Rate Limiting)
               ▼
┌───────────────────────────────┐
│         redis:7-alpine        │ (Puerto 6379 interno)
└───────────────────────────────┘
```

### 2.1 Requisitos de Recursos
- **SearXNG**: 1.0 CPU, 512 MB RAM (límite), 128 MB RAM (reserva).
- **Redis**: 0.5 CPU, 256 MB RAM (límite), 64 MB RAM (reserva).

---

## 3. Puesta en Marcha en la Flota

### Opción A: Despliegue en Coolify (PaaS de la Flota)
1. Acceder al proyecto correspondiente en la consola Coolify en `<nodo-orquestacion>`.
2. Crear un nuevo servicio de tipo **SearXNG** (o Compose Service).
3. Asegurar que las variables de entorno contengan:
   - `SEARXNG_BIND_ADDRESS=0.0.0.0`
   - `SEARXNG_REDIS_URL=redis://redis:6379/0`
   - `SEARXNG_SECRET=<clave_aleatoria>`
4. Verificar que el volumen `./settings.yml` tenga habilitado el formato `json`:
   ```yaml
   search:
     formats:
       - html
       - json
   ```
5. Iniciar el servicio y comprobar que el health check en `/healthz` responde con código 200.

### Opción B: Despliegue Soberano Docker Compose
En cualquier nodo de cómputo con Docker instalado:
```bash
cd templates/searxng
cp .env.example .env
# Generar clave secreta
sed -i "s/change_me_to_a_random_secret_string/$(openssl rand -hex 32)/g" .env
docker compose up -d
```

---

## 4. Uso Determinista desde Scripts y Workflows

### 4.1 Comprobación de Disponibilidad (Sonda de Salud)
```bash
bash scripts/agent/lib/searxng-client.sh --check
```
- **Retorno 0**: Servicio activo y respondiendo satisfactoriamente.
- **Retorno 2**: Servicio inactivo o inalcanzable (fail-soft, sin interrumpir abruptamente el pipeline).

### 4.2 Consulta Directa con Formateo Markdown
```bash
bash scripts/agent/lib/searxng-client.sh --query "Model Context Protocol specifications"
```
Emite los 10 mejores resultados en formato Markdown estructurado con títulos, enlaces clicables y extractos textuales.

### 4.3 Consulta con Salida Estructurada JSON
```bash
bash scripts/agent/lib/searxng-client.sh --query "FastAPI async SQLAlchemy" --json
```

---

## 5. Integración con el Workflow de Deep Research

En el workflow canónico `@[.agents/workflows/deep-research.md]`, la Fase 2A invoca deterministamente `searxng-client.sh`:
1. El agente formula la consulta técnica destilada del problema.
2. Invoca `bash scripts/agent/lib/searxng-client.sh --query "$QUERY" --output "$TEMP_RESEARCH_MD"`.
3. Sintetiza los hallazgos en la sección de contexto técnico del task file.

---

## 6. Mantenimiento y Troubleshooting

| Síntoma | Causa Probable | Remedio |
| :--- | :--- | :--- |
| `HTTP 403 Forbidden` en consultas JSON | `format: json` deshabilitado en `settings.yml` | Añadir `- json` bajo `search.formats` y reiniciar contenedor. |
| `HTTP 500` / Fallo de conexión | Redis caído o inalcanzable | Verificar `docker ps --filter 'name=redis'` y logs de SearXNG. |
| `Exit code 2` en `--check` | Endpoint no configurado en `fleet.yaml` ni en `SEARXNG_API_URL` | Registrar el endpoint en el overlay privado `fleet.yaml` o exportar `SEARXNG_API_URL`. |
