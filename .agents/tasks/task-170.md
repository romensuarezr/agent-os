# Task-170: Primera integración real de Nango en flujo operativo de agente

## Estado
⬜ Pendiente

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
- [ ] Documento formal de propuesta de integración de Nango presentado al operador.
- [ ] Aprobación humana explícita obtenida antes de conectar credenciales.
- [ ] Integración provisionada y conectada en la instancia viva de Nango.
- [ ] Flujo operativo o script de Agent OS consumiendo activamente la integración con Nango.
- [ ] Evidencia de funcionamiento real verificada y reportada sin exposición de secretos.
- [ ] Runbook operativo actualizado con el flujo de uso del conector.
- [ ] Suite de validación de control plane inmutable en 38/38 pasando limpia (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
