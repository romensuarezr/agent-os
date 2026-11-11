# Task-198: Política de enrutamiento /advisor y catálogo FreeLLMAPI

## Objetivo
Formalizar el rol de modelo Asesor (`advisor`) en la política de enrutamiento de inferencia y declarar los proveedores DeepSeek MoE y Nvidia NIM en la plantilla de configuración de FreeLLMAPI, reduciendo el sobrecoste de generación de código.

## Contexto técnico
- `.agents/config/routing-policy.yaml` (118 líneas) no contiene hoy ningún rol `advisor` ni referencias a DeepSeek/NIM (verificado por grep).
- `templates/freellmapi/config/freellmapi.config.json` no declara conectores DeepSeek MoE ni Nvidia NIM (verificado por grep).
- Patrón eficiente: workers económicos/rápidos para codificación mecánica; modelo top delegado como *Asesor* en deliberación y arquitectura.
- Ambos proveedores exponen API OpenAI-compatible (NIM: `base_url` `https://integrate.api.nvidia.com/v1`; DeepSeek: endpoint compatible chat/completions) — verificado en consultas SearXNG del research del sprint.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 36 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - `routing-policy.yaml`: nuevo rol `advisor` añadido de forma retrocompatible — las rutas existentes no se renombran ni eliminan; esquema YAML conservado (claves ya en uso del fichero).
  - Modelo de política: workers rápidos para codificación intensiva → delegación al modelo top solo en diseño/arbitraje/deliberación (rol `advisor`).
  - `freellmapi.config.json`: dos proveedores nuevos (`deepseek` MoE y `nvidia-nim`) con `base_url` OpenAI-compatible, **sin secretos en claro** (placeholders `***` o variables de entorno, política cero claves en git).
  - El template sigue siendo JSON válido y agnóstico de stack; no se muta ningún paquete en caliente.
  - Scout-First: sin alternativa OSS ≥500⭐ para catálogo de conectores → desarrollo a medida justificado (registrado en research).
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/config/routing-policy.yaml`
- `templates/freellmapi/config/freellmapi.config.json`

## Criterios de done
- [ ] `routing-policy.yaml` declara el rol `advisor` y rutas existentes intactas; YAML válido.
- [ ] `freellmapi.config.json` declara proveedores DeepSeek MoE y Nvidia NIM; JSON válido y sin claves reales.
- [ ] Cero dependencias nuevas y cero paquetes mutados.
- [ ] Suite `tests/validate-control-plane.sh` en verde sin regresiones.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `[CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR]`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
