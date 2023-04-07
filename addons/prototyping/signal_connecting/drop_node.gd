@tool
extends HBoxContainer

var NodeToNodeConfigurator = load("res://addons/prototyping/signal_connecting/node_to_node_configurator.tscn")

var node: Node:
	set(value):
		node = value
		%label.text = node.name
		var icon = Utils.icon_for_class(node.get_class(), node)
		if icon:
			%icon.texture = icon

func _can_drop_data(at_position, data):
	return "type" in data and data["type"] == "P_CONNECT_SIGNAL"

func _drop_data(at_position, data):
	var source_signal = data["signal"]
	
	var popup = NodeToNodeConfigurator.instantiate()
	popup.selected_signal = source_signal
	popup.receiver = node
	popup.anchor = node
	Utils.spawn_popup_from_canvas(node, popup)
