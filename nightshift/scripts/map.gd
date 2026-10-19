extends RefCounted
## Red de 7 camaras + oficina (GDD Pagina 3) y grafo de movimiento de los monstruos.

const CAMS: Dictionary = {
	1: {"name": "LOBBY PRINCIPAL", "short": "LOBBY", "dark": false},
	2: {"name": "RECEPCIÓN", "short": "RECEPCIÓN", "dark": false},
	3: {"name": "COCINA", "short": "COCINA", "dark": false},
	4: {"name": "PASILLO ESTE", "short": "PASILLO ESTE", "dark": true},
	5: {"name": "PASILLO OESTE", "short": "PASILLO OESTE", "dark": true},
	6: {"name": "CUARTO DE CALDERAS", "short": "CALDERAS", "dark": true},
	7: {"name": "CONDUCTOS DE VENTILACIÓN", "short": "DUCTOS", "dark": false},
}

# Conexiones entre camaras (las rejas de la oficina se alcanzan desde los pasillos).
const LINKS: Dictionary = {
	1: [2],
	2: [1, 3, 4, 5],
	3: [2],
	4: [2, 6],
	5: [2, 6],
	6: [4, 5],
	7: [],
}

# Pasillo Este -> reja derecha; Pasillo Oeste -> reja izquierda.
const DOOR_CAM: Dictionary = {"left": 5, "right": 4}


static func cam_name(id: int) -> String:
	return "CAM %02d — %s" % [id, CAMS[id]["name"]]


static func is_dark(id: int) -> bool:
	return CAMS[id]["dark"]


## Siguiente camara en el camino mas corto de `from` hacia `to` (BFS).
static func next_step(from: int, to: int) -> int:
	if from == to:
		return from
	var prev: Dictionary = {from: -1}
	var queue: Array = [from]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		if cur == to:
			break
		for n in LINKS[cur]:
			if not prev.has(n):
				prev[n] = cur
				queue.append(n)
	if not prev.has(to):
		return from
	var step: int = to
	while prev[step] != from:
		step = prev[step]
	return step
