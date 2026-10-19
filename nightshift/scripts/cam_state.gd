extends RefCounted
## Estado de una camara.
## GDD Riesgo #5: el campo de estado (activa/interferida) existe desde el inicio aunque
## la Interferencia de Cornelius (Noche 4+) quede fuera del MVP, para evitar refactor despues.

enum Estado { ACTIVA, INTERFERIDA }

var id: int = 0
var estado: int = Estado.ACTIVA


func _init(cam_id: int) -> void:
	id = cam_id


func is_blind() -> bool:
	return estado == Estado.INTERFERIDA
