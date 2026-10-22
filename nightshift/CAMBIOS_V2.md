# Cambios de la versión 2 — qué reemplazar y cómo funciona

## 1. Qué archivos reemplazar

Todos están dentro de `scripts/`. **No cambian** `project.godot`, las escenas (`.tscn`), `energy_system.gd`, `map.gd`, `cam_state.gd`, `office_view.gd`, `jumpscare_view.gd`, `cornelius.gd`, ni el shader.

| Archivo | Ruta en el proyecto | Acción |
|---|---|---|
| `balance.gd` | `scripts/balance.gd` | Reemplazar |
| `night.gd` | `scripts/night.gd` | Reemplazar |
| `hud.gd` | `scripts/hud.gd` | Reemplazar |
| `camera_view.gd` | `scripts/camera_view.gd` | Reemplazar |
| `figures.gd` | `scripts/figures.gd` | Reemplazar |
| `ui_util.gd` | `scripts/ui_util.gd` | Reemplazar |
| `main_menu.gd` | `scripts/main_menu.gd` | Reemplazar |
| `game_state.gd` | `scripts/game_state.gd` | Reemplazar |
| `sound_bank.gd` | `scripts/sound_bank.gd` | Reemplazar |
| `result.gd` | `scripts/result.gd` | Reemplazar |
| `pause_menu.gd` | `scripts/pause_menu.gd` | Reemplazar |
| `botones.gd` | `scripts/monsters/botones.gd` | Reemplazar |
| `chef.gd` | `scripts/monsters/chef.gd` | Reemplazar |
| `mucama.gd` | `scripts/monsters/mucama.gd` | Reemplazar |
| `bailarina.gd` | `scripts/monsters/bailarina.gd` | **Archivo nuevo** (copiarlo a esa carpeta) |
| `GUIA_DEL_JUEGO.md` | donde tengas la guía / `docs/` | Reemplazar (ya dice 12 s y todo lo nuevo) |

Pasos: cierra Godot, copia los archivos, abre el proyecto y espera a que reimporte. Si Godot marca un error rojo, casi siempre es que falta algún archivo de la lista (se necesitan **todos juntos**, porque se llaman entre sí).

---

## 2. Qué se hizo con cada petición

**Flash e intercom gastaban mucho / que no gaste tanta energía** → `balance.gd` (arriba del todo):

| Concepto | Antes | Ahora |
|---|---|---|
| Flash | 1.5 % | 0.7 % (el "abuso" sube 25 % por uso, antes 60 %) |
| Intercom (la música del Chef) | 2.5 % | 1.2 % |
| Reja cerrada (por segundo) | 0.22 % | 0.15 % |
| Monitor (por segundo) | 0.06 % | 0.045 % |
| Caldera | 3.0 % | 2.0 % |
| Corto circuito de Cornelius | 2.0 % | 1.5 % |

**Canción del Chef 12 s** → `INTERCOM_DURATION = 12.0` en `balance.gd`, y la guía y la pantalla de controles ya lo dicen.

**Cajita de música** → ver sección 3.

**Sonido en todo** → ver sección 4.

**Probabilidades y tiempos / si no miras las cámaras cambia cómo se mueven** → ver sección 5.

**Modelos mejor diseñados** → `figures.gd`: cada monstruo se redibujó con sombreado, siluetas propias (gorra cuadrada del Botones, gorro alto y cuchilla del Chef, cofia y plumero de la Mucama, sombrero de copa y monóculo de Cornelius) y caras más detalladas para el jumpscare. Se agregó la Bailarina. Siguen siendo dibujos por código: si después alguien hace arte real en imágenes, se reemplazan solo estas funciones.

**Portada, Jugar, Controles, Configuración y "Nuevo juego"** → ver sección 6.

**Ocultar el modo depuración** → ver sección 7.

---

## 3. La Cajita de Música (cómo está hecha)

Idea: una tarea de mantenimiento en cámaras. Tienes que **ir a mirar la Cam 01** cada cierto tiempo, y eso compite con vigilar a los demás monstruos.

Son tres piezas:

1. **Estado en `night.gd`.** Una variable `box_charge` (de 1.0 = llena a 0.0 = parada). En `_update_box()` baja sola: `box_charge -= delta / box_seconds`, donde `box_seconds` sale de `balance.gd` (50 s en la Noche 2 … 38 s en la Noche 5, clave `"box"`). La función `do_wind()` la devuelve a 1.0, cobra 0.5 % de energía y solo funciona si el monitor está arriba **y** la cámara actual es la 01.
2. **La Bailarina, `monsters/bailarina.gd`.** Es un monstruo más (extiende `monster.gd`). Cada frame mira `game.box_charge`. Si es 0, suma tiempo a `wake`; cuando `wake` llega a `grace` (14 s en la Noche 2, 11 s en la 5) lanza el jumpscare. Si hay cuerda, `wake` baja 3 veces más rápido. No se mueve, y en el apagón no actúa (ya te atrapan los demás).
3. **Lo que ve y oye el jugador.**
   - `hud.gd`: medidor "CAJITA" siempre visible (parpadea en rojo bajo 25 %) y el botón CUERDA [R], que solo aparece mirando la Cam 01.
   - `camera_view.gd`: función `_music_box()`, dibuja el pedestal, la manivela que gira y a la Bailarina asomándose según `awake_amount()`.
   - Sonido: la melodía (`"musicbox"`) suena en bucle; `set_loop()` baja su tono y velocidad cuando queda poca cuerda (te avisa aunque estés en la oficina). Al pararse suena `"box_stop"`.

Consecuencia extra: con la caja parada, `risk_mult()` suma `BOX_EMPTY_RISK` (+50 %) y los monstruos avanzan más rápido.

Ajustes: `charge` y `grace` por noche en `NIGHTS`, y `COST_WIND`, `BOX_EMPTY_RISK` arriba de `balance.gd`.

---

## 4. Sonido

Todo sigue sintetizado en `sound_bank.gd` (no hay archivos de audio). Nuevos sonidos: pasar el ratón y clic en los menús, campanilla de recepción (al empezar la noche y cada hora), aviso de batería baja (20 %), crujido, manivela, caja de música (y su versión que se detiene), ambiente de fondo, pasos de Botones y Chef, jingle de victoria y de derrota, y **música de menú** (jazz lento). El volumen general se controla desde Configuración.

Para usar un sonido real en el futuro: en `_build()` devuelve un `AudioStream` cargado de un `.ogg` en lugar del sintetizado, con el mismo nombre.

---

## 5. Probabilidades y tiempos (revisión)

Lo que es aleatorio en el juego, y lo que no:

| Qué | Cómo se decide |
|---|---|
| Por qué reja llega el Botones | 50 % / 50 % |
| Por qué reja llega el Chef | 50 % / 50 % … **salvo** si llevas más de 18 s sin mirar las cámaras: elige la reja abierta |
| Cuándo sale la Mucama | al azar entre `idle_min` y `idle_max` de la noche |
| Dónde se oculta Cornelius | al azar entre las cámaras oscuras que sigan con señal |
| Cuánto tarda en actuar Cornelius | al azar entre `hide_min` y `hide_max` |
| Todo lo demás | determinista (temporizadores) |

**Regla nueva de "descuido"** (`night.gd`, `_update_unwatched()`): `unwatched_t` cuenta los segundos con el monitor abajo. Al pasar 18 s (`UNWATCHED_THRESHOLD`) suena un crujido y los monstruos se vuelven audaces (+25 % de velocidad, `UNWATCHED_RISK`). Todos los avances usan `game.risk_mult()`, así que esa sola función suma: cámaras ciegas de Cornelius + caja parada + descuido. En cuanto subes el monitor se resetea.

**Pruebas automáticas** (bot, 6 estilos × 5 noches × 4 partidas = 120 partidas): el jugador eficiente gana todas; el descuidado en la Noche 5 gana 2 de 4; quien nunca le da cuerda a la caja pierde siempre (~64 s). Detalle en la guía, sección 7.

---

## 6. Portada, Jugar, Controles, Configuración

Todo vive en **`main_menu.gd`**, que ahora maneja cuatro "páginas" dentro de la misma escena (por eso no hay que tocar `main_menu.tscn` ni `project.godot`):

- `_build_title()` → portada con logo y los cuatro personajes en silueta.
- `_build_play()` → **Nuevo juego** (pide confirmación si ya tenías progreso, y borra el avance con `GameState.reset_progress()`), **Continuar** y las 5 noches con su descripción.
- `_build_controls()` → teclas en recuadros.
- `_build_settings()` → volumen, pantalla completa y efecto CRT; se guarda en `save.cfg` mediante `game_state.gd`.

`ui_util.gd` trae los ayudantes nuevos: fondo animado con rayos y polvo, esquinas Art Deco, separadores, logo, fuente decorativa (usa Copperplate/Georgia si el equipo la tiene) y `menu_button()` (con sonido). Los menús de pausa y resultado usan lo mismo; en la derrota aparece el monstruo que te atrapó.

---

## 7. Cómo ocultar el modo depuración

Qué es: en `night.gd`, las teclas **F1** (ver estados de los monstruos), **F2** (+30 s), **F3** (batería llena) y **F4** (batería casi a 0), útiles para probar rápido.

**Ya viene oculto.** En `scripts/balance.gd` hay una línea:

```gdscript
const DEBUG_KEYS: bool = false
```

- `false` → las teclas F1–F4 no hacen nada y el panel verde nunca aparece (versión para entregar).
- `true` → vuelven a funcionar (para que ustedes prueben).

Cómo funciona: en `_input()` de `night.gd` cada tecla F empieza con `if Balance.DEBUG_KEYS:`. Si es falso, no ejecuta nada. Además se quitó el texto "DEPURACIÓN" de la pantalla de controles, así que el jugador ni se entera.

Si más adelante quieren que **desaparezca el código** y no solo se apague: borren los cuatro bloques `KEY_F1`…`KEY_F4` al final de `_input()` en `night.gd`, la variable `debug_on`, el bloque `if debug_on:` de `_update_hud()` y el `debug_label` de `hud.gd`. No es necesario para entregar.
