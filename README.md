# Las Guerras del Meridiano

Prototipo 0.1 de estrategia espacial original en Godot 4 / GDScript.
Repositorio Git independiente. No contiene material de LOGH ni depende de Python.

## Ejecutar

1. Instalar Godot 4.3 o posterior (edición estándar, no necesita .NET).
2. Importar `project.godot` desde el gestor de proyectos.
3. Pulsar F6 en `presentation/main.tscn` o F5 para iniciar el proyecto.

Selecciona una flota de Veyra en el desplegable y pulsa un sistema adyacente.
Las líneas doradas son órdenes pendientes, reemplazables hasta resolver turno.
Puedes reforzar flotas por 10 créditos o cancelar todas las órdenes.
La Liga emite sus órdenes antes de resolver los movimientos simultáneos.
Ganas al eliminar sus flotas; perder ambas fuerzas produce un empate.
Nueva campaña reinicia inmediatamente el prototipo.

## Pruebas

```sh
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 10
```

El ejecutable puede llamarse `godot4` en algunas instalaciones.
El runner devuelve código 1 si falla cualquier comprobación. No requiere plugins.
Incluye órdenes inválidas, sustitución de órdenes, economía, combate simultáneo,
eliminación, empate, bloqueo al finalizar y simulación de 20 turnos.

## Arquitectura y clean code

| Capa | Responsabilidad |
| --- | --- |
| `domain/` | Estado de campaña, resolución de combate y planificación de IA |
| `application/` | Casos de uso y validación de acciones |
| `infrastructure/` | Construcción del escenario inicial |
| `presentation/` | Mapa, entradas y composición de dependencias |
| `tests/` | Pruebas sin interfaz y sin dependencias externas |

La simulación usa objetos RefCounted, no escenas ni autoloads; el servicio recibe
sus dependencias por constructor. La interfaz no decide reglas de combate.
Constantes nombradas, métodos con una responsabilidad, sin servicios globales.
Las colecciones de entidades son diccionarios internos en este primer corte;
convertirlas a modelos tipados antes de añadir persistencia y escenarios externos.
No se introduce una interfaz/abstracción sin una necesidad concreta.

Referencia técnica: [RefCounted en Godot](https://docs.godotengine.org/en/stable/classes/class_refcounted.html).

## Alcance y límites explícitos

- 12 sistemas, dos facciones activas, mundos neutrales y cuatro flotas.
- Grafo 2D, turnos, ingresos, refuerzos, captura y combate automático determinista.
- Reabastecimiento local inmediato tras captura: todavía no hay líneas logísticas.
- Las flotas que cruzan una ruta en sentidos opuestos no se interceptan.
- IA de expansión por distancia, sin refuerzos, evaluación militar ni niebla de guerra.
- Combate agregado 1:1, sin clases de nave, comandantes ni tácticas aún.
- Sin guardado/carga, política, narrativa ramificada, sonido, multijugador ni exportaciones.
- No hay dependencias de terceros ni assets descargados. Nombres provisionales.

## Próximos hitos

1. Ejecutar y revisar visualmente en Godot; equilibrar bucle de 10 turnos.
2. Modelos tipados y guardado versionado con validación y escritura atómica.
3. Logística conectada, refuerzos de IA y pruebas de victoria/derrota.
4. Comandantes, apoyo político y una decisión con consecuencias por turno.
5. Batalla táctica 2D compartiendo el mismo contrato de resultados.

No se ha elegido licencia de distribución del código ni publicado el juego.
Mantener activos, personajes, música y guiones propios y registrar su procedencia.
