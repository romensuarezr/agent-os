# Task-139: Verificar el recolector de eventos Orca en host (`check --run --wait` frente a `--types`, payload `worker_done`)

## Objetivo
Verificar empíricamente en el host el comportamiento del comando `orca orchestration check` bajo el modo reactivo (`--wait`), analizando la semántica del filtro `--types`, la gestión de keepalives y la estructura del evento `worker_done` para determinar si transporta el veredicto en su payload o si requiere lectura posterior vía `worker-read`.

## Contexto técnico
Actualmente, el motor de deliberación (`deliberate-plan.sh`) consulta el estado del worker mediante sondeo activo (polling) con `orca orchestration worker-read`, durmiendo 2 segundos en cada iteración hasta que detecta los delimitadores del veredicto JSON o se agota el timeout de 60 segundos.

Orca ADE dispone de un bus de eventos accesible mediante `orca orchestration check` con las siguientes particularidades documentadas en su CLI:
1. `--types <tipo,...>` opera como **condición de despertar (wake condition)** para `--wait`, pero el lote entregado (`Delivery`) es siempre el lote FIFO completo sin filtrar por tipo (solo `--peek` y `--all` filtran sus filas).
2. Durante la espera con `--wait`, emite pulsos keepalive periódicos cada 15 segundos a stderr (`{"_keepalive": true}`).
3. Es necesario clarificar si el evento `worker_done` incluye el contenido emitido por el modelo en su payload de salida o si actúa meramente como señal de sincronización indicando que el proceso del worker ha finalizado.

Esta tarea ejecutará pruebas controladas y no destructivas en el host para documentar formalmente la interacción reactiva y definir si `deliberate-plan.sh` o futuros componentes multi-agente pueden adoptar este mecanismo reactivo en sustitución del polling.

## Skills relevantes
- `orchestrator`: Eventos agénticos asíncronos y primitivas de sincronización reactiva.
- `doc-maintainer`: Registro metódico y estructuración de runbooks de verificación experimental.

## Caja de archivos
- `docs/runbooks/orca-event-collector-verification.md`
- `.agents/tasks/task-139.md`

## Criterios de done
- [ ] Ejecutada prueba empírica en host con `orca orchestration check --wait` sobre un Run supervisado.
- [ ] Comportamiento de `--types` verificado: documentado cómo opera como condición de despertar para `--wait` y cómo se estructuran los lotes retornados (`Delivery`).
- [ ] Caracterizado el flujo de keepalives emitidos a stderr cada 15s y verificado el patrón para ignorarlos (`select(._keepalive|not)`).
- [ ] Analizada la carga útil del evento `worker_done`: constatado si contiene el payload con la salida del worker o si exige una invocación subsiguiente a `worker-read`.
- [ ] Documentación canónica generada en `docs/runbooks/orca-event-collector-verification.md` con comandos reproducibles y contratos de eventos.
- [ ] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene de secretos/rutas.
