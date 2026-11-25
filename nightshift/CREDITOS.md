# Créditos de assets externos

Datos sacados de los metadatos que Sketchfab guarda dentro de cada `.glb` (`asset.extras`).

| Archivo | Modelo | Autor | Licencia |
|---|---|---|---|
| `assets/3d/office/desk.glb` | [Vintage Wooden Workdesk](https://sketchfab.com/3d-models/vintage-wooden-workdesk-f1eddff773a740b78110610cef248093) | [Poring](https://sketchfab.com/poring) | [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/) |
| `assets/3d/office/lamp.glb` | [Banker's Lamp (Luminária de Mesa)](https://sketchfab.com/3d-models/bankers-lamp-luminaria-de-mesa-8bf915a5bbaf48feab4397cffba75df1) | [ArthurBoni](https://sketchfab.com/ArthurBoni) | [CC BY-NC 4.0](http://creativecommons.org/licenses/by-nc/4.0/) (solo uso no comercial) |
| `assets/3d/office/chair.glb` | [Old leather office chair](https://sketchfab.com/3d-models/old-leather-office-chair-5f2076e080cd48a583ee66f0ccb52b88) | [Timothy Ahene](https://sketchfab.com/timothyahene) | [Sketchfab Standard](https://sketchfab.com/licenses) |
| `assets/3d/office/monitor.glb` | [CRT-TV](https://sketchfab.com/3d-models/crt-tv-5f827ab96d184431a0179ceb7c463157) | [SketchyBot](https://sketchfab.com/SketchyB0t_3D_Fabrication) | [Sketchfab Standard](https://sketchfab.com/licenses) |

Los archivos `desk_*.png`, `chair_*.jpg/png` y `lamp_*.png` son las texturas que Godot extrajo de esos `.glb`: tienen la misma licencia que su modelo.

## Lo que hay que tener en cuenta

- **CC BY**: se puede usar dando crédito al autor. Esta página cuenta como crédito; si el juego tiene pantalla de créditos, conviene ponerlo también ahí.
- **CC BY-NC**: igual que CC BY, pero **no se puede usar en un juego que se venda**. Para un proyecto escolar no hay problema.
- **Sketchfab Standard**: se puede usar dentro del juego, pero la licencia **no permite redistribuir el archivo del modelo tal cual**. Como el repositorio de GitHub es público, subir `chair.glb` y `monitor.glb` (y sus texturas) a una rama pública podría contar como redistribución. Opciones: hacer el repositorio privado, o no subir esos archivos (añadirlos a `.gitignore` y pasarlos entre el equipo por otro medio), o cambiarlos por modelos CC0 / CC BY.

(No somos abogados: ante la duda, revisen el texto de cada licencia en los enlaces.)

## Assets propios

- Monstruos 3D (`scenes/3d/monsters/*_3d.tscn`): hechos para este proyecto con primitivas de Godot (ver `MODELOS_3D.md`).
- Arte 2D, sonido y música: generados por código (`figures.gd`, `sound_bank.gd`).
