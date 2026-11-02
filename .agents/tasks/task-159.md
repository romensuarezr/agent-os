# Task-159: Cliente CLI determinista para Bane (`bane-client.sh`) con salida stdout y sonda

## Objetivo
Implementar el cliente CLI determinista en Bash `scripts/agent/lib/bane-client.sh` para interactuar con la API del servicio Bane (deep research), con salida primaria por stdout en formato Markdown, soporte para flags estándar (`--query`, `--timeout`, `--output`, `--json`, `--check`), wrapper de timeout portable y semántica estricta de disponibilidad: el servicio se clasifica como activo única y exclusivamente si está configurado Y alcanzable dentro de la cota de tiempo, degradando de forma limpia y silenciosa si no está disponible sin bloquear la ejecución del agente.

## Contexto técnico
El consumo desatendido de motores de deep research requiere un cliente ligero, universal y con coste $0 de tokens que encaje en la filosofía UNIX de Agent OS:
1. **Salida primaria por stdout**: Los resultados de la investigación se emiten directamente por stdout en Markdown estructurado, permitiendo pipes directos a ficheros de research o a otros scripts de procesamiento sin obligar a usar archivos temporales salvo con `--output <path>`.
2. **Definición técnica de "Activo"**: Un endpoint de Bane se considera `ACTIVO` solo si:
   - Está explícitamente configurado (vía variable `BANE_API_URL` o lectura en `.agents/config/fleet.yaml`).
   - Y responde satisfactoriamente a una sonda HTTP GET/POST dentro de una ventana de timeout estricta (por defecto 3s).
   - Si no está configurado o si el ping excede el timeout / falla la conexión, el cliente emite estado inactivo (código de salida reconocible, e.g. 2) sin lanzar errores fatales.
3. **Robustez y Portabilidad**: Basado en `curl` nativo, validación con `scripts/agent/lib/portable-timeout.sh` y formateo seguro sin exponer credenciales en argv o procesos visibles.

Esta tarea se ejecuta bajo el régimen autónomo del **Piloto Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28 - Enmienda Bane)
- **Decisiones e interfaces selladas**:
  - Implementar `scripts/agent/lib/bane-client.sh` con flags:
    - `--query <string>`: Texto de la consulta de investigación técnica.
    - `--timeout <segundos>`: Presupuesto temporal de espera (por defecto 60s para query, 3s para check).
    - `--output <path>`: Archivo de destino opcional; por defecto emite por stdout.
    - `--check`: Modo sonda de salud; emite código 0 si activo, código 2 si inactivo/inalcanzable.
    - `--json`: Emisión de metadatos estructurados en JSON.
    - `-h, --help`: Ayuda canónica del CLI.
  - Sonda fail-soft: En ningún caso una pasarela caída debe provocar un aborto no controlado del script padre.
  - Cero dependencias de librerías externas o frameworks Node/Python.
  - Denominador de la suite de control plane se mantiene en **37/37** (0 errores).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Desarrollo de librerías deterministas CLI del core.
- `tool-inventory`: Consumo de configuraciones de herramientas de la flota.

## Caja de archivos
- `scripts/agent/lib/bane-client.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-159.md`

## Criterios de done
- [ ] Script `scripts/agent/lib/bane-client.sh` implementado y con permisos de ejecución.
- [ ] Ayuda estándar expuesta con `-h` y `--help`.
- [ ] Salida primaria por stdout en Markdown estructurado verificada.
- [ ] Semántica de "activo" (configurado Y alcanzable en timeout) probada con mocks de red offline y online.
- [ ] Degradación limpia fail-soft ante servicio caído sin bloquear procesos padres.
- [ ] Suite pasando limpia en 37/37 (0 errores).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
