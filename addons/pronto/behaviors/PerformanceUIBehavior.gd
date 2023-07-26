@tool
#thumb("AnimationTrackList")
extends Behavior
class_name PerformanceBehavior

var panel: PanelContainer
var outer_vbox: VBoxContainer
var fps_label: Label
var node_counter_label: Label
enum monitor {
		TIME_FPS,
		TIME_PROCESS,
		TIME_PHYSICS_PROCESS,
		TIME_NAVIGATION_PROCESS,
		MEMORY_STATIC,
		MEMORY_STATIC_MAX,
		MEMORY_MESSAGE_BUFFER_MAX,
		OBJECT_COUNT,
		OBJECT_RESOURCE_COUNT,
		OBJECT_NODE_COUNT,
		OBJECT_ORPHAN_NODE_COUNT,
		RENDER_TOTAL_OBJECTS_IN_FRAME,
		RENDER_TOTAL_PRIMITIVES_IN_FRAME,
		RENDER_TOTAL_DRAW_CALLS_IN_FRAME,
		RENDER_VIDEO_MEM_USED,
		RENDER_TEXTURE_MEM_USED,
		RENDER_BUFFER_MEM_USED,
		PHYSICS_2D_ACTIVE_OBJECTS,
		PHYSICS_2D_COLLISION_PAIRS,
		PHYSICS_2D_ISLAND_COUNT,
		PHYSICS_3D_ACTIVE_OBJECTS,
		PHYSICS_3D_COLLISION_PAIRS,
		PHYSICS_3D_ISLAND_COUNT,
		AUDIO_OUTPUT_LATENCY,
		NAVIGATION_ACTIVE_MAPS,
		NAVIGATION_REGION_COUNT,
		NAVIGATION_AGENT_COUNT,
		NAVIGATION_LINK_COUNT,
		NAVIGATION_POLYGON_COUNT,
		NAVIGATION_EDGE_COUNT,
		NAVIGATION_EDGE_MERGE_COUNT,
		NAVIGATION_EDGE_CONNECTION_COUNT,
		NAVIGATION_EDGE_FREE_COUNT,
		MONITOR_MAX
	}

## Set the lower limit of when the fps_warning signal should be fired. (0 means never)
@export var fps_warn: int = 0:
	set(value):
		fps_warn = max(0,value)

@export_group("Metrics to display")
@export var TIME_FPS: bool = true
@export var TIME_PROCESS: bool = false
@export var TIME_PHYSICS_PROCESS: bool = false
@export var TIME_NAVIGATION_PROCESS: bool = false
@export var MEMORY_STATIC: bool = false
@export var MEMORY_STATIC_MAX: bool = false
@export var MEMORY_MESSAGE_BUFFER_MAX: bool = false
@export var OBJECT_COUNT: bool = false
@export var OBJECT_RESOURCE_COUNT: bool = false
@export var OBJECT_NODE_COUNT: bool = true
@export var OBJECT_ORPHAN_NODE_COUNT: bool = false
@export var RENDER_TOTAL_OBJECTS_IN_FRAME: bool = false
@export var RENDER_TOTAL_PRIMITIVES_IN_FRAME: bool = false
@export var RENDER_TOTAL_DRAW_CALLS_IN_FRAME: bool = false
@export var RENDER_VIDEO_MEM_USED: bool = false
@export var RENDER_TEXTURE_MEM_USED: bool = false
@export var RENDER_BUFFER_MEM_USED: bool = false
@export var PHYSICS_2D_ACTIVE_OBJECTS: bool = false
@export var PHYSICS_2D_COLLISION_PAIRS: bool = false
@export var PHYSICS_2D_ISLAND_COUNT: bool = false
@export var PHYSICS_3D_ACTIVE_OBJECTS: bool = false
@export var PHYSICS_3D_COLLISION_PAIRS: bool = false
@export var PHYSICS_3D_ISLAND_COUNT: bool = false
@export var AUDIO_OUTPUT_LATENCY: bool = false
@export var NAVIGATION_ACTIVE_MAPS: bool = false
@export var NAVIGATION_REGION_COUNT: bool = false
@export var NAVIGATION_AGENT_COUNT: bool = false
@export var NAVIGATION_LINK_COUNT: bool = false
@export var NAVIGATION_POLYGON_COUNT: bool = false
@export var NAVIGATION_EDGE_COUNT: bool = false
@export var NAVIGATION_EDGE_MERGE_COUNT: bool = false
@export var NAVIGATION_EDGE_CONNECTION_COUNT: bool = false
@export var NAVIGATION_EDGE_FREE_COUNT: bool = false

var label_cache = {}

signal fps_warning(current_fps: int)

var shape_rect: Rect2


@export_group("Design")
@export var shape_size: Vector2:
	set(v):
		shape_size = v
		shape_rect = Rect2(shape_size / -2, shape_size)
		queue_redraw()
		
@export var background_color: Color:
	set(v):
		background_color = v
		queue_redraw()
		
var size:
	get:
		return shape_size

var scroll_container: ScrollContainer

var expanded = true
var min_button: Button
var header_hbox: HBoxContainer
var expanded_size: Vector2
var minimized_size: Vector2

func _init():
	self.shape_size = Vector2(200, 60)
	

func _ready():
	super._ready()
	self.top_level = true
	outer_vbox = VBoxContainer.new()
	outer_vbox.set_size(shape_size)
	outer_vbox.set_position(Vector2(-shape_size.x/2, -shape_size.y/2))
	var header_label = Label.new()
	header_label.text = self.name
	min_button = Button.new()
	min_button.text = "—"
	min_button.pressed.connect(_toggle_visiblity)
	expanded_size = shape_size
	
	header_hbox = HBoxContainer.new()
	header_hbox.add_child(header_label)
	header_hbox.add_spacer(false)
	header_hbox.add_child(min_button)
	
	
	outer_vbox.add_child(header_hbox)
	scroll_container = ScrollContainer.new()
	var inner_vbox = VBoxContainer.new()
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(inner_vbox)
	outer_vbox.add_child(scroll_container)
	
	
	var counter = 0
	for current_monitor in monitor.keys():
		if self.get(current_monitor):
			var monitor_label = Label.new()
			label_cache[monitor.keys()[counter]] = {"id": counter, "label": monitor_label}
			inner_vbox.add_child(monitor_label)
		counter += 1
	self.add_child(outer_vbox)

func _process(delta):
	super._process(delta)
	if !Engine.is_editor_hint():
		var fps = Engine.get_frames_per_second()
		if fps_warn > 0 and fps <= fps_warn:
			fps_warning.emit(fps)
		for label_entry in label_cache:
			var value = Performance.get_monitor(label_cache[label_entry]["id"])
			label_cache[label_entry]["label"].text = _beautify_name(label_entry) + ": " + str(value)

func _toggle_visiblity():
	expanded = !expanded
	scroll_container.visible = expanded
	header_hbox.get_children()[1].visible = expanded
	if expanded:
		min_button.text = "—"
		minimized_size = header_hbox.size
		self.shape_size = expanded_size
	else:
		min_button.text = "+"
		self.shape_size = header_hbox.size
	

func handles():
	return [
		Handles.SetPropHandle.new(shape_size / 2,
			Utils.icon_from_theme("EditorHandle", self),
			self,
			"shape_size",
			func (coord): return floor(coord * 2).clamp(Vector2(1, 1), Vector2(10000, 10000)))
	]

func _draw():
	super._draw()
	if shape_rect != null and expanded:
		draw_rect(shape_rect, background_color, true)
		
func _beautify_name(name: String):
	var output = ""
	for s in name.split("_"):
		var tmp = s.to_lower()
		tmp[0] = tmp[0].to_upper()
		output = output + " " + tmp
	return output


