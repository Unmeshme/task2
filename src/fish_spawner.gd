extends Node

export (PackedScene) var fish_scene

onready var left_ref: ReferenceRect = $left_reference
onready var right_ref: ReferenceRect = $right_reference
onready var spawn_timer: Timer = $spawn_timer

func _ready() -> void:
	randomize()

func _get_random_position(p_rect_node: ReferenceRect) -> Vector2:
	var m_rect: Rect2 = p_rect_node.get_global_rect()
	
	var m_random_x: float = rand_range(m_rect.position.x, m_rect.position.x + m_rect.size.x)
	var m_random_y: float = rand_range(m_rect.position.y, m_rect.position.y + m_rect.size.y)
	
	return Vector2(m_random_x, m_random_y)

func _spawn_fish() -> void:
	var m_spawn_side: int = randi() % 2
	var m_face_right: bool = false
	var m_position: Vector2 = Vector2.ZERO
	
	if m_spawn_side == 0:
		m_position = _get_random_position(left_ref)
		m_face_right = true
	else:
		m_position = _get_random_position(right_ref)
	
	var m_fish: Area2D = fish_scene.instance()
	m_fish.position = m_position
	
	if m_face_right:
		m_fish.rotation = rand_range(-3.0 * PI / 4.0, -PI / 4.0)
	else:
		m_fish.rotation = rand_range(3.0 * PI / 4.0, PI / 4.0)
	
	add_child(m_fish)
	m_fish.move()


func _on_spawn_timer_timeout():
	if Globals.total_fish_count < 300:
		_spawn_fish()
		Globals.total_fish_count += 1
		print("Spawned: %s " %[Globals.total_fish_count])
		spawn_timer.wait_time = rand_range(1, 6)
	
