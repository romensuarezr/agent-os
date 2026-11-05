# Executive Design Digest — T-170

## 🎯 Objetivo
Implementar la primera integración productiva real de Nango en un flujo de trabajo de la flota de Agent OS. La tarea inicia obligatoriamente con una **propuesta formal sellada ante el humano** (analizando candidatos como Cloudflare / Infisical u otros servicios de la flota, el flujo real desbloqueado y qué credenciales u OAuth toca). **Sin aprobación humana explícita de la propuesta en el chat, queda prohibido conectar nada**. Tras recibir dicha aprobación, conectar el conector seleccionado a la instancia viva de Nango (<nodo-orquestacion>:3003) y construir o adaptar un flujo operativo de agente que lo consuma activamente con evidencia verificable.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-170 satisface las restricciones arquitectónicas de Agent OS y la directiva de Gobernanza Opción D. La elección de Cloudflare (DNS) frente a Infisical o GitHub como primer caso de integración real en Nango es técnicamente adecuada por su acotado radio de impacto y alto beneficio en la automatización de dominios para despliegues con Coolify. La decisión de encapsular la consulta en `scripts/agent/lib/nango-client.sh` respeta la política de scripts deterministas de coste cero y centraliza la obtención de credenciales efímeras sin persistencia de secretos en disco.
- **Prospección Scout**: `CONFORME (sprint-30-research.md)`
  - Alternativa detectada:** Cloudflare API / OAuth, Infisical Universal Auth, GitHub App Connector, Slack / Notion.
  - Recomendación del agente:** Elaborar propuesta formal sellada ante el humano con trade-offs, analizando Cloudflare e Infisical como candidatos inmediatos, flujos desbloqueados y credenciales implicadas. Bloquear toda conexión hasta obtener aprobación humana expresa. Conectar en Nango y crear/adaptar flujo de agente con evidencia real.
  - Dictamen del Relé (Enmienda vinculante):** Ratificado. La compuerta humana previa es estricta: ninguna credencial ni conector se aprovisiona sin la aprobación explícita en chat. Denominador inmutable en 38/38.
  - Alternativas rechazadas y motivos:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-170-nango-real-integration' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/skills/coolify-nextjs-deploy/SKILL.md`
- `.agents/tasks/_archived/task-170.md`
- `docs/runbooks/nango-oauth-service.md`
- `docs/sprints/sprint-30-core.md`
- `scripts/agent/lib/nango-client.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `infisical-secrets`
- `coolify-nextjs-deploy` / `coolify-admin`
