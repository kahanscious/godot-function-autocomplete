@tool
extends EditorPlugin

var current_editor: TextEdit = null
var last_checked_editor: ScriptEditorBase = null


func _enter_tree() -> void:
	set_process(true)


func _exit_tree() -> void:
	_disconnect_current_editor()
	set_process(false)


func _process(_delta: float) -> void:
	if not is_instance_valid(last_checked_editor):
		last_checked_editor = null
		current_editor = null

	var script_editor: ScriptEditor = get_editor_interface().get_script_editor()
	if not script_editor:
		return

	var editor: ScriptEditorBase = script_editor.get_current_editor()
	if editor != last_checked_editor:
		last_checked_editor = editor
		_update_current_editor(editor)


func _disconnect_current_editor() -> void:
	if is_instance_valid(current_editor) and current_editor.gui_input.is_connected(_on_gui_input):
		current_editor.gui_input.disconnect(_on_gui_input)
	current_editor = null


func _update_current_editor(editor: ScriptEditorBase) -> void:
	_disconnect_current_editor()

	if not is_instance_valid(editor):
		return

	var text_edit: TextEdit = editor.get_base_editor()
	if text_edit and is_instance_valid(text_edit):
		current_editor = text_edit
		if not current_editor.gui_input.is_connected(_on_gui_input):
			current_editor.gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if not is_instance_valid(current_editor):
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		var cursor_line: int = current_editor.get_caret_line()
		var current_line: String = current_editor.get_line(cursor_line)
		current_line = current_line.strip_edges(false, true)
		var parts: PackedStringArray = current_line.split(" ", false)

		if parts.size() >= 2 and parts[0] == "func":
			get_viewport().set_input_as_handled()

			var indent: String = ""
			for c in current_line:
				if c == " " or c == "\t":
					indent += c
				else:
					break

			# Get the initial function signature
			var func_signature: String = current_line.substr(current_line.find(parts[1]))
			var return_type: String = "void"

			# Handle return types in different scenarios
			if "->" in func_signature:
				var parts_arrow = func_signature.split("->", true, 1)
				return_type = parts_arrow[1].strip_edges()
				if return_type == "":
					return_type = "void"
				func_signature = parts_arrow[0].strip_edges()
				# Check for return type after complete parentheses
			elif ")" in func_signature:
				var after_paren = func_signature.split(")", true, 1)
				if after_paren.size() > 1:
					var potential_return = after_paren[1].strip_edges()
					if potential_return != "":
						return_type = potential_return
						func_signature = after_paren[0] + ")"
			# Check for return type without parentheses
			elif parts.size() > 2:
				var last_part = parts[-1]
				if not "(" in last_part:
					return_type = last_part
					func_signature = (
					func_signature
					. substr(0, func_signature.rfind(" " + last_part))
					. strip_edges()
					)

			# Handle incomplete parameter declarations
			if "(" in func_signature:
				# Get the part inside parentheses
				var param_start = func_signature.find("(")
				var param_end = func_signature.find(")")
				if param_end == -1:
					param_end = func_signature.length()

				var before_params = func_signature.substr(0, param_start + 1)
				var params = func_signature.substr(param_start + 1, param_end - param_start - 1)
				var after_params = (
									"" if param_end == func_signature.length() else func_signature.substr(param_end)
									)

				# Keep the parameter type if it exists
				if ":" in params:
					params = params.strip_edges()

				func_signature = before_params + params + (after_params if after_params else ")")
			else:
				func_signature += "()"

			# Remove any trailing colon
			if func_signature.ends_with(":"):
				func_signature = func_signature.substr(0, func_signature.length() - 1)

			var new_line: String = indent + "func " + func_signature + " -> " + return_type + ":"

			# Generate appropriate body based on return type
			var body_line: String
			if return_type == "void":
				body_line = indent + "\tpass"
			else:
				# Generate default return value based on type
				var default_value = ""
				match return_type:
					"bool":
						default_value = "false"
					"int":
						default_value = "0"
					"float":
						default_value = "0.0"
					"String":
						default_value = '""'
					"Array", "PackedStringArray", "PackedByteArray", "PackedInt32Array", "PackedInt64Array", "PackedFloat32Array", "PackedFloat64Array", "PackedVector2Array", "PackedVector3Array", "PackedColorArray":
						default_value = "[]"
					"Dictionary":
						default_value = "{}"
					_:
						default_value = "null"  # For all other types (objects, etc)
				body_line = indent + "\treturn " + default_value

			var current_scroll: int = current_editor.get_v_scroll()
			var full_text: String = current_editor.text
			var lines: PackedStringArray = full_text.split("\n")
			lines[cursor_line] = new_line
			lines.insert(cursor_line + 1, body_line)
			var new_text: String = "\n".join(lines)

			var undo_redo: EditorUndoRedoManager = get_undo_redo()
			undo_redo.create_action("Add Function Return Type")
			undo_redo.add_do_method(self, "_set_text", new_text)
			undo_redo.add_undo_method(self, "_set_text", full_text)
			undo_redo.commit_action()

			call_deferred("_update_caret", cursor_line + 1, indent.length() + 5, current_scroll)


func _set_text(text: String) -> void:
	if is_instance_valid(current_editor):
		current_editor.text = text


func _update_caret(line: int, column: int, scroll: int) -> void:
	if is_instance_valid(current_editor):
		current_editor.set_v_scroll(scroll)
		current_editor.set_caret_line(line)
		current_editor.set_caret_column(column)
		current_editor.grab_focus()
