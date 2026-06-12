---
name: rule-creator
description: Formaliza solicitudes de comportamiento del usuario en reglas persistentes que el agente seguirá en futuras sesiones.
---

# Creador de Reglas (Rule Creator)

Esta habilidad permite al usuario dictar nuevas "leyes" o comportamientos que el agente debe respetar siempre, convirtiéndolas en archivos de reglas formales en `.agents/rules/`.

## Propósito
Capturar preferencias, restricciones de seguridad, o principios de diseño que deben ser permanentes y globales para todos los agentes.

## Flujo de Trabajo

1.  **ANÁLISIS DE INTENCIÓN**:
    - Cuando el usuario dice: "Quiero que siempre...", "Nunca hagas...", "A partir de ahora usa...".
    - El agente interpreta esto como una solicitud de **Regla Permanente**.

2.  **REDACCIÓN DE PROPUESTA**:
    - Generar un Artifact (`Propuesta de Regla [Nombre]`) con el contenido propuesto.
    - Usar el **Template Obligatorio** (ver abajo).
    - Asegurar que el frontmatter YAML sea correcto (`trigger: always_on`).

3.  **REVISIÓN Y APROBACIÓN (Bloqueante)**:
    - Usar `notify_user` con `BlockedOnUser: true`.
    - Mensaje: "He redactado esta regla basada en tu solicitud. ¿La activo?"

4.  **PERSISTENCIA**:
    - **Solo si aprobado**:
        - Crear el archivo en `.agents/rules/[nombre-kebab].md`.
        - Ejecutar (opcional pero recomendado):
          - `git add .agents/rules/[archivo]`
          - `git commit -m "docs(rules): add rule [nombre]"`

## Template Obligatorio

```markdown
---
trigger: always_on
---

# [Nombre de la Regla]

> [Breve descripción del principio o la intención]

## Reglas
1. **[Instrucción Principal]**: [Detalle de qué hacer o no hacer]
2. **[Instrucción Secundaria]**: ...

## Ejemplos
- ✅ **Correcto**: [Ejemplo de comportamiento deseado]
- ❌ **Incorrecto**: [Ejemplo de comportamiento a evitar]

## Excepciones
- [Si aplica, casos donde esta regla no se activa]
```

## Verificación
- El archivo debe residir en `.agents/rules/`.
- Debe empezar con `--- trigger: always_on ---`.
