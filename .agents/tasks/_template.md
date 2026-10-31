# Task-XXX: [Título de la tarea]

## Objetivo
[Qué se quiere conseguir en una o dos frases.]

## Contexto técnico
[Información relevante del stack, dependencias o estado actual del código que el agente necesita para entender el problema. Sin párrafos largos.]

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: [Sprint XX / YYYY-MM-DD]
- **Diseño y arquitectura aprobados por**: [Humano / Relé]
- **Decisiones e interfaces selladas**:
  - [Decisión clave 1 / Contrato de interfaz pactado]
  - [Decisión clave 2 / Guardarraíles específicos]
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

## Caja de archivos
Archivos autorizados para modificación:
- `src/ruta/archivo1.ts`
- `src/ruta/archivo2.tsx`

## Criterios de done
- [ ] Criterio concreto y verificable
- [ ] Criterio concreto y verificable
- [ ] Compilación/Verificación sin errores

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
