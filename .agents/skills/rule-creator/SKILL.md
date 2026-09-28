---
name: rule-creator
description: Formaliza solicitudes de comportamiento del usuario en reglas persistentes que el agente seguirá en futuras sesiones.
tools:
  - name: notify_user
    optional: true
  - name: ask_question
    optional: true
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
    - Generar un Artifact o borrador con el contenido propuesto.
    - Usar el **Template Obligatorio** (ver abajo).
    - Asegurar que el frontmatter YAML sea correcto (`trigger: always_on` o el valor controlado correspondiente).

3.  **REVISIÓN Y APROBACIÓN (Bloqueante)**:
    - **En runtimes con tool calls interactivos**: Usar `notify_user` con `BlockedOnUser: true` o `ask_question`. Mensaje: "He redactado esta regla basada en tu solicitud. ¿La activo?"
    - **Alternativa portable Shell/POSIX**: En entornos de terminal pura o runtimes CLI sin herramientas interactivas nativas, imprimir la propuesta formateada en pantalla y solicitar confirmación expresa vía `read -p "¿Deseas activar esta regla? [s/N]: " confirm` o mediante un prompt conversacional estándar antes de persistir.

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
