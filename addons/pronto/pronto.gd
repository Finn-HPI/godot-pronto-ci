@tool
extends EditorPlugin
class_name Pronto

const COMPONENTS = {
	"Move": "ToolMove",
	"Spawner": "GPUParticles3D",
	"Controls": "Joypad",
	"Bind": "EditBezier",
	"State": "CylinderMesh",
	"Collision": "GPUParticlesCollisionBox3D",
	"Clock": "Timer",
	"Always": "Loop",
	"Placeholder": "Skeleton2D",
	"Key": "KeyboardPhysical",
	"Stopwatch": "Time"
}

var edited_object
var popup

func _enter_tree():
	if not Engine.is_editor_hint():
		return
	
	var base = get_editor_interface().get_base_control()
	for key in COMPONENTS:
		add_custom_type(key,
			"Node2D", load("res://addons/pronto/behaviors/" + key + ".gd"),
			base.get_theme_icon(COMPONENTS[key], &"EditorIcons"))

func _exit_tree():
	for key in COMPONENTS:
		remove_custom_type(key)

func pronto_should_ignore(object):
	if not object is Node:
		return false
	
	if object.has_meta("pronto_ignore"):
		return object.get_meta("pronto_ignore")
	else:
		if object.has_method("get_parent") and object.get_parent():
			return pronto_should_ignore(object.get_parent())
		else:
			return false

func _handles(object):
	return !pronto_should_ignore(object)

func _edit(object):
	if edited_object and edited_object is Behavior:
		edited_object.deselected()
	
	edited_object = object
	if edited_object and edited_object is Node:
		show_signals(edited_object)
	else:
		close()

func close():
	if popup: popup.queue_free()
	popup = null

func _make_visible(visible):
	if not visible:
		close()

func _forward_canvas_gui_input(event):
	if edited_object is Behavior:
		var ret = edited_object._forward_canvas_gui_input(event, get_undo_redo())
		if ret:
			update_overlays()
		return ret
	return false

func _forward_canvas_draw_over_viewport(viewport_control):
	if edited_object is Behavior:
		edited_object._forward_canvas_draw_over_viewport(viewport_control)

func show_signals(node: Node):
	if popup:
		close()
	
	var Connect = preload("res://addons/pronto/signal_connecting/connect.tscn")
	popup = Connect.instantiate()
	popup.undo_redo = get_undo_redo()
	popup.node = node
	popup.anchor = Utils.parent_that(node, func (p): return Utils.has_position(p))
	Utils.spawn_popup_from_canvas(node, popup)