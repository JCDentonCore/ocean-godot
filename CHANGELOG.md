# Changelog — Ocean Godot

Proyecto Godot 4.7.2 (Forward+) de un mar básico con peces low-poly, burbujas y cámara libre.
Hardware: AMD Radeon RX 7900 XT (RADV NAVI31), Vulkan 1.4.354, CachyOS Linux (Wayland).

## [0.2.0] — 2026-09-08

### Added
- **Export a binario Linux x86_64** (`build/ocean-godot.x86_64`, ~71 MB, PCK
  embebido). Funciona en Debian, CachyOS/Arch y cualquier Linux x86_64 con
  Mesa/Vulkan. Distribuido como GitHub Release.
- **Cámara libre** (WASD/flechas para moverse, ratón botón derecho para rotar,
  Space/C para subir/bajar, Shift para velocidad rápida).
- **F12**: captura de pantalla manual, guardada en
  `~/.local/share/godot/app_userdata/Ocean Godot/ocean_screenshot.png`.
- **Esc**: cierra la aplicación.
- `scenes/verify.tscn` + `scripts/verify_frame.gd` (fuera del repo): escena de
  verificación headless que analiza píxeles de la viewport en memoria y confirma
  el render del océano, los peces y el fondo marino.

### Changed
- `scripts/main.gd`:
  - Se eliminó la captura automática de pantalla en el frame 60.
  - Se eliminó la salida automática en el frame 240.
  - `_unhandled_key_input` se fusionó en `_unhandled_input` (Godot 4.7 exige la
    firma `_unhandled_input(InputEvent) -> void`).
  - Nueva función `_update_camera(delta)` que aplica la rotación yaw/pitch y el
    desplazamiento basado en la entrada.
- `project.godot`: se eliminó `run/auto_quit=true` (no era un setting válido).

### Fixed
- Errores de parseo del script de verificación (`Vector3` no tiene `.x`/`.y`/`.z`
  como propiedades individuales accesibles por nombre en GDScript; se usaron los
  índices `[0]`, `[1]`, `[2]` y se eliminaron funciones undefined).

### Export de Windows
- El binario Windows (`ocean-godot-windows-x64.exe` + `.pck`) se exportó
  abriendo el editor de Godot (`godot --editor`) y creando el preset desde
  Project → Export, ya que esta build no acepta presets escritos a mano en modo
  `--headless`. El PCK va separado (no embebido); copiar ambos archivos juntos.

### Notas de verificación (headless, in-engine)
- `Image.save_png()` y `--write-movie` producen imágenes negras en esta build de
  Godot (4.7.2 Arch) en este hardware. El buffer en memoria es correcto; la
  verificación se hizo leyendo píxeles directamente de la viewport.
- Análisis de 1280×720 a los 5 s de runtime:
  - ~49.069 píxeles azules (océano), color medio ≈ (0.28, 0.40, 0.57).
  - 48 píxeles naranjas detectados (escuela de peces visible en el frame).
  - Fondo marino visible: color medio ≈ (0.80, 0.77, 0.56).
- Veredicto: el render está bien.

## [0.1.0] — 2026-09-07

### Added
- Primer esqueleto del proyecto Godot 4.7:
  - `project.godot` con renderer Forward+ y viewport 1280×720.
  - `scenes/main.tscn` (escena principal).
  - `scripts/main.gd` con:
    - Océano procedural de 24×24 tiles (48×48 vértices) con animación de olas
      senoidales.
    - Fondo marino (sea floor) procedural.
    - 110 peces low-poly (mesh generado a mano) con movimiento de escuela.
    - 90 burbujas ascendentes.
    - Cámara y luces (DirectionalLight3D + Environment con color de fondo azul).
  - Modo demo automático: screenshot en frame 60, salida en frame 240
    (eliminado en 0.2.0).

## Estructura del proyecto

```
ocean-godot/
├── project.godot
├── CHANGELOG.md
├── scenes/
│   └── main.tscn          # Escena principal (Node3D con scripts/main.gd)
├── scripts/
│   └── main.gd            # Lógica: océano, peces, burbujas, cámara, input
└── screenshot.png         # (obsoleto, de la demo automática de 0.1.0)
```

## Controles

| Tecla / ratón | Acción |
|---|---|
| W A S D / flechas | Mover la cámara |
| Ratón (botón derecho + arrastrar) | Rotar la cámara (yaw/pitch) |
| Space / C | Subir / bajar |
| Shift | Movimiento rápido |
| F12 | Screenshot manual |
| Esc | Cerrar |

## Cómo ejecutar

```bash
cd /home/jcgolinux/.openclaw/workspace/ocean-godot && godot
```

## Roadmap / próximas ideas (sin confirmar)

- [ ] Material de agua más rico (specular, fresnel, refraction).
- [ ] Nado de peces con steering (boids) en lugar de movimiento lineal.
- [ ] Partículas de luz (god rays) bajo el agua.
- [ ] Screenshot con `--write-movie` o captura vía API cuando la build lo
      soporte sin el bug de PNG negro.
- [ ] Exportar a Linux standalone para probar fuera del editor.
