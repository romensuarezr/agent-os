# ADR 001: Core sin dependencias y auto-hospedaje (Self-Hosting)

**Estado:** Accepted  
**Fecha:** 2026-06-16  
**Contexto:** Sprint 02 — Core  

## Contexto
Agent OS está diseñado para ser portable y compatible con cualquier repositorio de código, independientemente de su lenguaje o framework. Si el core dependiera de un gestor de paquetes específico (como npm o pip) para su funcionamiento básico, obligaríamos a todos los repositorios clientes a introducir dependencias que podrían entrar en conflicto con sus propios entornos. Además, necesitamos un entorno de autodesarrollo donde el core pueda gestionarse a sí mismo sin recursión infinita de copia de scripts.

## Decisión
1. Mantener el core libre de dependencias de empaquetado externas (sin `package.json` o `requirements.txt` obligatorios en el núcleo). El comportamiento se basa en scripts de shell (`bash`) y archivos en formato Markdown.
2. Centralizar la instalación en un script `install.sh`.
3. Soportar el mecanismo de auto-hospedaje (self-hosting) con el flag `--self`. Al ejecutar `bash scripts/agent/install.sh . --self`, el script detecta que está en el propio core, omite la duplicación de los archivos de script (que ya existen) y solo inicializa la estructura de directorios y archivos de sesión necesarios para operar sobre el repositorio de Agent OS.

### Componentes Clave
1. `scripts/agent/install.sh`: Script principal de instalación. Maneja el flag `--self`.
2. `.agents/`: Directorio local de configuración operativa del agente en cualquier proyecto, incluido en el propio core cuando se auto-hospeda.

## Consecuencias

### Positivas (Pros)
* **Portabilidad total**: Funciona en cualquier sistema UNIX que soporte Bash sin necesidad de instalar entornos de ejecución de lenguajes de programación adicionales.
* **Aislamiento**: Cero impacto en las dependencias de los proyectos hijos.
* **Bootstrapping simple**: Permite a los agentes trabajar en el repositorio de Agent OS usando el propio flujo de trabajo de Agent OS.

### Negativas (Cons)
* **Complejidad en Bash**: El desarrollo de lógica compleja en shell scripts es más propenso a errores silenciosos en comparación con TypeScript o Python.
* **Testing limitado**: No disponemos de frameworks robustos de testing integrados (como Jest o Pytest) sin añadir dependencias, dependiendo de tests de aserción nativos en bash.

### Riesgos y Mitigaciones
* **Incompatibilidad de Bash en diferentes OS**: *Probabilidad: Media* -> *Mitigación*: Mantener compatibilidad con POSIX y evitar comandos o flags específicos de distribuciones GNU que rompan en macOS/WSL.

## Referencias
* [AGENTS.md](file:///home/romen/Proyectos/agent-os/AGENTS.md)
* [scripts/agent/install.sh](file:///home/romen/Proyectos/agent-os/scripts/agent/install.sh)
