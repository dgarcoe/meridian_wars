# Meridian Wars — Operación Nártex

Primera misión integrada de estrategia espacial original en **Godot 4.3**.
Interfaz de mando naval, decisiones previas, despliegue y combate 3D con pausa.
No es todavía una gran campaña: esta entrega valida un recorrido completo de misión.

## Empezar

1. Clona el repositorio e importa `project.godot` en Godot 4.3 estándar.
2. Pulsa F5. Elige comandante y doctrina; autoriza la operación.
3. Refuerza las escuadras y salta de Veyra a Sereva y después a Nártex.
4. Pulsa **Asumir mando táctico**. La batalla comienza en pausa.
5. Da órdenes, inicia el combate y vuelve al centro de mando al finalizar.

Diseño lógico de 1600×1000, escalado a la ventana (1440×900 por defecto).
No requiere .NET, Python, plugins ni paquetes artísticos externos para jugar.

## Qué incluye

- Centro de mando azul profundo, dorado/cian, paneles de escuadras y registro.
- Mapa vectorial de 12 sistemas: inspección, zoom y desplazamiento.
- Una ruta operativa de dos saltos; el resto de sistemas es contexto cartográfico.
- Dos comandantes: alcance +15% o velocidad +20%.
- Fragatas, cruceros y porta-lanzas con alcance, casco, velocidad y daño diferentes.
- Refuerzos con coste y capacidad máxima; suministros consumidos por salto.
- Batalla con 30 naves iniciales, modelos procedurales 3D, formaciones,
  etiquetas de escuadra, selección, rayos de armas y destellos de destrucción.
- Simulación determinista a 10 Hz, daño simultáneo, alcance y orientación.
- Protección del convoy: sobrevivir 120 s o eliminar al enemigo.
- Interdicción: eliminar al enemigo; retirada por límite de 300 s.
- Retirada voluntaria con confirmación; resultados y bajas persistentes.
- Tesoro y apoyo civil afectados por el desenlace y las bajas.
- Guardado/carga de un slot, versión de esquema y validación antes de aplicar.
  No guarda batallas en curso. Reiniciar requiere confirmación.

## Controles

| Contexto | Control |
| --- | --- |
| Mapa | Clic en sistema: inspeccionar; rueda: zoom; arrastre central: desplazar |
| Batalla | Clic o 1/2/3: seleccionar escuadra propia |
| Órdenes | Clic derecho en espacio: mover; en escuadra enemiga: atacar |
| Tiempo | Espacio o botón: pausa; botones ×1/×2/×4: velocidad |
| Mantener posición | H o botón; sigue disparando si hay objetivos a alcance |
| Cámara | Botón central: órbita; rueda: zoom; WASD: desplazar; F: centrar |
| Fuego conjunto | Botón: las tres escuadras atacan el primer grupo enemigo vivo |

## Clean code y separación de responsabilidades

- `domain/operation.gd`: estados de misión, costes y consecuencias; sin escenas/disco.
- `domain/tactical_battle.gd`: simulación táctica y órdenes; sin renderizado.
- `infrastructure/operation_store.gd`: serialización y reemplazo mediante fichero temporal.
- `presentation/deck_theme.gd`: colores, tipografía, superficies y componentes reutilizables.
- `presentation/sector_map.gd`: cartografía e interacción de cámara.
- `presentation/ship_visual.gd`: modelos originales construidos con mallas.
- `presentation/battle_view.gd`: adaptación de la simulación al escenario 3D y controles.
- `presentation/main.gd`: composición de pantallas y conexión de la misión.
- `tests/`: pruebas de reglas, persistencia, ciclo de escenas y límites del layout.

El prototipo estratégico 0.1 se conserva en sus módulos originales y sus pruebas,
pero ya no es la pantalla principal. No hay autoloads ni dependencias externas.
El dominio usa RefCounted y GDScript; las entidades tácticas son diccionarios internos.

## Verificación

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/operation_tests.gd
godot --headless --path . --script tests/layout_smoke.gd
godot --path . --script tests/scene_smoke.gd
godot --path . --script tests/visual_capture.gd
```

Los dos últimos comandos deben usar un renderizador real. En Linux CI se ejecutan
con Xvfb y OpenGL por software. `visual_capture.gd` genera cuatro PNG reales del
motor en `build/screenshots/`. GitHub Actions los adjunta como artefacto.
El éxito de generar capturas no sustituye una revisión visual humana.

## Límites de esta entrega

- Una misión cerrada, no campaña libre ni diplomacia/parlamento completos.
- El convoy es un objetivo temporizado, no una nave civil simulada y atacable.
- La simulación agrupa el casco y daño por escuadra; las naves son representación
  del número superviviente, sin colisiones ni rutas individuales.
- Maniobras sobre plano XZ dentro de un escenario 3D, no navegación libre en seis ejes.
- IA táctica de aproximación al enemigo más cercano; sin planificación avanzada.
- Efectos básicos y modelos originales de prototipo; sin música, audio ni retratos.
- Balance preliminar; sin multijugador ni ejecutables exportados.

Próximo hito: revisar las capturas y probar controles en un PC, mejorar el arte
de naves/efectos y el balance, después ampliar logística y campaña persistente.

No contiene nombres, guiones, imágenes ni música de LOGH. No se ha elegido una
licencia de distribución del código; no confundir la licencia MIT de Godot con
la del juego.
