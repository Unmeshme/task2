extends Area2D

const SPEED: float = 60.0
const EDGE_MARGIN: float = 30.0 #top and bottom
const EDGE_MARGIN_X: float = 60.0

const NORMAL_SCALE: Vector2 = Vector2(0.5, 0.5)
const MAX_SIZE: Vector2 = Vector2(1.0, 1.0)
const HOVER_DURATION: float = 0.4

const BOOST_DURATION: float = 3.0 # How long the speed boost lasts in seconds
const BOOST_SPEED_MULTIPLIER: float = 4.0

const STYLE_CHANGE_MIN_INTERVAL: float = 3.0
const STYLE_CHANGE_MAX_INTERVAL: float = 6.0


#one of these is overshooting lol idk which one
const TWEEN_STYLES: Array = [
	[Tween.TRANS_LINEAR, Tween.EASE_IN_OUT],
	[Tween.TRANS_SINE, Tween.EASE_IN_OUT],
	#[Tween.TRANS_QUAD, Tween.EASE_OUT],
	[Tween.TRANS_CIRC, Tween.EASE_IN_OUT],
	[Tween.TRANS_CUBIC, Tween.EASE_OUT],
]


var position_tween: Tween
var scale_tween: Tween
var blink_tween: Tween
var boost_timer: Timer
var style_timer: Timer
var is_hovered: bool = false


func _process(p_delta: float) -> void:
	pass #adding to differentiate it from the main branch to be able to create a pull request


func _ready() -> void:
	position_tween = Tween.new()
	scale_tween = Tween.new()
	blink_tween = Tween.new()
	boost_timer = Timer.new()
	style_timer = Timer.new()

	add_child(position_tween)
	add_child(scale_tween)
	add_child(blink_tween)
	add_child(boost_timer)
	add_child(style_timer)

	scale = NORMAL_SCALE
	add_to_group("fish")

	position_tween.connect("tween_completed", self, "_on_tween_completed")

	# Configure boost countdown timer
	boost_timer.one_shot = true
	boost_timer.connect("timeout", self, "_on_boost_timeout")

	# Fires every 3-6s so the swim style varies even mid-flight
	style_timer.one_shot = true
	style_timer.connect("timeout", self, "_on_style_timer_timeout")


func _on_fish_mouse_entered() -> void:
	if not _should_take_hover_focus():
		return

	is_hovered = true
	position_tween.stop_all()
	style_timer.paused = true

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


func _on_fish_mouse_exited() -> void:
	if not is_hovered:
		return
	is_hovered = false
	_shrink_to_normal()
	position_tween.resume_all()
	style_timer.paused = false

func _shrink_to_normal() -> void:
	scale_tween.remove(self, "scale")
	scale_tween.interpolate_property(
		self,
		"scale",
		scale,
		NORMAL_SCALE,
		HOVER_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	scale_tween.start()


func _should_take_hover_focus() -> bool:
	for m_other in get_tree().get_nodes_in_group("fish"):
		if m_other == self or not m_other.is_hovered:
			continue
		if m_other.z_index > z_index:
			return false
		m_other.is_hovered = false
		m_other._shrink_to_normal()
		m_other.position_tween.resume_all()
		m_other.style_timer.paused = false
	return true


func _on_fish_input_event(_p_viewport: Viewport, p_event: InputEvent, _p_shape_idx: int) -> void:
	if p_event.is_action_pressed("left_click"):
		#here remove the position tween?
		_apply_speed_boost()
		_on_fish_mouse_exited()
		move()


func _apply_speed_boost() -> void:
	position_tween.playback_speed = BOOST_SPEED_MULTIPLIER

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



func _on_boost_timeout() -> void:
	position_tween.playback_speed = 1.0

	blink_tween.stop_all()
	blink_tween.remove_all()
	modulate.a = 1.0


func move() -> void:
	var m_bounds: Rect2 = _get_bounds()

	position.x = clamp(position.x, m_bounds.position.x, m_bounds.end.x)
	position.y = clamp(position.y, m_bounds.position.y, m_bounds.end.y)

	var m_direction: Vector2 = Vector2.DOWN.rotated(rotation)
	var m_end_position: Vector2 = _find_end_position(position, m_direction, m_bounds)

	var m_distance: float = position.distance_to(m_end_position)
	var m_duration: float = m_distance / SPEED

	position_tween.remove(self, "position")
	_start_position_tween(m_end_position, m_duration)
	position_tween.start()

	style_timer.stop()
	style_timer.start(rand_range(STYLE_CHANGE_MIN_INTERVAL, STYLE_CHANGE_MAX_INTERVAL))


func _find_end_position(p_start_pos: Vector2, p_dir: Vector2, p_bounds: Rect2) -> Vector2:
	var m_shortest_travel_time: float = INF

	if p_dir.x != 0.0:
		var m_time_to_left_edge: float = (p_bounds.position.x - p_start_pos.x) / p_dir.x
		var m_time_to_right_edge: float = (p_bounds.end.x - p_start_pos.x) / p_dir.x

		if m_time_to_left_edge > 0.0:
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_left_edge)
		if m_time_to_right_edge > 0.0:
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_right_edge)

	if p_dir.y != 0.0:
		var m_time_to_top_edge: float = (p_bounds.position.y - p_start_pos.y) / p_dir.y
		var m_time_to_bottom_edge: float = (p_bounds.end.y - p_start_pos.y) / p_dir.y

		if m_time_to_top_edge > 0.0:
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_top_edge)
		if m_time_to_bottom_edge > 0.0:
			m_shortest_travel_time = min(m_shortest_travel_time, m_time_to_bottom_edge)

	return p_start_pos + p_dir * m_shortest_travel_time



func _start_position_tween(p_end_position: Vector2, p_duration: float) -> void:
	var m_style: Array = TWEEN_STYLES[randi() % TWEEN_STYLES.size()]
	position_tween.interpolate_property(
		self,
		"position",
		position,
		p_end_position,
		p_duration,
		m_style[0],
		m_style[1]
	)


func _on_tween_completed(_p_object: Object, p_key: NodePath) -> void:
	if p_key == NodePath(":position"):
		var m_bounds: Rect2 = _get_bounds()
		position.x = clamp(position.x, m_bounds.position.x, m_bounds.end.x)
		position.y = clamp(position.y, m_bounds.position.y, m_bounds.end.y)
		_change_direction()


func _on_style_timer_timeout() -> void:
	move()
	
	
func _change_direction() -> void:
	var m_bounds: Rect2 = _get_bounds()
	var m_hit_side: bool = position.x <= m_bounds.position.x or position.x >= m_bounds.end.x
	var m_hit_top_or_bottom: bool = position.y <= m_bounds.position.y or position.y >= m_bounds.end.y

	if m_hit_side and m_hit_top_or_bottom:
		rotation = PI + rotation
		
	elif m_hit_side:
		rotation = -rotation
		
	else:
		rotation = PI - rotation
	rotation = wrapf(rotation, PI, -PI)
	move()


func _get_window_size() -> Vector2:
	return get_viewport().size


func _get_bounds() -> Rect2:
	var m_top_left: Vector2 = Vector2(EDGE_MARGIN_X, EDGE_MARGIN)
	var m_size: Vector2 = _get_window_size() - m_top_left * 2.0
	return Rect2(m_top_left, m_size)
