extends Area2D

const SPEED: float = 60.0
const MAX_SIZE: Vector2 = Vector2(3.0, 3.0)
const HOVER_DURATION: float = 0.4
const BOOST_DURATION: float = 3.0 # How long the speed boost lasts in seconds

var position_tween: Tween 
var scale_tween: Tween
var blink_tween: Tween
var boost_timer: Timer

func _ready() -> void:
	position_tween = Tween.new()
	scale_tween = Tween.new()
	blink_tween = Tween.new()
	boost_timer = Timer.new()

	add_child(position_tween)
	add_child(scale_tween)
	add_child(blink_tween)
	add_child(boost_timer)
	
	position_tween.connect("tween_completed", self, "_on_tween_completed")
	
	# Configure boost countdown timer
	boost_timer.one_shot = true
	boost_timer.connect("timeout", self, "_on_boost_timeout")

# Hover entered: freeze position movement and scale up
func _on_fish_mouse_entered() -> void:
	position_tween.stop_all()
	
	scale_tween.remove(self, "scale")
	scale_tween.interpolate_property(
		self,
		"scale",
		scale,
		MAX_SIZE,
		HOVER_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	scale_tween.start()

# Hover exited: scale down and resume position movement
func _on_fish_mouse_exited() -> void:
	scale_tween.remove(self, "scale")
	scale_tween.interpolate_property(
		self,
		"scale",
		scale,
		Vector2(1.0, 1.0),
		HOVER_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	scale_tween.start()
	
	position_tween.resume_all()


func _on_fish_input_event(_p_viewport: Viewport, p_event: InputEvent, _p_shape_idx: int) -> void:
	if p_event.is_action_pressed("left_click"):
		_apply_speed_boost()

func _apply_speed_boost() -> void:
	position_tween.playback_speed = 4.0

	boost_timer.start(BOOST_DURATION)
	
	blink_tween.remove_all()
	blink_tween.interpolate_property(
		self,
		"modulate:a",
		1.0,
		0.2,
		0.15,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	blink_tween.repeat = true
	blink_tween.playback_process_mode = Tween.TWEEN_PROCESS_IDLE

	blink_tween.interpolate_property(
		self,
		"modulate:a",
		0.2,
		1.0,
		0.15,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT,
		0.15
	)
	blink_tween.start()


# Triggered when boost duration expires
func _on_boost_timeout() -> void:
	position_tween.playback_speed = 1.0

	blink_tween.stop_all()
	blink_tween.remove_all()
	modulate.a = 1.0

func move() -> void:
	var m_screen_size: Vector2 = _fall_back_screen_size()
	
	position.x = clamp(position.x, 2.0, m_screen_size.x - 2.0)
	position.y = clamp(position.y, 2.0, m_screen_size.y - 2.0)
	
	var m_direction: Vector2 = Vector2.DOWN.rotated(rotation)
	var m_end_position: Vector2 = _find_end_position(position, m_direction)
	
	var m_distance: float = position.distance_to(m_end_position)
	var m_duration: float = m_distance / SPEED
	
	position_tween.remove(self, "position")
	_create_twin_with_different_property(m_end_position, m_duration)
	position_tween.start()

func _find_end_position(p_start_pos: Vector2, p_dir: Vector2) -> Vector2:
	var m_screen_bounds: Rect2 = Rect2(Vector2.ZERO, _fall_back_screen_size())
	var m_shortest_travel_time: float = INF
	
	if p_dir.x != 0.0:
		var m_time_to_left_edge: float = (m_screen_bounds.position.x - p_start_pos.x) / p_dir.x
		var m_time_to_right_edge: float = (m_screen_bounds.end.x - p_start_pos.x) / p_dir.x
		
		if m_time_to_left_edge > 0.0: 
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_left_edge)
		if m_time_to_right_edge > 0.0: 
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_right_edge)

	if p_dir.y != 0.0:
		var m_time_to_top_edge: float = (m_screen_bounds.position.y - p_start_pos.y) / p_dir.y
		var m_time_to_bottom_edge: float = (m_screen_bounds.end.y - p_start_pos.y) / p_dir.y
		
		if m_time_to_top_edge > 0.0: 
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_top_edge)
		if m_time_to_bottom_edge > 0.0: 
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_bottom_edge)

	return p_start_pos + p_dir * m_shortest_travel_time



#create 5-6 different type of tween and then add them in the move function dynamically choosing or something so everything else is decoupled
func _create_twin_with_different_property(p_end_position: Vector2, p_duration: float) ->void:
	var m_random : int = randi() % 5
	#we might be able to utilize, 
	if m_random == 0:
		position_tween.interpolate_property(
		self, 
		"position", 
		position,
		p_end_position, 
		p_duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	elif m_random == 1:
		position_tween.interpolate_property(
		self, 
		"position", 
		position,
		p_end_position, 
		p_duration, 
		Tween.TRANS_CIRC, 
		Tween.EASE_IN_OUT
	)
	elif m_random == 2:
		position_tween.interpolate_property(
		self, 
		"position", 
		position,
		p_end_position, 
		p_duration, 
		Tween.TRANS_QUAD, 
		Tween.EASE_OUT
	)
	elif m_random == 3:
		position_tween.interpolate_property(
		self, 
		"position", 
		position,
		p_end_position, 
		p_duration, 
		Tween.TRANS_ELASTIC, 
		Tween.EASE_IN
	)
	else:
		position_tween.interpolate_property(
		self, 
		"position", 
		position,
		p_end_position, 
		p_duration, 
		Tween.TRANS_BOUNCE, 
		Tween.EASE_OUT_IN
	)
		

func _on_tween_completed(_p_object: Object, p_key: NodePath) -> void:
	if p_key == NodePath(":position"):
		_change_direction()

func _change_direction() -> void:
	rotation = (PI + rotation) + rand_range(PI / 10.0, PI / 8.0)
	#is it better to move or just recompute, the end_point? will the tween continue to behave as expected?
	move()

func _fall_back_screen_size() -> Vector2:
	return get_viewport().size
