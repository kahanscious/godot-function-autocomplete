@tool
extends EditorPlugin

var current_editor: TextEdit = null
var last_checked_editor = null


func _enter_tree() -> void:
	set_process(true)


func _exit_tree() -> void:
	if current_editor and current_editor.gui_input.is_connected(_on_gui_input):
		current_editor.gui_input.disconnect(_on_gui_input)
	set_process(false)


func _process(_delta: float) -> void:
	var script_editor = get_editor_interface().get_script_editor()
	var editor = script_editor.get_current_editor()

	if editor != last_checked_editor:
		last_checked_editor = editor
		_update_current_editor(editor)


func _update_current_editor(editor) -> void:
	if current_editor and current_editor.gui_input.is_connected(_on_gui_input):
		current_editor.gui_input.disconnect(_on_gui_input)
		current_editor = null

	if editor:
		var text_edit = editor.get_base_editor()
		if text_edit:
			current_editor = text_edit
			if not current_editor.gui_input.is_connected(_on_gui_input):
				current_editor.gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if not current_editor:
		return

	# Only trigger on Tab key
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		var cursor_line = current_editor.get_caret_line()
		var current_line = current_editor.get_line(cursor_line)

		# Remove any trailing whitespace
		current_line = current_line.strip_edges(false, true)

		# Check if line matches our pattern
		var parts = current_line.split(" ")

		# Check if this is a function declaration
		if parts[0] == "func" and "(" in current_line and ")" in current_line:
			get_viewport().set_input_as_handled()

			var return_type = "void"  # Default type
			var func_part = current_line  # Default to whole line

			# If there's a type specified after the parentheses
			if parts.size() >= 3:
				return_type = parts[-1]
				func_part = current_line.substr(0, current_line.rfind(" " + return_type))

			# Get the indent level
			var indent = ""
			for c in current_line:
				if c == " " or c == "\t":
					indent += c
				else:
					break

			# Create the new line
			var new_line = func_part + " -> " + return_type + ":"

			# Create the undo/redo action
			var undo_redo = get_undo_redo()
			undo_redo.create_action("Add Function Return Type")

			# Store the current state for undo
			undo_redo.add_do_method(self, "_set_line", cursor_line, new_line)
			undo_redo.add_do_method(self, "_insert_line", cursor_line + 1, indent + "\tpass")
			undo_redo.add_undo_method(self, "_set_line", cursor_line, current_line)
			undo_redo.add_undo_method(self, "_remove_line", cursor_line + 1)

			# Commit the action
			undo_redo.commit_action()

			# Move cursor to the pass line
			current_editor.set_caret_line(cursor_line + 1)
			current_editor.set_caret_column((indent + "\tpass").length())


# Helper methods for undo/redo operations
func _set_line(line: int, text: String) -> void:
	if current_editor:
		current_editor.set_line(line, text)


func _insert_line(line: int, text: String) -> void:
	if current_editor:
		current_editor.insert_line_at(line, text)


func _remove_line(line: int) -> void:
	if current_editor:
		current_editor.remove_line(line)
