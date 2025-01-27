@tool
#thumb("CylinderMesh")
extends Behavior
class_name StoreBehavior

## When enabled, add the value of all properties to the global G dictionary as well.
@export var global = false

var _last_reported_game_values = {}

signal changed(prop: String, value: Variant)

func _ready():
	super._ready()
	if global and not Engine.is_editor_hint():
		for prop in get_meta_list():
			if prop != "pronto_connections":
				G._register_store(self, prop)
				if global:
					G.put(prop, get_meta(prop))

func inc(prop: String, amount = 1):
	var value = get_meta(prop) + amount
	put(prop, value)

func dec(prop: String, amount = 1):
	inc(prop, -amount)

func put(prop: String, value: Variant):
	set_meta(prop, value)
	if global:
		G._put(prop, value)
	changed.emit(prop, value)
	if EngineDebugger.is_active(): EngineDebugger.send_message("pronto:store_put", [get_path(), prop, value])

func at(prop: String, default = null):
	return get_meta(prop, default)

func at_and_remove(prop: String, default = null):
	var val = at(prop,default)
	if(has_meta(prop)):
		remove_meta(prop)
	return val

func _report_game_value(prop: String, value: Variant):
	_last_reported_game_values[prop] = value

func lines():
	return super.lines() + [Lines.BottomText.new(self, _print_values())]

func _print_values():
	return "\n".join(Array(get_meta_list()).filter(func (p): return p != "pronto_connections").map(func (prop):
		return "{0} = {1}{2}".format([prop, str(get_meta(prop)), _last_reported_string(prop)])))

func _last_reported_string(prop: String):
	var val = _last_reported_game_values.get(prop)
	if val != null:
		return " ({0})".format([val])
	else:
		return ""
