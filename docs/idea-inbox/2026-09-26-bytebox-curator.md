# Idea: Skill y Helper CLI para ByteBox (bytebox-curator)

**Fecha**: 2026-09-26  
**Origen**: Petición de usuario durante cierre de T-050  
**Estado**: 💡 Capturada para próximo sprint / backlog

---

## 1. Concepto
Crear una skill especializada (`bytebox-curator`) y un script CLI determinista (`scripts/agent/bytebox-cli.sh`) que permita al agente y al usuario registrar snippets de código, comandos CLI y notas técnicas en la instancia activa de ByteBox sin fricción manual.

---

## 2. Puntos Clave de Diseño
1. **API REST directa**:
   - Consumir el endpoint `POST /api/cards` de ByteBox con payload JSON `{ title, type: 'command'|'snippet'|'note', content, description, tags, categoryId }`.
   - Utilizar la URL registrada en `config/fleet.yaml` (`nodes.oracle.services.bytebox.url`).
2. **Criterio Anti-Ruido (HITL)**:
   - Evitar capturas automáticas indiscriminadas de comandos básicos (`git status`, `npm run dev`).
   - Actuación por comando explícito del usuario (*"guarda este comando en ByteBox"*) o propuesta sugerida por el agente al finalizar tareas complejas de devops/arquitectura con comandos no triviales.
3. **Integración Operativa**:
   - Enlace opcional en la Fase 6 de cierre de sesión o en la skill `doc-maintainer`.
