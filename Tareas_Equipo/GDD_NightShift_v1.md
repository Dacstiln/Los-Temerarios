# UNIVERSIDAD DE COLIMA

**FACULTAD DE TELEMÁTICA**
**INGENIERÍA DE SOFTWARE**
**VIDEOJUEGOS**

**PRACTICA 1. ENTREGA – GDD V1 (LISTO PARA PRODUCCIÓN)**

**MIGUEL ANGEL RODRIGUEZ ORTIZ**
**ANGEL MATEO DELGADO CORTES**
**CÁRDENAS SÁNCHEZ DIEGO ALEXANDER**

---

# GDD

## NIGHT SHIFT AT THE GRAND TENEBRIS
### Game Design Document v1 — Listo para Producción

---

## Registro de participación del equipo

| Etapa | Actividad realizada | Integrante(s) | Evidencia |
|---|---|---|---|
| Sesión 1 (presencial/síncrona) | Lluvia de ideas del concepto y el setting (hotel "Grand Tenebris", época y ambientación Art Decó); definición conjunta del High Concept y del perfil de jugador. | Mateo y Diego | Minuta de sesión 1 (ver Anexo A) y bocetos iniciales del lore. |
| Sesión 1 | Investigación de referentes del género (survival horror de gestión de recursos) y discusión de qué mecánicas evitar por ser clichés. | Diego | Notas de investigación comparativa (Anexo A). |
| Trabajo independiente | Redacción del Lore, personajes (Botones, Mucama, Chef, Cornelius) y dirección de arte "Art Decó Decadente". | Mateo | Documento de lore entregado en canal del equipo. |
| Trabajo independiente | Diseño del Core Loop, definición del recurso de Energía/Batería y balanceo preliminar de consumo por mecánica. | Diego | Diagrama de flujo del loop y tabla de consumo de energía (Anexo B). |
| Trabajo independiente | Especificación de mecánicas principales (Puertas de ascensor, Intercomunicador, Calefacción de conductos, Flash de cámara, Interferencia de Cornelius). | Mateo y Diego (dividido por mecánica: Mateo — Ascensores e Intercomunicador; Diego — Calefacción, Flash e Interferencia) | Fichas de mecánica individuales. |
| Trabajo independiente | Definición del MVP (alcance de 3 noches), lista de sistemas fuera del MVP y matriz de riesgos. | Diego | Tabla de alcance y matriz de riesgos (Anexo C). |
| Sesión 2 (presencial/síncrona) | Revisión cruzada del documento: Mateo revisó la sección de mecánicas de Diego y viceversa; ajuste de condiciones de victoria/derrota; consolidación final del GDD en Markdown. | Mateo y Diego | Historial de commits en GitHub (ver Anexo A) y acuerdos de sesión 2. |
| Sesión 2 | Exportación final a PDF y verificación de que el documento cumple con el formato de 10 páginas de Level Up! (Level 4). | Mateo | Checklist de entrega. |

---

## Página 1 — High Concept y Visión

### High Concept

"Night Shift at The Grand Tenebris" es un survival horror de gestión de recursos y vigilancia, en el que el jugador —Leo, un estudiante universitario endeudado— trabaja como guardia nocturno en un hotel de lujo de los años 20 abandonado y reabierto en los años 90. Anclado a un escritorio de seguridad, debe usar una red de cámaras deterioradas y un generador de energía moribundo para sobrevivir cinco noches mientras los antiguos empleados del hotel —transformados en entidades sobrenaturales— intentan alcanzarlo.

El gancho del diseño es que cada monstruo exige una contramedida distinta y mutuamente excluyente: no existe una única estrategia ("cerrar puertas y ya"), sino que el jugador debe priorizar qué sistema de defensa activar según la amenaza que identifique, todo bajo la presión de un recurso de energía compartido y limitado.

### Experiencia buscada

Tensión sostenida por gestión de atención dividida (cámaras, audio, energía) más pánico de decisión bajo presión: el miedo no viene solo del jumpscare, sino de la ansiedad de "¿tengo suficiente batería para reaccionar a las próximas dos amenazas?".

### Pilares de diseño

1. **Recursos compartidos, decisiones excluyentes.** Toda acción cuesta energía del mismo generador; no hay recursos infinitos para ninguna mecánica.
2. **Una amenaza, una respuesta específica.** Ningún sistema de defensa sirve para todos los monstruos (a diferencia de FNAF, donde las puertas resuelven casi todo).
3. **Ambientación como sistema, no como decoración.** El estilo Art Decó Decadente y el sonido (jazz, vapor, estática) están ligados directamente a mecánicas (señuelo de audio, visibilidad).

### Perfil de jugador objetivo

Jugador de 15-30 años, aficionado a horror de gestión de recursos (tipo Five Nights at Freddy's, Poppy Playtime, Buckshot Roulette), que busca sesiones cortas (15-30 min por noche) con tensión creciente y rejugabilidad basada en dominar patrones, no en reflejos de acción rápida.

---

## Página 2 — Mundo y Narrativa Funcional

### Lore

En 1929, el Grand Tenebris —el hotel más opulento de la ciudad— fue clausurado tras un incendio provocado por el ritual oculto de su fundador, Cornelius Tenebris, quien buscaba la inmortalidad. Cornelius fusionó las almas de las víctimas con los uniformes, la utilería y las bestias disecadas del hotel antes de morir en el incendio. Seis décadas después, una corporación compra el edificio para restaurarlo y contrata a Leo, un estudiante universitario ahogado en deudas, como guardia nocturno del turno que nadie más quiere. Al caer la medianoche, los antiguos empleados despiertan para asegurar que nadie —huésped o guardia— haga check-out con vida.

### Por qué la narrativa es funcional (no decorativa)

- El incendio de 1929 justifica narrativamente el estado deteriorado de las cámaras (estática, CRT de los 90) y de las puertas (rejas de ascensor en vez de puertas blindadas), que son restricciones de diseño reales del gameplay.
- Cada monstruo tiene un rasgo narrativo que es literalmente su mecánica de combate: la Mucama es ciega pero de oído fino (de ahí el señuelo de audio), el Chef es agresivo por ruido (de ahí el intercomunicador de jazz), Cornelius puede cegar cámaras (de ahí la mecánica de interferencia).
- El motivo de Leo (deuda económica, sueldo doble) explica narrativamente por qué el jugador no huye, resolviendo el típico problema de coherencia de "¿por qué no simplemente me voy?" en el género.

### Personajes

| Personaje | Rol | Rasgo narrativo → mecánica asociada |
|---|---|---|
| Leo | Jugador | Guardia sin defensa física; solo cámaras y sistemas eléctricos. |
| El Botones | Amenaza 1 | Lento pero acelera si no se vigila → exige monitoreo constante de Cam 01. |
| La Mucama | Amenaza 2 | Ciega, oído fino, se mueve por ductos → exige vigilancia de Cam 07 y uso de Calefacción de Conductos. |
| El Chef | Amenaza 3 | Agresivo, ruidoso, sensible al sonido → exige uso del Intercomunicador como señuelo. |
| Cornelius | Jefe final (Noche 4+) | Desactiva cámaras y abre puertas → exige reacción rápida a la mecánica de Interferencia. |

### Dirección de arte

Estilo "Art Decó Decadente": geometría dorada y negra de los años 20 combinada con polvo, escombros de construcción moderna y luz tungsteno cálida que deja rincones en oscuridad total. Todo se observa a través de monitores CRT de los 90 con estática, baja resolución y aberración cromática — refuerzo estético que también oculta limitaciones técnicas reales de producción (menos detalle gráfico necesario).

---

## Página 3 — Escenarios y Red de Cámaras

| Cámara | Escenario | Función de diseño |
|---|---|---|
| Oficina (base) | Escritorio con monitores CRT y dos rejas de ascensor (izq/der) | Zona segura del jugador; punto de todas las decisiones. |
| Cam 01 | Lobby Principal | Ruta principal del Botones. |
| Cam 02 | Recepción | Cámara de tránsito, permite anticipar movimiento hacia pasillos. |
| Cam 03 | Cocina | Refugio del Chef; punto de activación del señuelo de audio. |
| Cam 04 / 05 | Pasillo Este / Oeste | Cuellos de botella hacia la oficina; puntos de mayor tensión. |
| Cam 06 | Cuarto de Calderas | Oscura, requiere Flash de Cámara. |
| Cam 07 | Conductos de Ventilación | Visión nocturna verde; ruta exclusiva de la Mucama. |

Esta red de 7 cámaras + oficina está dimensionada deliberadamente para ser manejable por un solo jugador sin sobrecarga cognitiva, y para servir de base escalable de contenido en el MVP (ver Página 6).

---

## Página 4 — Core Loop (con cambio de estado)

### Loop principal

Percibir → Identificar amenaza → Activar contramedida específica → Confirmar resolución → Volver a vigilar

### Cambio de estado explícito

El sistema se modela con máquina de estados por amenaza, más un estado global de energía:

**Estado global:** Energía [0–100%]
- Cada acción del jugador resta energía (tasa distinta por mecánica; ver Página 5).
- Si Energía = 0 → transición forzada a estado **Apagón**: puertas se abren automáticamente, cámaras se apagan, Jumpscare garantizado en el siguiente ciclo de patrulla de cualquier monstruo activo. Esto es una condición de derrota.

**Estado por amenaza (ejemplo: Botones):**
Lejos (Cam 01) → (temporizador sin vigilancia) → Acercándose (Cam 02/04) → (jugador cierra reja correspondiente) → Bloqueado (frente a reja) → (temporizador de espera) → Retirado (vuelve a Cam 01)

Si el jugador no cierra la reja a tiempo cuando el estado llega a *En la oficina*: transición a **Jumpscare** → derrota inmediata.

**Estado por amenaza (Mucama):**
En ductos (Cam 07) → Acercándose a rejilla de oficina → (jugador activa Sobrecargo de Caldera) → Repelida → En ductos. Sin la contramedida correcta a tiempo: **Jumpscare**.

**Estado por amenaza (Cornelius, desde Noche 4):**
Inactivo → (sonido de reloj de bolsillo) → Corto circuito en curso → (jugador baja el monitor en <3s) → Resuelto / si no reacciona → Cámara interferida (esa cámara queda ciega el resto de la noche; no es derrota inmediata, pero incrementa el riesgo acumulado).

Este diseño de estados es deliberadamente implementable: cada transición depende de un input discreto del jugador (clic/tecla) y un temporizador, sin necesidad de sistemas de IA complejos para el MVP.

---

## Página 5 — Mecánicas y Sistemas Especificados

| Mecánica | Descripción | Costo de energía | Contrarresta a |
|---|---|---|---|
| Rejas de Ascensor (Izq/Der) | Bloquean físicamente el paso; el monstruo espera visible tras los barrotes hasta desistir. | Alto mientras permanecen cerradas | Botones, Chef |
| Intercomunicador (señuelo de audio) | Reproduce jazz de los años 20 en una cámara específica para atraer al Chef y alejarlo del pasillo del jugador. Solo una cámara a la vez. | Medio, por uso | Chef |
| Sobrecargo de Caldera (calefacción de ductos) | Bombea aire caliente por la ventilación para repeler a la Mucama; no sirve contra amenazas terrestres. | Fijo por activación | La Mucama |
| Flash de Cámara | Ilumina por 1 segundo cámaras oscuras (Calderas, Pasillos) para revisar si Cornelius se oculta. | Alto si se abusa | Cornelius (detección) |
| Interferencia de Cornelius | El jugador debe bajar el monitor de cámaras al escuchar el tic-tac del reloj de bolsillo; si no reacciona, esa cámara queda ciega el resto de la noche. | N/A (es una amenaza, no una defensa) | — |

### Regla de diseño explícita

Ninguna mecánica de defensa es universal: esto obliga al jugador a identificar correctamente la amenaza antes de reaccionar, que es el pilar central del juego (ver Página 1).

---

## Página 6 — MVP (2-3 Noches del mismo sistema)

### Alcance del MVP

El MVP se define como las primeras 3 noches jugables, usando el mismo sistema base (energía + cámaras + rejas), con dificultad progresiva mediante ajuste de parámetros, no mediante contenido nuevo:

| Noche | Monstruos activos | Cambio respecto a la noche anterior |
|---|---|---|
| Noche 1 (tutorial implícito) | Solo el Botones | Ritmo lento, energía abundante (drenaje reducido 30%) para que el jugador aprenda el loop sin morir. |
| Noche 2 | Botones + Chef | Se introduce el Intercomunicador; el jugador debe alternar entre dos contramedidas distintas. |
| Noche 3 | Botones + Chef + Mucama | Se introduce el Sobrecargo de Caldera y la vigilancia de Cam 07; drenaje de energía a tasa base (100%). |

Esta estructura demuestra que el mismo sistema (loop + energía + red de cámaras) escala en dificultad sin necesidad de nuevos sistemas de código, solo agregando un monstruo y ajustando curvas numéricas — esto es clave para la viabilidad de producción en el tiempo del curso.

### Justificación de alcance

Se eligió detener el MVP en la Noche 3 (antes de Cornelius) porque la mecánica de Interferencia requiere lógica adicional de "cámara permanentemente inutilizada", que agrega complejidad de estado no esencial para demostrar el core loop.

---

## Página 7 — Sistemas Fuera del MVP

Los siguientes sistemas están diseñados y documentados, pero explícitamente NO se implementarán en el MVP:

1. Cornelius y la mecánica de Interferencia (Noche 4-5): requiere lógica de estado persistente por cámara (ciega permanentemente) y balanceo fino de un jefe final; se pospone a una segunda iteración post-MVP.
2. Noche 5 y escalado final de dificultad ("todo se vuelve más rápido"): depende de que las 3 mecánicas básicas ya estén balanceadas; no tiene sentido afinar el clímax antes de validar la base.
3. Sistema de progresión entre partidas (desbloqueables, logros, modo personalizado de noches): no aporta a validar si el core loop es divertido, que es la pregunta que el MVP debe responder.
4. Narrativa expandida/cinemáticas (secuencias del incendio de 1929, finales alternativos): el lore ya cumple su función de justificar mecánicas (ver Página 2); una expansión narrativa es contenido de pulido, no de validación.
5. Menú de opciones avanzado, accesibilidad completa, rebinding de controles: se usará una configuración fija de controles para el MVP.

Esta exclusión explícita evita que el equipo, con dos integrantes, intente abarcar más de lo que el tiempo de la segunda parcial permite.

---

## Página 8 — Condiciones de Victoria y Derrota

### Condición de victoria

El jugador gana la noche cuando el reloj en pantalla llega a 6:00 AM sin que ninguna amenaza haya alcanzado el estado *Jumpscare*. Ganar las 3 noches del MVP en secuencia constituye la finalización de la versión jugable.

### Condiciones de derrota

1. **Derrota por Apagón:** Energía = 0% → puertas se abren automáticamente → cualquier monstruo en estado *Acercándose* o *En la oficina* provoca Jumpscare automático.
2. **Derrota por contramedida incorrecta o tardía:** el jugador identifica mal la amenaza (p. ej., cierra la reja en vez de activar el Sobrecargo de Caldera contra la Mucama) o reacciona después de que el temporizador de la amenaza expira → Jumpscare inmediato de ese monstruo específico.

### Regla de diseño sobre derrota

Ambas derrotas son atribuibles a una decisión del jugador (gestión de energía o identificación de amenaza), nunca a azar puro, lo cual es coherente con el pilar de diseño de "decisiones excluyentes" (Página 1) y evita la frustración de "muertes injustas" identificada como riesgo (ver Página 9).

---

## Página 9 — Riesgos Reales y Alcance Controlado

| # | Riesgo | Categoría | Impacto | Probabilidad | Plan de mitigación / validación |
|---|---|---|---|---|---|
| 1 | Sobrecarga cognitiva: el jugador debe vigilar 7 cámaras + energía + 3 contramedidas distintas y puede sentirse abrumado en vez de tenso. | Diseño / UX | Alto | Media | Prototipo en Figma/Unity de la Noche 1 (solo Botones) probado con 5 personas; medir cuántas veces revisan la cámara equivocada. Si el error es sistemático, reducir cámaras visibles simultáneas. |
| 2 | Error de input: zonas de clic para cámaras y rejas muy cercanas, causando muertes por error de UI y no de juego. | UX / Usabilidad | Alto | Media | Prueba de usabilidad de 2 minutos en Noche 5 simulada con 5 personas; si hay más de 1-2 errores de clic por persona, se separan las zonas interactivas. |
| 3 | Balanceo de energía: si el drenaje es muy alto, el juego se vuelve injusto; si es muy bajo, pierde tensión. | Balance de juego | Alto | Alta | Playtesting iterativo de la Noche 2 (primera noche con decisión real de prioridad) ajustando tasas de consumo en incrementos de 10%. |
| 4 | Alcance excesivo para equipo de 2 personas en el tiempo de la segunda parcial. | Gestión de proyecto | Alto | Alta | Ya mitigado explícitamente delimitando el MVP a 3 noches y posponiendo Cornelius, progresión y narrativa expandida (ver Página 7). |
| 5 | La mecánica de Interferencia de Cornelius (fuera del MVP) podría requerir refactor de la lógica de cámaras ya construida si no se planea desde el inicio. | Técnico | Medio | Media | Diseñar la clase/objeto "Cámara" del MVP con un campo de estado (activa/interferida) desde el inicio, aunque no se use hasta la Noche 4, para evitar refactor mayor después. |
| 6 | Dependencia de audio para mecánicas clave (reloj de Cornelius, pasos, señuelo de jazz) puede excluir jugadores con discapacidad auditiva o jugar sin sonido. | Accesibilidad | Medio | Alta | Fuera de alcance del MVP (ver Página 7), pero se documenta como deuda de diseño a resolver con indicador visual redundante en iteración futura. |

### Alcance controlado (resumen)

El equipo, de solo dos integrantes, controla el alcance de tres formas concretas:

1. Limitando el MVP a 3 noches con el mismo sistema (Página 6).
2. Excluyendo explícitamente 5 sistemas documentados pero no implementados (Página 7).
3. Diseñando las derrotas para que dependan de decisiones del jugador y no de sistemas nuevos de IA compleja (Página 8), reduciendo carga de programación.

---

## Página 10 — Justificación de Decisiones y Rol de Diseñador

### Trade-off explícito

- **Opción 1 (descartada):** HUD invisible/mínimo (sin número de energía ni reloj visibles) para máximo realismo, obligando al jugador a revisar un reloj físico dentro del escenario.
- **Opción 2 (elegida):** Energía y hora siempre visibles en las esquinas superiores de la pantalla.
- **Lo que se pierde:** algo de inmersión/realismo visual.
- **Lo que se gana:** el jugador puede tomar decisiones de prioridad (¿cierro reja o activo caldera?) con información completa y sin perder tiempo de reacción en momentos de pánico, lo cual es indispensable dado que el juego ya exige identificar amenazas con precisión (pilar de diseño #2, Página 1).

### Por qué el diseño es viable para producción

1. Los estados son discretos y finitos (Página 4): no requieren IA compleja, sino temporizadores y transiciones por input, lo cual es programable por un equipo de dos personas en el tiempo disponible.
2. El MVP reutiliza el mismo sistema tres veces (Página 6): el costo de producción no crece linealmente con el contenido, porque cada noche nueva es una reconfiguración de parámetros, no una mecánica nueva.
3. Los riesgos más altos ya tienen mitigación planeada antes de escribir código (Página 9), en vez de descubrirse durante producción.
4. La narrativa no es un añadido: cada personaje fue diseñado primero por su función mecánica y después vestido con lore (Página 2), evitando el riesgo común de una historia bonita que no sirve al gameplay.

### Asunción de responsabilidad del equipo

Ángel Mateo Delgado Cortes fue responsable de lore, personajes, dirección de arte y las mecánicas de Rejas de Ascensor e Intercomunicador. Diego Alexander Cárdenas Sánchez fue responsable del diseño del Core Loop, el sistema de energía, las mecánicas de Calefacción de Conductos, Flash de Cámara e Interferencia, y la matriz de riesgos. Ambos integrantes participaron en sesión 1 (definición conjunta de concepto), trabajo independiente (secciones divididas y documentadas arriba) y sesión 2 (revisión cruzada y consolidación final), dejando registro en GitHub mediante commits individuales y en la minuta de sesión adjunta como Anexo A.

---

## Anexo A — Evidencia de sesiones

### Sesión 1 — Martes 15 de septiembre de 2026, 17:00-18:30 hrs (videollamada)

**Asistentes:** Ángel Mateo Delgado Cortes, Diego Alexander Cárdenas Sánchez.

**Acuerdos:**
- Se descarta la primera propuesta (un barco fantasma) por ser demasiado similar a referentes ya conocidos del género; Diego propone un hotel de los años 20 como setting, y se acepta por unanimidad.
- Se decide que Leo (el jugador) debe tener una razón económica creíble para no huir del trabajo, evitando el problema típico de "¿por qué no simplemente te vas?".
- Se acuerda que ningún monstruo puede resolverse con la misma contramedida que otro; esto queda como regla de diseño obligatoria para toda mecánica futura.
- Diego se compromete a investigar 2-3 referentes de horror de gestión de recursos antes del viernes para evitar repetir mecánicas ya vistas (FNAF, Poppy Playtime).
- Mateo se compromete a tener una primera versión del lore y los 4 personajes antes del jueves.
- Se define fecha de sesión 2 para el domingo 20 de septiembre a las 18:00 hrs.

### Trabajo independiente — Miércoles 16 a sábado 19 de septiembre de 2026

- **16 sept:** Diego sube al repositorio la comparación de referentes (FNAF 1-4, Poppy Playtime Cap. 1) con notas sobre qué mecánicas evitar; commit: `docs: investigación de referentes de género`.
- **17 sept:** Mateo sube el documento de lore, los 4 personajes y la dirección de arte "Art Decó Decadente"; commit: `feat(lore): historia, personajes y dirección de arte`.
- **18 sept:** Diego sube el diagrama del core loop y la primera tabla de consumo de energía por mecánica; commit: `feat(core-loop): estados y balance preliminar de energía`.
- **18 sept (tarde):** Mateo redacta las fichas de las mecánicas de Rejas de Ascensor e Intercomunicador; commit: `feat(mecanicas): ascensores e intercomunicador`.
- **19 sept:** Diego redacta las fichas de Calefacción de Conductos, Flash de Cámara e Interferencia de Cornelius, además de la primera versión de la matriz de riesgos; commit: `feat(mecanicas): calefaccion, flash, interferencia + matriz de riesgos`.
- Ambos reportan avances por chat del equipo (capturas de commits compartidas la noche del 19 de septiembre).

### Sesión 2 — Domingo 20 de septiembre de 2026, 18:00-19:15 hrs (videollamada)

**Asistentes:** Ángel Mateo Delgado Cortes, Diego Alexander Cárdenas Sánchez.

**Acuerdos:**
- Mateo revisa la sección de mecánicas escrita por Diego y sugiere aclarar que la Calefacción de Caldera no sirve contra amenazas terrestres; se corrige en el documento.
- Diego revisa la sección de lore y personajes de Mateo y pide precisar el costo de energía del Flash de Cámara, que originalmente no tenía valor asignado; se agrega como "alto si se abusa".
- Se discute y se cierra la definición de las condiciones de victoria y derrota, que hasta ese momento estaban solo esbozadas por separado en las notas de cada quien.
- Se revisa en conjunto la matriz de riesgos y se agrega el riesgo de accesibilidad auditiva (propuesto por Mateo tras la revisión).
- Se acuerda consolidar el documento en un solo archivo Markdown esa misma noche; Mateo queda a cargo de integrar el documento final y exportarlo a PDF antes de la entrega.
- Commit final de consolidación: `docs: GDD v1 consolidado, listo para producción`.

---

## Anexo B — Tabla de consumo de energía (referencia de balance, sujeta a playtesting)

| Acción | Consumo relativo |
|---|---|
| Cámaras abiertas (pasivo) | Bajo |
| Reja cerrada (por segundo) | Alto |
| Sobrecargo de Caldera (por uso) | Medio-Alto |
| Flash de Cámara (por uso) | Medio |
| Intercomunicador activo | Medio |

---

## Anexo C — Checklist de entrega

- ☒ Documento completo en Markdown subido a GitHub.
- ☒ PDF exportado para Classroom.
- ☒ Evidencia de participación de ambos integrantes en sesión 1, trabajo independiente y sesión 2.
- ☒ High Concept, Core Loop con cambio de estado, MVP, mecánicas, sistemas fuera de MVP, condiciones de victoria/derrota y riesgos, todos documentados.
