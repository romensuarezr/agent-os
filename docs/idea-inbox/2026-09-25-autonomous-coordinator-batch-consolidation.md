# Idea: Orquestación Autónoma Desatendida desde el Coordinador (Single-Pane of Glass)

> **Fecha**: 2026-09-25  
> **Estado**: 💡 Capturada en Idea Inbox  
> **Área**: UX de Agentes / Orquestación Multi-Agente / Swarm Autonomous Coordination  
> **Origen**: Sesión de trabajo Sprint 08 — Feedback del usuario sobre interacción multi-agente  

---

## 1. Problema y Oportunidad

En la interacción multi-agente actual en Orca ADE, al despachar workers en paralelo sobre distintos worktrees, la UX requería que el usuario navegase manualmente entre las pestañas de cada worktree para revisar y aprobar el avance de cada agente.

**Visión del Usuario**:
- El usuario habla **exclusivamente con el agente Coordinador en la terminal principal** (interfaz única o *single-pane of glass*).
- El usuario aprueba el plan del lote en la terminal principal.
- El Coordinador despacha a los agentes obreros a sus worktrees en Orca.
- Los agentes se comunican entre sí y con el Coordinador de forma autónoma.
- El Coordinador supervisa la ejecución en segundo plano, recopila los resultados, diffs y verificaciones, y entrega **un único informe consolidado final en la terminal principal**.
- El usuario no tiene que saltar entre pestañas ni microgestionar worktrees.

---

## 2. Líneas de Investigación y Referencias Técnicas

1. **Orca Federation & Control Mail**:
   - Orca ADE v1.4 incluye capacidades de federación:
     - `orchestration.federation.v1`
     - `orchestration.federation-control-mail.v1`
     - `orchestration.worker-stop-verdict.v1`
   - Investigar cómo usar `orca orchestration check --wait` y el bus de correo de control (`control-mail`) para que el script coordinador recoja automáticamente la salida estructurada de cada worker sin intervención del usuario.
2. **Patrón Hierarchical Swarm / Supervisor**:
   - Modelos como LangGraph Supervisor o Claude Agent Teams donde los sub-agentes tienen terminación autónoma y envían su artefacto final al padre.
3. **Mapeo de Flujo Futuro**:
   - `session-start` aprueba el lote.
   - `orca-orchestrate.sh batch --wait` mantiene la escucha en segundo plano o asíncrona.
   - Al terminar todos los workers, emite el `consolidated-digest.json` con todos los cambios listos para commit o merge.

---

## 3. Próximos Pasos
- Buscar tutoriales y documentación avanzada de Orca ADE sobre automatización desatendida y federation control mail.
- Probar un prototipo en una rama experimental cuando se aborde en futuros sprints.
