@tool
extends Node2D
class_name Behavior

var _icon
var _handles := Handles.new()
var _lines := Lines.new()

func _ready():
	if Engine.is_editor_hint() and show_icon() and is_active_scene():
		_icon = TextureRect.new()
		var name = get_script().resource_path.get_file().split('.')[0]
		_icon.texture = Utils.icon_from_theme(G.at("_pronto_behaviors")[name], self)
		_icon.position = _icon.texture.get_size() / -2
		add_child(_icon, false, Node.INTERNAL_MODE_FRONT)
		
		# spawn slightly offset from parent
		if position == Vector2.ZERO:
			var parent = get_parent()
			var parent_rect = Utils.global_rect_of(parent)
			var parent_full_rect = parent.get_children() \
				.filter(func(child): return child != self) \
				.map(func(child): return Utils.global_rect_of(child)) \
				.reduce(func(a, b): return a.merge(b), parent_rect)
			
			var radius = (parent_full_rect.size.length() + Utils.global_rect_of(self).size.length()) / 2
			radius = clamp(radius, 10, 200)
			position = Vector2(0, radius).rotated(get_parent().get_child_count() * PI / 4)
			position = clamp(position, parent_rect.position, parent_rect.position + parent_rect.size)

func is_active_scene() -> bool:
	return owner == null or get_editor_plugin().get_editor_interface().get_edited_scene_root() == owner

func get_editor_plugin() -> EditorPlugin:
	return G.at("_pronto_editor_plugin")

func show_icon():
	return true

func connect_ui():
	return null

func _process(delta):
	if Engine.is_editor_hint():
		Connection.garbage_collect(self)
		if _lines._needs_update(lines()):
			queue_redraw()

func _forward_canvas_draw_over_viewport(viewport_control: Control):
	_handles._forward_canvas_draw_over_viewport(self, viewport_control)

func _forward_canvas_gui_input(event: InputEvent, undo_redo: EditorUndoRedoManager):
	return _handles._forward_canvas_gui_input(self, event, undo_redo)

func deselected():
	_handles.deselected()

func handles():
	return []

var _running_tweens = {}
func connection_activated(c: Connection):
	# FIXME not scheduling well yet on fast repeats
	var current = _running_tweens.get(c)
	if current != null and not current.is_running(): current = null
	if current != null:
		if current.get_total_elapsed_time() < 0.1:
			return
		else:
			current.kill()
	var t = create_tween()
	_running_tweens[c] = t
	if current == null:
		t.tween_method(flash_line.bind(c, 'activated'), 0.0, 1.0, 0.2)
	t.tween_method(flash_line.bind(c, 'activated'), 1.0, 0.0, 0.2)
	
# duplicating as Godot does not support overloading
# see: https://github.com/godotengine/godot-proposals/issues/1571
var _running_highlight_tweens = {}
func highlight_activated(c: Connection):
	var duration = 0.3
	# FIXME not scheduling well yet on fast repeats
	var current = _running_highlight_tweens.get(c)
	if current != null and not current.is_running(): current = null
	if current != null:
		current.kill()
	var t = create_tween()
	_running_highlight_tweens[c] = t
	t.tween_method(flash_line.bind(c, 'highlight'), 1.0, 0.0, duration)

func flash_line(value: float, key: Variant, type: String):
	_lines.flash_line(key, type, value)
	queue_redraw()

func lines() -> Array:
	return Connection.get_connections(self).map(func (connection):
		var other = self if not connection.is_target() else get_node_or_null(connection.to)
		if other == null:
			return null
		return Lines.Line.new(self,
			other,
			func (flipped): return connection.print(flipped),
			connection,
			Color.WHITE if connection.enabled else Color.WHITE.lerp(Color.BLACK, 0.5))
	).filter(func (connection): return connection != null)

func _draw():
	if not Engine.is_editor_hint() or not _icon or not is_inside_tree():
		return
	_lines._draw_lines(self, lines())
