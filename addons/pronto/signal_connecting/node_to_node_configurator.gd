@tool
extends PanelContainer
class_name NodeToNodeConfigurator

static func _open(anchor: Node, undo_redo: EditorUndoRedoManager):
	var i = preload("res://addons/pronto/signal_connecting/node_to_node_configurator.tscn").instantiate()
	i.anchor = anchor
	i.undo_redo = undo_redo
	return i

static func open_existing(undo_redo: EditorUndoRedoManager, from: Node, connection: Connection):
	var i = _open(Utils.parent_that(from, func (n): return Utils.has_position(n)), undo_redo)
	i.set_existing_connection(from, connection)
	Utils.spawn_popup_from_canvas(from, i)
	i.default_focus()

static func open_new_invoke(undo_redo: EditorUndoRedoManager, from: Node, source_signal: Dictionary, receiver: Node):
	var i = _open(Utils.parent_that(receiver, func (n): return Utils.has_position(n)), undo_redo)
	i.selected_signal = source_signal
	i.from = from
	i.receiver = receiver
	i.set_expression_mode(false)
	Utils.spawn_popup_from_canvas(receiver, i)
	i.default_focus()

static func open_new_expression(undo_redo: EditorUndoRedoManager, from: Node, source_signal: Dictionary):
	var i = _open(Utils.parent_that(from, func (n): return Utils.has_position(n)), undo_redo)
	i.selected_signal = source_signal
	i.from = from
	i.set_expression_mode(true)
	Utils.spawn_popup_from_canvas(from, i)
	i.default_focus()


var undo_redo: EditorUndoRedoManager

var anchor: Node:
	set(n):
		anchor = n
		size = Vector2.ZERO
		%FunctionName.anchor = n
var from: Node
var existing_connection = null

var selected_signal: Dictionary:
	set(value):
		selected_signal = value
		%Signal.text = Utils.print_signal(value)

func _input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_on_cancel_pressed()
	if (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed
		and not %FunctionName.has_focus()
		and (not %Expression.visible or event.ctrl_pressed)):
		_on_done_pressed()

var receiver: Object:
	set(value):
		receiver = value
		%ReceiverPath.text = "${0} ({1})".format([from.get_path_to(receiver), receiver.name])
		%FunctionName.anchor = anchor
		%FunctionName.node = receiver

func set_expression_mode(expr: bool):
	%Receiver.visible = not expr
	%Expression.visible = expr
	%Expression.text = ''

func default_focus():
	await get_tree().process_frame
	if %Expression.visible:
		%Expression.grab_focus()
	else:
		%FunctionName.grab_focus()

func _process(delta):
	if anchor and anchor.is_inside_tree():
		position = Utils.popup_position(anchor)
		%FunctionName.anchor = anchor

func set_existing_connection(from: Node, connection: Connection):
	self.from = from
	existing_connection = connection
	selected_signal = Utils.find(from.get_signal_list(), func (s): return s["name"] == connection.signal_name)
	if connection.is_target():
		receiver = from.get_node(connection.to)
		%FunctionName.anchor = anchor
		%FunctionName.text = connection.invoke
		_on_function_selected(connection.invoke)
	else:
		%Expression.text = connection.expression
	
	%Receiver.visible = connection.is_target()
	%Expression.visible = connection.is_expression()
	
	for i in range(%Args.get_child_count()):
		%Args.get_child(i).text = connection.arguments[i] if i <= connection.arguments.size() - 1 else ""

func _on_function_selected(name: String):
	var method = Utils.find(receiver.get_method_list(), func (m): return m["name"] == name)
	
	for child in %Args.get_children():
		%Args.remove_child(child)
		child.queue_free()
	
	if method == null:
		return
	
	var ArgUI = load("res://addons/pronto/signal_connecting/argument.tscn")
	for arg in method["args"]:
		var arg_ui = ArgUI.instantiate()
		arg_ui.arg_name = arg["name"]
		%Args.add_child(arg_ui)
	if not %Args.get_children().is_empty():
		%Args.get_children().back().is_last = true

func _on_done_pressed():
	if %Receiver.visible:
		var args = %Args.get_children().map(func (c): return c.text)
		var invoke = %FunctionName.text
		if invoke.length() == 0 or args.any(func (a): return a.length() == 0): return
		if existing_connection:
			Utils.commit_undoable(undo_redo,
				"Update connection {0}".format([selected_signal["name"]]),
				existing_connection,
				{"arguments": args, "invoke": invoke})
		else:
			Connection.connect_target(from, selected_signal["name"], from.get_path_to(receiver), invoke, args, undo_redo)
	if %Expression.visible:
		if existing_connection:
			Utils.commit_undoable(undo_redo,
				"Update connection {0}".format([selected_signal["name"]]),
				existing_connection,
				{"expression": %Expression.text})
		else:
			Connection.connect_expr(from, selected_signal["name"], %Expression.text, undo_redo)
	queue_free()

func _on_remove_pressed():
	if existing_connection:
		existing_connection.delete(from)
	queue_free()

func _on_cancel_pressed():
	queue_free()