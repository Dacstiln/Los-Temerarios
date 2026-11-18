# Bitacora de Diseno y Pruebas - Mateo

## Revision Cruzada con Diego (GDD Sesion 2)
- Evaluacion de la mecanica de Sobrecargo de Caldera: confirmacion de que solo afecta conductos.
- Ajuste al Flash de Camara para evitar abusos de consumo.
- Propuesta de mitigacion de accesibilidad auditiva para senales de pasos y jazz.


## Sprint Final - Interfaz de Usuario y Rediseño de Cámaras (Semana 2 y 3)
- **Plano Esquemático de Cámaras (CCTV Blueprint):**
  - Implementación del nuevo layout con plano arquitectónico del hotel en `hud.gd`.
  - Disposición de salas: CAM 01 (Lobby), CAM 02 (Recepción), CAM 03 (Cocina), CAM 04 (Pasillo Este), CAM 05 (Pasillo Oeste), CAM 06 (Calderas), CAM 07 (Conductos) y posición de la Oficina `[YOU]`.
  - Control dual operativo: selección interactiva mediante clic directo con ratón sobre las cajas de cámara y selección rápida con teclado (teclas numéricas superiores 1-7 y teclado numérico Keypad).
  - Retroalimentación visual: luz verde pulsante en `[YOU]` e indicador rojo REC parpadeante sobre la cámara activa.
- **Etiquetas Guía Difuminadas en HUD:**
  - Sustitución de los botones de acción (`FLASH`, `INTERCOM`, `CALDERA`, `CUERDA`) por componentes `ActionGuide` no interactivos (`mouse_filter = MOUSE_FILTER_IGNORE`).
  - Estilo visual tenue y difuminado con bordes translúcidos y teclas de atajo destacadas (`[ F ]`, `[ I ]`, `[ B ]`, `[ R ]`).
  - Estados dinámicos para cooldown (temporizador en Caldera) y modo activo (intercomunicador de Jazz).
- **Rediseño Visual de la Oficina (Fase 1 Arte y Escenarios):**
  - Ambientación Art Déco: zócalos de caoba con molduras biseladas y franjas textiles.
  - Reloj de pared analógico sincronizado en tiempo real con las horas de la noche.
  - Accesorios de época en el escritorio: taza de café de porcelana con vapor animado, bitácora de turnos con sello del hotel y lámpara de banquero con pantalla verde esmeralda.
  - Monitor CRT mejorado con pantalla convexa de fósforo, estática procedural y resplandor sobre el escritorio.
  - Rejas de ascensor estilo acordeón con remaches de tijera, barra de impacto pesada y placas de bronce.
- **Rediseño Visual de los Escenarios de Cámaras (Fase 2 Arte y Escenarios):**
  - Efecto CCTV: Viñeta de lente de seguridad convexa y sombreado perimetral en todas las cámaras.
  - CAM 01 (Lobby): Alfombra de diamantes dorados, columnas de mármol negro con estrías doradas y candelabro de cristal.
  - CAM 02 (Recepción): Casillero de llaves con borlas rojas, mostrador de caoba con mármol verde, timbre de conserje y teléfono de época.
  - CAM 03 (Cocina): Suelo de damero ajedrezado, azulejos sanitarios, mesa de acero inoxidable y altavoz de jazz con ondas sonoras.
  - CAM 04 y 05 (Pasillos): Perspectiva profunda, alfombra central, puertas de habitaciones numeradas y apliques de pared en antorcha.
  - CAM 06 (Calderas): Caldera monumental de hierro con remaches, portezuela con fuego y brasas animadas, manómetro de presión y tuberías con válvulas.
  - CAM 07 (Conductos): Túnel de chapa galvanizada en perspectiva forzada con remaches y marcas de arrastre.
- **Rediseño Visual de los Monstruos y Siluetas (Fase 3 Arte y Escenarios):**
  - Implementación de sombreado volumétrico anatómico y claroscuro en `figures.gd`.
  - Halos espectrales luminosos en los ojos de todos los monstruos para una visibilidad tétrica en penumbra y tras las rejas.
  - El Botones: Uniforme de gala con charreteras militares, botones con relieve y sonrisa cosida con puntadas negras.
  - El Chef: Silueta corpulenta, manchas de sangre detalladas en el delantal y cuchilla de carnicero de acero con filo resplandeciente.
  - La Mucama: Vestido victoriano con pliegues en cascada, ojos espectrales ciegos con lágrimas oscuras y plumero antiguo.
  - Cornelius: Levita con faldones en pico, bastón con empuñadura dorada, monóculo brillante y reloj de bolsillo de oro con destello.
  - La Bailarina: Muñeca de porcelana agrietada con tutú geométrico de pétalos y ojos rubí.
  - Jumpscares (`draw_face`): Rostros en primer plano enriquecidos con cuencas profundas, fauces abiertas y colmillos sombreados en 3D.
- **Ambientación Sonora y Música de Tensión:**
  - **Música de Tensión Procedural (`tension`):** Síntesis de dark ambient drone en `sound_bank.gd` (sub-graves a 40/55 Hz con pulso LFO sordo de 2 s, tritono disonante en 77.75 Hz / 155.5 Hz con respiración armónica de 8 s, y rumor subterráneo con crossfade fino en bucle continuo).
  - **Dinamismo y Escalamiento en Tiempo Real (`night.gd`):** Volumen y tono de la tensión escalan de forma continua de 12:00 AM (-26 dB) a 5:00 AM (-16 dB). Se intensifican dinámicamente si hay amenazas inmediatas en las rejas (+4.5 dB), si la caja de música está baja (+3.0 dB) o ante negligencia prolongada.
  - **Crujidos y Sonidos Vivos del Edificio:** Temporizador estocástico (intervalo de 13 a 26 segundos) que reproduce crujidos de madera vieja (`creak`), quejidos de vigas/tuberías pesadas (`groan`) y ráfagas distantes de viento (`wind`).
  - **Diferenciación Acústica de la Oficina:** Atenuación del zumbido de sala de guardia al subir el monitor CRT y chasquido analógico de apertura/cierre de monitor (`ui`).
  - **Corte Sepulcral en Apagón:** Detención instantánea de zumbidos eléctricos y música de tensión ante descarga total de batería, dejando un silencio aterrador.

## Migración a Entorno 3D y Modelos Reales (Sprint Final - Rama 3D)
- **Oficina 3D Interactiva y Modelos Reales (`office_3d.tscn`):**
  - Implementación de paneo de cámara horizontal suave controlado por mouse (-58° a +58°) imitando la perspectiva del guardia en FNAF.
  - Integración y calibración de assets 3D reales descargados de Sketchfab: escritorio victoriano (`desk.glb`), lámpara de banquero esmeralda (`lamp.glb`), monitor CRT retro (`monitor.glb`) y sillón de guardia (`chair.glb`).
  - Rejas mecánicas 3D animadas con respuesta a teclas `A` y `D`.
  - Mecánica de iluminación de puertas (teclas `Q` para puerta izquierda y `E` para puerta derecha): pasillos exteriores permanecen en penumbra profunda para ocultar amenazas hasta encender el foco halógeno.
  - Iluminación equilibrada: lámpara de escritorio tenue, resplandor de fósforo azul CRT en la mesa y luz cenital cálida de la oficina.
- **Sistema Multicámara 3D (CCTV para 7 salas):**
  - Creación de dioramas 3D independientes para las 7 salas del hotel en `cctv_3d.tscn`.
  - Cámara de seguridad fija por sala con paneo lento automático (-3° a +3°) y preservación del shader CRT analógico.
  - CAM 01 (Lobby con columnas de mármol y pedestal de caja de música), CAM 02 (Recepción con mostrador y timbre), CAM 03 (Cocina con azulejos y altavoz de jazz), CAM 04 y 05 (Pasillos oscuros iluminables con Flash `F`), CAM 06 (Calderas con fuego activo y sobrecargo `B`), CAM 07 (Túnel de ventilación galvanizado).
  - Estado de "SIN SEÑAL" automático para cámaras saboteadas por Cornelius.
