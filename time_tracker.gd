@tool
extends EditorPlugin

var dock: VBoxContainer
var session_label: Label
var total_label: Label

# The path to save the time data
const SAVE_PATH := "user://time_tracker.save"

# Track time in seconds
var session_time := 0.0
var total_time := 0.0

# Store the last known time to save to prevent excessive disk writes
var last_save_time := 0.0

# --- Plugin Lifecycle ---
func _enter_tree():
	# Load previous total time
	total_time = _load_total_time()
	session_time = 0.0
	last_save_time = total_time

	# Create the UI dock
	dock = VBoxContainer.new()
	dock.name = "Time Tracker"

	var title = Label.new()
	title.text = "⏱ Project Time Tracker"
	title.add_theme_font_size_override("font_size", 14)
	dock.add_child(title)

	session_label = Label.new()
	session_label.text = "Session: 0m 0s"
	dock.add_child(session_label)

	total_label = Label.new()
	total_label.text = _format_time(total_time)
	dock.add_child(total_label)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree():
	_save_total_time(total_time)
	if dock:
		remove_control_from_docks(dock)
		dock.free()

func _process(delta):
	# Update time counters
	session_time += delta
	total_time += delta

	# Update labels
	session_label.text = "Session: %s" % _format_time_simple(session_time)
	total_label.text = "Total: %s" % _format_time(total_time)

	# Save every minute to prevent data loss from crashes
	if floor(total_time / 60) > floor(last_save_time / 60):
		_save_total_time(total_time)
		last_save_time = total_time
		print("Time saved automatically at ", int(total_time), " seconds")

# --- Helper Functions ---
func _format_time(time_in_seconds: float) -> String:
	var hours = floor(time_in_seconds / 3600)
	var minutes = floor(fmod(time_in_seconds, 3600) / 60)
	var seconds = floor(fmod(time_in_seconds, 60))
	return "%dh %dm %ds" % [hours, minutes, seconds]

func _format_time_simple(time_in_seconds: float) -> String:
	var minutes = floor(time_in_seconds / 60)
	var seconds = floor(fmod(time_in_seconds, 60))
	return "%dm %ds" % [minutes, seconds]

# --- Save/Load Functions ---
func _save_total_time(t: float):
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(t)
		f.close()

func _load_total_time() -> float:
	if FileAccess.file_exists(SAVE_PATH):
		var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var t = f.get_var()
			f.close()
			if typeof(t) == TYPE_FLOAT || typeof(t) == TYPE_INT:
				return float(t)
	return 0.0
