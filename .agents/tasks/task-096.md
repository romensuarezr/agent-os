# Task-096: Guidance operativo del working tree post-instalación en `install.sh`

## Objetivo
Que `install.sh` deje explícito, al terminar, el estado esperado del working tree del proyecto recién instalado y qué debe hacer el agente a continuación, eliminando la ambigüedad entre "instalado" y "listo para trabajar".

## Contexto técnico
`install.sh` despliega assets en el hijo y hoy no emite ninguna guía sobre el estado del árbol de trabajo tras la instalación. El resultado: el agente asume que puede commitear cualquier cosa y arrastra al primer commit archivos generados por el propio instalador, o peor, da por buena la instalación sin comprobar que el árbol quedó como se esperaba.

La ya existente guía de flujo de trabajo en `sync.sh` cubre la marca de trazabilidad (`last-sync.md`), pero no el estado del árbol. El mensaje final debe ser corto y accionable, coherente con el estilo de salida de los demás scripts del core (emoji + causa + acción), y no debe distinguir por plataforma con lógica propia.

Estado a documentar explícitamente: archivos modificados o añadidos por la instalación, si el árbol debe quedar limpio antes de empezar a trabajar, y qué hacer si el árbol ya estaba sucio antes de instalar (instalación no destructiva por defecto: se opera en modo detección salvo `--apply`).

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/install.sh`
- `changelog.md`
- `.agents/tasks/task-096.md`

## Criterios de done
- [ ] `install.sh` emite al final un bloque de estado del working tree (rutas exactas, sin rutas personales).
- [ ] El mensaje distingue árbol limpio de árbol con cambios preexistentes y en ambos casos dice qué hacer a continuación.
- [ ] Funciona idéntico en Linux y macOS (sin `ls -d`, `realpath` con flags GNU, ni `sed -i`).
- [ ] La salida no incluye IPs, dominios ni secretos.
- [ ] `bash tests/validate-control-plane.sh` sin regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente