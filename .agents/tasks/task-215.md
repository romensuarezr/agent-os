# Task-215: Despliegue de Harness y Autenticación Dual Google Pro en el VPS (agy + agy2)

## Objetivo
Desplegar el harness nativo de Antigravity en el VPS `datamanager` (ARM64) y configurar dos perfiles de ejecución aislados vinculados a las dos cuentas de Google Pro (`agy` y `agy2`), aplicando primero el Método Inmediato (Cero Fricción) mediante la transferencia segura de tokens OAuth desde la estación local a través de Tailscale.

## Contexto técnico
- En la estación local, el operador dispone de dos cuentas Google Pro aisladas en perfiles (`HOME=/home/romen/.antigravity_pro2` y `HOME=/home/romen/.antigravity_pro3`).
- El paquete PyPI `google-antigravity` (0.1.23) proporciona el wheel oficial para Linux ARM64 con el binario nativo `localharness` y soporte para `local_openai_connection` y Google Auth.
- La transferencia del archivo `antigravity-oauth-token` permite que el VPS quede autenticado inmediatamente sin requerir interacción gráfica en navegador.
- En caso de fallo con los tokens transferidos, se dispone del método fallback Out-of-Band (`ANTIGRAVITY_REMOTE_OOB_AUTH`).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 40 / 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Romén)
- **Decisiones e interfaces selladas**:
  - Probar en primera instancia el Método Inmediato (Cero Fricción) transfiriendo los tokens de `agy` y `agy2`.
  - Crear los directorios de perfil en `datamanager`: `/home/ubuntu/.antigravity_pro1` y `/home/ubuntu/.antigravity_pro2`.
  - Crear los scripts envoltorios `/home/ubuntu/.local/bin/agy` y `/home/ubuntu/.local/bin/agy2` en `datamanager`.
  - Verificar que ambos perfiles pueden consultar modelos Pro sin errores de autenticación.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-40.md`
- `.agents/config/fleet.yaml` (si requiere registrar los runtimes remotos)

## Criterios de done
- [ ] Entorno de ejecución de Antigravity operativo en `datamanager` (ARM64).
- [ ] Perfil `agy` (Google Pro 1) configurado y autenticado en el VPS.
- [ ] Perfil `agy2` (Google Pro 2) configurado y autenticado en el VPS.
- [ ] Ejecución de prueba con éxito en ambos perfiles (prompt simple no destructivo devolviendo respuesta válida).

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
