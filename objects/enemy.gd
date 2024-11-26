extends Node3D

@export var player: Node3D
@export var patrol_points: Array[Vector3]  # Pontos de patrulha
@export var detection_radius: float = 10.0  # Raio de detecção do jogador
@export var speed: float = 2.0  # Velocidade de movimento

@onready var raycast = $RayCast
@onready var muzzle_a = $MuzzleA
@onready var muzzle_b = $MuzzleB

var health := 100
var time := 0.0
var destroyed := false
var current_patrol_index := 0
var is_chasing := false

# Inicializando variáveis para patrulhamento
var target_position: Vector3

func _ready():
	if patrol_points.size() > 0:
		target_position = patrol_points[current_patrol_index]
		position = patrol_points[current_patrol_index]

func _process(delta):
	if destroyed:
		return

	if player and position.distance_to(player.position) <= detection_radius:
		is_chasing = true
	else:
		is_chasing = false

	if is_chasing:
		chase_player(delta)
	else:
		patrol(delta)

	# Garante que o inimigo sempre olhe para o jogador de frente
	look_at(player.position + Vector3(0, 0.5, 0), Vector3.UP)

func patrol(delta):
	if patrol_points.size() == 0:
		return

	# Movendo-se entre os pontos de patrulha
	position = position.lerp(target_position, speed * delta)

	# Quando o inimigo chega em um ponto de patrulha, muda para o próximo
	if position.distance_to(target_position) < 0.1:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target_position = patrol_points[current_patrol_index]

func chase_player(delta):
	var target = player.position
	position = position.lerp(target, speed * delta)

	# Garantir que o inimigo esteja mirando e indo para o jogador
	look_at(player.position + Vector3(0, 0.5, 0), Vector3.UP)

func damage(amount):
	Audio.play("sounds/enemy_hurt.ogg")
	health -= amount

	if health <= 0 and !destroyed:
		destroy()

func destroy():
	Audio.play("sounds/enemy_destroy.ogg")
	destroyed = true
	queue_free()

func _on_timer_timeout():
	if is_chasing:
		raycast.force_raycast_update()

		if raycast.is_colliding():
			var collider = raycast.get_collider()

			if collider.has_method("damage"):
				# Animação de ataque
				muzzle_a.frame = 0
				muzzle_a.play("default")
				muzzle_a.rotation_degrees.z = randf_range(-45, 45)

				muzzle_b.frame = 0
				muzzle_b.play("default")
				muzzle_b.rotation_degrees.z = randf_range(-45, 45)

				Audio.play("sounds/enemy_attack.ogg")
				collider.damage(5)
