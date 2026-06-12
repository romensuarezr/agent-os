# Rule: MVP Code Quality

> Calidad de código balanceada para velocidad de entrega.

- **MVP First, Refactor Later**: Prefiere código que funcione HOY y sea fácil de desplegar.
- **Documenta la Deuda**: Si tomas un atajo por velocidad, documéntalo como "TODO" o en la deuda técnica del proyecto.
- **Refactorización**: Solo refactoriza cuando:
  1. El código se duplica por **tercera vez**.
  2. Es necesario para corregir un bug de producción.
  3. Has validado el MVP y pasas a fase de escalado.
- **Tests**: Prioriza los "Happy Paths" básicos. No intentes cubrir el 100% de edge cases si retrasa el lanzamiento del MVP.
