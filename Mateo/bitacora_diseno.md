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
