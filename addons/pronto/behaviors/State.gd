@tool
extends Behavior

signal changed(prop: String, value: Variant)

func inc(prop: String, amount = 1):
	var value = get_meta(prop) + amount
	set_meta(prop, value)
	changed.emit(prop, value)

func put(prop: String, value: Variant):
	set_meta(prop, value)
	changed.emit(prop, value)

func at(prop: String):
	return get_meta(prop)