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

			# Get the function name (second part after "func")
			var func_name: String = parts[1]

			# Initialize with void return type
			var return_type: String = "void"

			# If there are more parts and the last part doesn't contain parentheses,
			# it might be the return type
			if parts.size() >= 3:
				var last_part = parts[-1]
				if not ("(" in last_part or ")" in last_part):
					return_type = last_part
					func_name = (
					current_line
					. substr(
						current_line.find(parts[1]),
						current_line.rfind(" " + return_type) - current_line.find(parts[1])
					)
					. strip_edges()
					)

			# Add parentheses if they're missing
			if not "(" in func_name:
				func_name += "()"

			var new_line: String = indent + "func " + func_name + " -> " + return_type + ":"
			var pass_line: String = indent + "\tpass"

			var current_scroll: int = current_editor.get_v_scroll()
			var full_text: String = current_editor.text
			var lines: PackedStringArray = full_text.split("\n")
			lines[cursor_line] = new_line
			lines.insert(cursor_line + 1, pass_line)
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
