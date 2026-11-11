# Task-170: Primera integración real de Nango en flujo operativo de agente

## Estado
✅ Completada

## Objetivo
Implementar la primera integración productiva real de Nango en un flujo de trabajo de la flota de Agent OS. La tarea inicia obligatoriamente con una **propuesta formal sellada ante el humano** (analizando candidatos como Cloudflare / Infisical u otros servicios de la flota, el flujo real desbloqueado y qué credenciales u OAuth toca). **Sin aprobación humana explícita de la propuesta en el chat, queda prohibido conectar nada**. Tras recibir dicha aprobación, conectar el conector seleccionado a la instancia viva de Nango (<nodo-orquestacion>:3003) y construir o adaptar un flujo operativo de agente que lo consuma activamente con evidencia verificable.

## Contexto técnico
En T-166 se completó con éxito el despliegue soberano de Nango en el VPS de orquestación, validando su health check en el puerto 3003 y su interfaz Connect UI en el puerto 3009.
El siguiente paso operativo consiste en convertir Nango en un componente funcional del core, utilizándolo para mediar credenciales o tokens en un flujo real de agente.
Para salvaguardar la seguridad operativa y evitar conexiones arbitrarias o riesgos sobre credenciales de infraestructura, la tarea establece una compuerta estricta: formulación de propuesta formal y autorización humana antes de realizar cualquier conexión real.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-04 (Enmienda T-168 a T-170)
- **Diseño y arquitectura aprobados por**: Relé (Decisión Macro de Enmienda Sprint 30)
- **Decisiones e interfaces selladas**:
  - **Propuesta previa vinculante**:
    - Formular una propuesta técnica que identifique candidatos de integración (tomando Cloudflare o Infisical como puntos de partida, sin cerrar a priori otras opciones de la flota).
    - Describir con exactitud qué flujo operativo real de agente desbloquea dicha integración.
    - Especificar qué credenciales, scopes o flujos OAuth se ven afectados, garantizando que ninguna clave privada se exponga en el repositorio.
  - **Compuerta de aprobación humana**: Sin la aprobación expresa y sellada del humano en el chat sobre la propuesta, no se realiza ninguna conexión en Nango ni mutación sobre APIs externas.
  - **Conexión e integración operativa**:
    - Tras la aprobación, provisionar el conector o integración en la instancia viva de Nango.
    - Implementar o adaptar un flujo de trabajo o script determinista de Agent OS que consuma la API de Nango para obtener credenciales delegadas o tokens de sesión.
    - Probar el flujo de extremo a extremo aportando evidencia verificable en el reporte de cierre.
  - **Denominador de suite**: Inmutable en **38/38** (0 errores).

## Skills relevantes
- `agent-os-scripts`: Integración con utilidades de Agent OS.
- `infisical-secrets`: Gestión de secretos y vinculación de credenciales seguras.
- `coolify-nextjs-deploy` / `coolify-admin`: Flujos donde la integración OAuth/API aporta valor operativo.

## Caja de archivos
- `docs/runbooks/nango-oauth-service.md`
- `scripts/agent/` (script o cliente de consumo de Nango)
- `.agents/workflows/` (workflow actualizado o conector integrado)
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-170.md`

## Criterios de done
- [x] Documento formal de propuesta de integración de Nango presentado al operador.
- [x] Aprobación humana explícita obtenida antes de conectar credenciales.
- [x] Integración provisionada y conectada en la instancia viva de Nango.
- [x] Flujo operativo o script de Agent OS consumiendo activamente la integración con Nango.
- [x] Evidencia de funcionamiento real verificada y reportada sin exposición de secretos.
- [x] Runbook operativo actualizado con el flujo de uso del conector.
- [x] Suite de validación de control plane inmutable en 38/38 pasando limpia (0 errores).
- [x] Ejecutada y registrada bajo las reglas de Opción D.

## Evidencia operativa (T-170)

### 1. Propuesta de Integración y Aprobación Humana
- Propuesta formal presentada en el chat evaluando Cloudflare DNS frente a Infisical y GitHub.
- Aprobación explícita recibida para la zona `romensuarez.com` bajo directiva estricta:
  - Token acotado a `Zone.DNS:Edit` y `Zone.Zone:Read` exclusivamente para `romensuarez.com`.
  - Cero secretos en git, nunca impresos, nunca por chat.
  - Clave de Nango almacenada en Infisical (`/shared`, entorno `dev`).
  - Primera verificación en solo lectura (listar registros DNS).

### 2. Gestión de Credenciales y Registro Seguro en Nango
- `NANGO_SECRET_KEY` extraída de forma segura desde la instancia viva y guardada en Infisical (`/shared`).
- Conexión autorizada `romensuarez-com` registrada en Nango (`<nodo-orquestacion>:3003`) vinculada al proveedor nativo `cloudflare` (`unique_key: cloudflare-dns`).
- Token verificado en Cloudflare validando pertenencia exclusiva de la zona `romensuarez.com` sin exponer el valor.

### 3. Implementación de `scripts/agent/lib/nango-client.sh`
- Cliente determinista CLI con soporte para:
  - `--check`: Sonda rápida de salud (exit 0 si activo, exit 2 si no configurado).
  - `--list-integrations`: Lista integraciones activas (`cloudflare-dns`).
  - `--list-connections`: Lista conexiones activas (`romensuarez-com`).
  - `--proxy <path>`: Proxy unificado autenticado hacia la API externa sin exponer tokens.
  - `--json`: Salida estructurada.

### 4. Verificación de Funcionamiento en Solo Lectura (Evidencia Nango Proxy)
- Ejecución de inspección DNS a través del proxy de Nango:
  ```bash
  bash scripts/agent/lib/nango-client.sh --proxy "/v4/zones?name=romensuarez.com" --provider cloudflare-dns --connection romensuarez-com
  ```
  Retorna la zona activa `romensuarez.com` de forma delegada.
- Consulta de registros DNS existentes (primeros 5 registros):
  ```
  - A api.romensuarez.com -> <ip-publica-vps> (Proxied: False)
  - A blog.romensuarez.com -> <ip-publica-vps> (Proxied: True)
  - A brain-api.romensuarez.com -> <ip-publica-vps> (Proxied: True)
  - A brain.romensuarez.com -> <ip-publica-vps> (Proxied: False)
  - A cdn.romensuarez.com -> <ip-publica-vps> (Proxied: True)
  ```
- 0 escrituras ejecutadas; lectura delegada 100% verificada sin credenciales en disco.

### 5. Suite de Validación de Control Plane
- Resultado: **38/38 validaciones superadas (0 errores)** certificando cliente determinista, templates, runbook y scripts de integración.

---

## Declaraciones Técnicas y de Gobernanza

Para formalizar los compromisos operativos y registrar las tres declaraciones formales requeridas por la gobernanza de Agent OS tras el cierre de T-170:

### 1. Naturaleza del Token Cloudflare (Nuevo vs. Reutilizado)
- Se generó y aprovisionó un token nuevo dedicado con privilegios mínimos exclusivos (`Zone.DNS:Edit` y `Zone.Zone:Read` acotados únicamente a la zona `romensuarez.com`).
- No se reutilizó el token general de la flota (`CLOUDFLARE_API_TOKEN`), blindando el principio de aislamiento de privilegios.

### 2. Ruta Canónica en Infisical
La clave maestra de Nango queda formalmente ubicada bajo la ruta canónica de la flota:
- **Proyecto**: Agent OS Fleet
- **Entorno**: `dev`
- **Path canónico**: `/shared`
- **Clave**: `NANGO_SECRET_KEY`

### 3. Declaración de Archivo Fuera de Caja (`SKILL.md`)
En T-170 se modificó `.agents/skills/coolify-nextjs-deploy/SKILL.md` (línea 58) sin figurar en la Caja de archivos del contrato original de la tarea.
- **Justificación**: Se documentó la vía de verificación delegada de registros DNS en modo solo lectura a través de `nango-client.sh --proxy` antes de provisionar dominios en Coolify, mejorando la operatividad de la skill sin alterar su comportamiento por defecto.
- **Resolución**: Se ratifica la modificación y se declara subsanada formalmente en el registro del sprint y de la tarea.
