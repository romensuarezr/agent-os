# Goal Schema & End State Contract
# Esquema Declarativo para Metas Persistentes (/goal y /subgoal)

Este esquema define el contrato formal entre el Orquestador/Coordinador y los Workers/Judges en agent-os. Toda meta persistente o submeta instanciada debe cumplir esta estructura.

---

## 1. Metadatos de la Meta
- **goal_id**: `GOAL-<TASK-ID>` (ej: `GOAL-T-054` o `SUBGOAL-T-054-01`)
- **parent_goal_id**: `<ID-META-PADRE>` (vacío si es meta principal)
- **title**: "[Título conciso y descriptivo]"
- **assigned_profile**: `[coordinator | coder | qa-judge | docs-researcher]`
- **created_at**: "YYYY-MM-DDTHH:MM:SSZ"
- **status**: `[pending | in_progress | under_review | verified | escalated_to_human | rejected]`
- **retry_count**: 0  # Máximo permitido: 3 (Circuit Breaker)

---

## 2. Descripción e Intención
[Descripción detallada de la meta, contexto de negocio y restricciones técnicas].

---

## 3. End State Contract (Criterios Binarios de Éxito)
Condiciones observables e irrefutables para declarar la meta como completada:
- [ ] Criterio binario 1 (Verificable de forma determinista o por inspección)
- [ ] Criterio binario 2
- [ ] Criterio binario 3

---

## 4. Caja de Archivos Autorizados (Allowlist)
Lista exhaustiva de archivos cuya creación o modificación está permitida durante la ejecución de esta meta. Cualquier archivo modificado fuera de esta lista causará el fallo inmediato de las compuertas técnicas.

```yaml
allowlist:
  - "path/to/file1.ext"
  - "path/to/file2.ext"
  - "dir/allowed-pattern/*.ext"
```

---

## 5. Quality Gates Deterministas (0 Tokens de Inferencia)
Comandos automáticos ejecutados por `scripts/agent/verify-goal.sh`:

1. **Git Status Clean Gate**:
   - Comando: `test -z "$(git status --porcelain)"`
   - Veredicto esperado: 0 (Working tree limpio sin cambios untracked o staged pendientes).

2. **Allowlist Scope Gate**:
   - Comando: Comparar `git diff --name-only <base_ref>...HEAD` contra `allowlist`.
   - Veredicto esperado: 0 violaciones detectadas.

3. **Project Test Suite Gate**:
   - Comando: `tests/validate-control-plane.sh` (o runner detectado del proyecto).
   - Veredicto esperado: Código de salida 0.

---

## 6. Protocolo de Evaluación Judge (Ralph Loop)
- **Judge Asignado**: Agente con perfil `qa-judge` o script determinista `verify-goal.sh`.
- **Condición de Parada (Circuit Breaker)**:
  - Intentos máximos de auto-corrección: **3 retries**.
  - Si tras 3 intentos consecutivos la meta no satisface los Quality Gates, el estado cambia automáticamente a `escalated_to_human` y se suspende la ejecución hasta intervención manual.

---

## 7. Registro de Verificación (Audit Trail)
| Intento | Timestamp | Veredicto | Allowlist Pass | Tests Pass | Resumen / Violaciones |
| :---: | :---: | :---: | :---: | :---: | :--- |
| 1 | YYYY-MM-DDTHH:MM:SSZ | PENDING | - | - | Registro inicial |
