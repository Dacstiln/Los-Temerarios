# Guía del juego — Night Shift at The Grand Tenebris

Esta guía explica cómo se juega, cómo funciona cada mecánica por dentro y dónde cambiar cada número. Todo lo que dice está tomado del código del proyecto (Godot 4.3, GDScript).

---

## 1. Cómo abrirlo y jugarlo

1. Instala **Godot 4.3** (la versión estándar, no la de .NET).
2. En Godot: **Importar → elegir `project.godot`**. La primera vez tarda unos segundos en importar.
3. Presiona **F5** (o el botón de play). Abre la **portada**.

La portada tiene **Jugar**, **Configuración**, **Controles** y **Salir**. En **Jugar** eliges **Nuevo juego** (borra el progreso y empieza en la Noche 1, con confirmación si ya tenías avance), **Continuar** o una noche concreta de las que ya desbloqueaste. En **Configuración** ajustas el volumen, la pantalla completa y el efecto de monitor viejo (CRT).

El progreso y la configuración se guardan solos.

### Controles

| Tecla | Acción |
|---|---|
| **A / D** | Cerrar o abrir la reja izquierda / derecha |
| **ESPACIO** | Subir o bajar el monitor de cámaras |
| **1 – 7** | Cambiar de cámara (con el monitor arriba) |
| **F** | Flash de cámara (solo en cámaras oscuras) |
| **I** | Intercomunicador: pone jazz 12 segundos en la cámara seleccionada (desde la Noche 2) |
| **B** | Sobrecargo de Caldera (desde la Noche 3) |
| **R** | Dar cuerda a la Cajita de Música (mirando la Cam 01; desde la Noche 2) |
| **ESC** | Pausa |

El modo depuración (F1 a F4) está **desactivado** en esta versión. Para volver a usarlo: `DEBUG_KEYS = true` en `scripts/balance.gd` (ver `CAMBIOS_V2.md`).

También se puede hacer todo con el mouse (botones en pantalla).

---

## 2. La idea en una frase

Eres **Leo**, guardia nocturno de un hotel embrujado. Debes sobrevivir de las **12:00 AM a las 6:00 AM**. Cada monstruo exige una **contramedida distinta**, y todas gastan la **misma batería**. No existe una defensa que sirva contra todo.

Una noche dura **6 minutos reales** (360 s): cada hora del juego son 60 segundos.

---

## 3. Energía (el recurso central)

La batería empieza en 100%. Todo lo que haces la gasta:

**Gasto continuo (por segundo)**

| Qué | Gasto |
|---|---|
| Oficina (siempre) | 0.02 % |
| Monitor arriba | +0.045 % |
| Cada reja cerrada | +0.15 % |

**Gasto por uso**

| Acción | Costo |
|---|---|
| Sobrecargo de Caldera | 2.0 % |
| Intercomunicador | 1.2 % |
| Flash de cámara | 0.7 % (sube 25 % por cada uso reciente: "alto si se abusa") |
| Dar cuerda a la Cajita de Música | 0.5 % |
| Corto circuito de Cornelius | 1.5 % (aunque lo evites) |

Todo se multiplica por el **factor de drenaje de la noche** (ver tabla de noches).

**Si la energía llega a 0 → Apagón (derrota):** las rejas se abren, el monitor se apaga y ningún botón responde. Un monstruo te alcanza en 1.5 a 3 s si ya estaba cerca, o en 4.5 a 8 s si no.

El HUD siempre muestra la energía y la hora (esquinas superiores) y una barra de **CONSUMO** de 5 segmentos que indica cuánto estás gastando ahora mismo.

---

## 4. La oficina y las cámaras

Desde la oficina ves las **dos rejas de ascensor** (izquierda y derecha) y la **rejilla de ventilación**. Aquí es donde aparecen los monstruos cuando llegan. Si subes el monitor ya no ves la oficina, pero sí las cámaras.

| Cámara | Lugar | Notas |
|---|---|---|
| 01 | Lobby Principal | Punto de partida del Botones |
| 02 | Recepción | Cruce hacia los pasillos |
| 03 | Cocina | Hogar del Chef |
| 04 | Pasillo Este | **Oscura**, lleva a la reja derecha |
| 05 | Pasillo Oeste | **Oscura**, lleva a la reja izquierda |
| 06 | Cuarto de Calderas | **Oscura** |
| 07 | Conductos | Visión verde; ruta exclusiva de la Mucama |

Las cámaras **oscuras** (4, 5 y 6) solo se ven mientras dura el **Flash** (1 segundo, enfriamiento de 1.2 s).

---

## 5. Los monstruos y su contramedida

### El Botones — se detiene con las rejas
- **Ruta:** Lobby → Recepción → Pasillo Este u Oeste → reja.
- **Se mueve** cada cierto intervalo (según la noche). Si lo estás **vigilando** en su cámara, avanza a 0.4× de velocidad. Si no lo vigilas, avanza a 1.0× y **va acelerando** hasta 2.5× cuanto más tiempo lo ignoras.
- **Al llegar a la reja** tienes una **ventana de reacción** (de 7 s en la Noche 1 a 4.6 s en la Noche 5) para cerrarla.
- Si la cierras a tiempo, queda **bloqueado** 6 s tras los barrotes y luego se retira. Si abres la reja mientras sigue ahí, regresa a la puerta y solo tienes 2 s.
- Si la ventana se acaba con la reja abierta: **jumpscare**.

### El Chef — rejas, o desviarlo con el intercomunicador
- **Ruta:** Cocina → Recepción → pasillo → reja. Es más ruidoso y agresivo.
- Las **rejas** también lo detienen igual que al Botones.
- **Intercomunicador (I):** pone jazz en la cámara que tengas seleccionada durante **12 s**. El Chef deja lo que hacía y camina hacia esa cámara. Si estaba ya en tu reja, **se da la vuelta y se va**. Cuando la música termina, regresa a la cocina.
- Solo puede sonar jazz en **una cámara a la vez**, y no funciona en la Cam 07.

### La Mucama — solo el Sobrecargo de Caldera la detiene
- Viaja por los **ductos**. **Las rejas no sirven contra ella.**
- Espera un rato en los ductos y luego se **acerca** a la rejilla de tu oficina durante varios segundos. En la **Cam 07** ves su cara crecer conforme se acerca. También se oyen golpes en los ductos y la rejilla se agita.
- Al llegar a la rejilla tienes una ventana de 4 a 4.5 s.
- **Sobrecargo de Caldera (B):** si ella está acercándose o en la rejilla, la **repele** (retrocede y vuelve a los ductos). Si no estaba cerca, se gasta la energía y **no hace nada**.
- Sin contramedida a tiempo: **jumpscare**.

### Cornelius (Noches 4 y 5) — reaccionar rápido
- Cornelius no te persigue por la oficina: **sabotea las cámaras**.
- **Se oculta** en una cámara oscura (4, 5 o 6). Solo lo ves con **Flash** sobre esa cámara, y si no lo ves, a veces aparece un **destello dorado** en la oscuridad que delata dónde está.
- **Flash sobre su cámara → lo revela y lo expulsa.** Ese ataque se cancela.
- Si no lo detectas, cuando **subas el monitor** empieza el **corto circuito**: suena un tic-tac de reloj de bolsillo y la imagen se llena de estática. Tienes **3 segundos (2.6 en la Noche 5) para bajar el monitor**.
  - **Lo bajas a tiempo:** se evita, pero cuesta 2 % de energía y el monitor queda **reiniciándose 4 s (5 s en la Noche 5)**, sin poder usarlo.
  - **No lo bajas a tiempo:** esa cámara queda **ciega el resto de la noche**, las rejas se abren y se **atoran 3 s**, y todos los demás monstruos se aceleran un **8 %** por cada cámara ciega acumulada. No es derrota inmediata, pero se va acumulando.
- Si no tocas el monitor, no hay corto circuito: el riesgo es no ver nada.

### La Bailarina (Noches 2 a 5) — dale cuerda a la Cajita de Música
- Vive en la **Cajita de Música** del Lobby (**Cam 01**). Mientras la caja suena, duerme.
- La cuerda se gasta sola (50 s en la Noche 2, 38 s en la Noche 5). Puedes **oír** la melodía desde la oficina: cuando le queda poca cuerda, **se vuelve lenta y grave**, y el medidor **CAJITA** del HUD parpadea en rojo.
- Para darle cuerda: sube el monitor, ve a la **Cam 01** y presiona **CUERDA [R]** (o el botón en pantalla). Cuesta 0.5 % de energía y llena la cuerda.
- Si la música se **detiene**, la Bailarina despierta: se asoma de la caja y tienes **14 s** (11 s en la Noche 5) para darle cuerda. Si no, **jumpscare**.
- Mientras la caja está parada, **todos los monstruos avanzan un 50 % más rápido**.

### Descuido (todas las noches)
Si pasas **18 segundos seguidos sin subir el monitor**, se oye un crujido y los monstruos se vuelven **audaces**: avanzan un **25 % más rápido**, la Mucama sale antes de los ductos y el Chef **elige la reja que dejaste abierta**. En cuanto subes el monitor, vuelve a la normalidad.

---

## 6. Las 5 noches

El MVP del GDD son las **Noches 1 a 3**: el mismo sistema, solo cambian los parámetros. Las **Noches 4 y 5** agregan a Cornelius.

| Noche | Monstruos | Drenaje | Herramientas nuevas |
|---|---|---|---|
| 1 | Botones | 0.70 | Rejas, monitor |
| 2 | + Chef y Bailarina | 0.85 | Intercomunicador, Cajita de Música |
| 3 | + Mucama | 1.00 | Sobrecargo de Caldera |
| 4 | + Cornelius | 0.95 | (nada nuevo, más amenazas) |
| 5 | Todo más rápido | 0.92 | (nada nuevo) |

Al empezar cada noche aparece una tarjeta con una pista. Ganas cuando el reloj llega a **6:00 AM** sin que nadie te haya alcanzado. Al superar la Noche 3 aparece un aviso de "MVP completado", y la Noche 5 tiene pantalla de final.

### Cómo termina una partida
- **Victoria:** reloj en 6:00 AM.
- **Derrota por Apagón:** energía en 0.
- **Derrota por contramedida incorrecta o tardía:** un monstruo llega y no usaste lo correcto a tiempo.
- La pantalla de derrota te dice **qué te atrapó y cuál era la contramedida**.

Ambas derrotas dependen de una decisión tuya, nunca del azar puro (aunque la ruta de los monstruos tiene parte aleatoria).

---

## 7. Resultados de las pruebas automáticas

Un bot jugó las 5 noches con 6 estilos distintos (atento, lento, sin usar el Flash, descuidado, que mira poco las cámaras y que **nunca** le da cuerda a la caja), 4 partidas por noche y estilo. No sustituye a probarlo con personas:

| Noche | Energía restante (jugador eficiente) | Comentario |
|---|---|---|
| 1 | ~86 % | Relajada |
| 2 | ~72 % | |
| 3 | ~46 % | |
| 4 | ~37 % | |
| 5 | ~33 % | El jugador descuidado pierde la mitad de las veces |

- Quien **no le da cuerda a la caja** pierde siempre, alrededor del segundo 64 (50 s de cuerda + 14 s de margen).
- Con los costos nuevos sobra más batería que antes (en la Noche 5 se terminaba con ~10 % y ahora con ~33 %). La presión viene ahora de la Bailarina, el descuido y los monstruos. Si quieres más tensión, sube `drain` de cada noche en `balance.gd`.

## 8. Dónde está cada cosa

```
project.godot               configuración (escena principal, autoloads)
scenes/
  main_menu.tscn            escena del menú (el contenido lo construye main_menu.gd)
  night.tscn                una noche de juego
  result.tscn               victoria / derrota / final
scripts/
  balance.gd                TODOS los números de balance y las 5 noches
  night.gd                  controlador de la noche (reloj, energía, acciones, victoria/derrota)
  energy_system.gd          batería y apagón
  monsters/
    monster.gd              base de todos (estados, apagón)
    botones.gd  chef.gd  mucama.gd  cornelius.gd  bailarina.gd
  map.gd                    cámaras y rutas
  cam_state.gd              cámara normal o interferida
  camera_view.gd            dibujo del monitor
  office_view.gd            dibujo de la oficina
  figures.gd                dibujo de los 5 monstruos
  hud.gd                    energía, hora, botones
  jumpscare_view.gd         pantalla del susto
  main_menu.gd              portada, Jugar, Controles y Configuración
  result.gd  pause_menu.gd  ui_util.gd
  game_state.gd             progreso y configuración guardados (autoload)
  sound_bank.gd             sonidos sintetizados por código (autoload)
shaders/crt.gdshader        efecto de monitor CRT
```

**Todo el arte, el sonido y la música se generan por código**: no hay imágenes ni archivos de audio. Son *placeholders* funcionales, pensados para reemplazarse.

### Cambios comunes
- **Dificultad de una noche:** `scripts/balance.gd`, bloque `NIGHTS`.
- **Qué cuesta cada acción:** constantes al inicio de `balance.gd`.
- **Duración de la noche:** `NIGHT_DURATION` en `balance.gd` (360 = 6 minutos).
- **Agregar un monstruo:** crear un script en `monsters/` que extienda `monster.gd` y registrarlo en `_build_monsters()` de `night.gd`.

---

## 9. Qué es del GDD, qué es ampliación y qué conviene revisar

**Del GDD:** energía compartida, 7 cámaras, rejas, Flash, Intercomunicador, Sobrecargo, 3 noches del MVP, máquinas de estado discretas, condiciones de derrota y la regla de que ninguna defensa sirve para todo.

**Ampliación (posterior al MVP, el GDD la marca como "fuera del MVP"):** Cornelius, la mecánica de Interferencia y las Noches 4 y 5.

**Decisiones que tomé y que el GDD no dice** (revísalas y dime si las quieres distintas):
1. Un corto circuito cuesta 2 % de energía y reinicia el monitor unos segundos. Sin eso, ignorar a Cornelius salía gratis y el Flash no servía.
2. Las Noches 4 y 5 gastan un poco menos de batería (0.95 y 0.92) para que sean ganables.
3. "Abre puertas", de la tabla de personajes de Cornelius, lo implementé como rejas que se **atoran** 3 s tras una interferencia.
4. Cornelius solo ataca cuando el monitor está arriba.

**Inconsistencia del propio GDD:** el lore dice que la Mucama es de "oído fino" y que de ahí sale el señuelo de audio, pero la tabla de mecánicas dice que el Intercomunicador atrae al **Chef**. El juego sigue la tabla.

**Límites conocidos:**
- El arte es más trabajado que en la v1 pero sigue siendo procedural (formas dibujadas por código).
- El audio está sintetizado y no lo he escuchado en un equipo real.
- Probé el balance solo con un bot, no con personas.
