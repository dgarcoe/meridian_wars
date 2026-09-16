# Verificación de la versión 0.2

Entorno local: Godot 4.3.stable.official.77dcf97d8, Linux sin servidor gráfico.

## Ejecutado localmente

- Importación del proyecto y parser de Godot.
- 46 comprobaciones del prototipo estratégico original.
- 46 comprobaciones de misión, combate táctico, persistencia y determinismo.
- Límites de layout a 1600×1000 en briefing, despliegue, contacto e informe.
- Arranque de la escena principal.
- Recorrido de escenas hasta batalla y vuelta a informe, con renderizador dummy.

El modo dummy emite errores `mesh_get_surface_count` en las mallas 3D. No se
ocultan ni se cuentan como una validación gráfica. La instalación local de Xvfb
falló por permisos; no se han sorteado esas restricciones.

## Comprobación gráfica reproducible

`.github/workflows/godot-tests.yml` ejecuta las reglas y el layout, después
`scene_smoke.gd` y `visual_capture.gd` con Xvfb/OpenGL por software en el runner.
Los pasos gráficos fallan ante mensajes `ERROR:` o `SCRIPT ERROR`. El driver
de audio Dummy evita depender de una tarjeta de sonido en CI; el renderizado
sí usa OpenGL real por software.
Las capturas se publican como artefacto `meridian-engine-screenshots`.
Consultar el resultado de Actions del commit; configurar un workflow no implica
que ya se haya ejecutado con éxito.

## Revisión manual pendiente

- Composición visual de las cuatro capturas reales y legibilidad con escalado.
- Raycasting de selección y órdenes con ratón en distintos tamaños de ventana.
- Cámara orbital, navegación WASD y teclado con foco en botones.
- Pruebas prolongadas para balance, rendimiento y diferencias entre plataformas.

No se declara arte final, calidad comercial ni una campaña completa.
