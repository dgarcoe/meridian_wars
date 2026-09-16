# Validación de la entrega inicial

- Comprobación de referencias `res://` y separación estructural de dominio:
  ejecutar `python3 tools/check_structure.py`.
- Limpieza del diff: `git diff --cached --check`.
- Godot no está instalado en el entorno de creación. Las pruebas GDScript,
  la compilación/importación y el aspecto visual NO están verificados aquí.
- Antes de ampliar funcionalidades, ejecutar ambos comandos Godot del README.
  Una comprobación estática de rutas no sustituye al parser ni al motor.
- Repositorio local: rama `main`. No se ha creado un remoto GitHub.

Python es opcional para esta comprobación de desarrollo, no para ejecutar el juego.
