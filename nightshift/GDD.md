# Implementación del GDD v1 en Godot 4.3 (GDScript)

**Mecánicas:**
- Energía compartida como recurso central; a 0% ocurre el Apagón (derrota).
- Rejas de ascensor, monitor con 7 cámaras, Flash de cámara, Intercomunicador y Sobrecargo de Caldera.

**Amenazas, cada una con su contramedida:**
- El Botones: rejas.
- El Chef: rejas o señuelo con el Intercomunicador.
- La Mucama: Sobrecargo de Caldera.
- Cornelius (noches 4-5): bajar el monitor al oír el reloj o expulsarlo con Flash.

**Estructura:**
- 5 noches. El MVP del GDD son las noches 1-3; las 4 y 5 agregan a Cornelius.
- Arte y sonido procedurales, sin archivos externos; shader CRT.
- Todo el balance está en `scripts/balance.gd`.

**Pruebas:**
- Simulación automática de las 5 noches con un bot, con ajustes de balance en las noches 4 y 5.