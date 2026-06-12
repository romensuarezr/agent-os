# Agent OS

> Repositorio central de configuración para agentes de IA en el ecosistema de romensuarezr.

## Propósito
Este repositorio contiene las reglas, skills y workflows universales que comparten todos mis proyectos. El objetivo es mantener una experiencia de desarrollo consistente, segura y eficiente, permitiendo que cada proyecto individual solo gestione su contexto específico.

## Estructura
- `.agents/rules/global/`: Reglas de comportamiento y estándares de ingeniería universales.
- `.agents/skills/global/`: Habilidades transversales (auditoría, planificación).
- `.agents/workflows/`: Plantillas para el ciclo de vida de las sesiones y sprints.
- `.agents/templates/`: Estructuras base para nuevos proyectos (onboarding, DoD).

## Cómo Usar
Para instalar este sistema en un nuevo repositorio, usa el script `install.sh` (próximamente):
```bash
bash install.sh /ruta/al/proyecto
```

Para sincronizar actualizaciones:
```bash
bash sync.sh /ruta/al/proyecto
```

---
*Core version: 1.0*
