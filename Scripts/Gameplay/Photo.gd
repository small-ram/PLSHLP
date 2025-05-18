# scripts/Gameplay/Photo.gd
extends Area2D
signal snapped(photo, slot)

@export var dialog_id : String = "" # which dialogue the photo triggers after snapping
@export var memory_id   : String          # which MemorySlot this photo belongs to
@export var snap_radius : float = 100.0   # pixels

@onready var sprite := $Sprite2D

var _dragging     : bool    = false
var _drag_offset  : Vector2 = Vector2.ZERO
var _snapped      : bool    = false      # so Stage-4 can unlock us safely

func _ready() -> void:
	# Pickable → Godot will forward _input_event automatically;
	# no need for an extra has_point() test.
	set_pickable(true)
	# (Optional) lets StageController find all photos later.
	add_to_group("photos")

# ------------------------------------------------------------------  
# DRAG–DROP HANDLING
# ------------------------------------------------------------------  
func _input_event(_viewport, event, _shape_idx) -> void:
	if _snapped:          # locked after a successful snap
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start dragging
			_dragging    = true
			_drag_offset = global_position - event.position
			move_to_front()                       # bring to top of draw order
		else:
			# Mouse released
			if _dragging:
				_dragging = false
				_try_snap()

func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseMotion:
		global_position = event.position + _drag_offset

# ------------------------------------------------------------------  
# SNAP-TO-SLOT LOGIC
# ------------------------------------------------------------------  
func _try_snap() -> void:
	var slot := _get_slot_for_memory()
	if slot and global_position.distance_to(slot.global_position) <= snap_radius:
		_snap_to_slot(slot)

func _get_slot_for_memory() -> Area2D:
	for s in get_tree().get_nodes_in_group("memory_slots"):
		if s.memory_id == memory_id:
			return s
	return null

func _snap_to_slot(slot: Area2D) -> void:
	_snapped = true
	global_position = slot.global_position
	set_pickable(false)        # lock until Stage-4 cleanup
	move_to_front()            # stay visually above the slot
	emit_signal("snapped", self, slot)
	if dialog_id != "":
		DialogueManager.load_tree(dialog_id)

# ------------------------------------------------------------------  
# CALLED BY STAGECONTROLLER DURING THE CLEANUP PHASE
# ------------------------------------------------------------------  
func unlock_for_cleanup() -> void:
	if !_snapped:
		return
	_snapped = false
	set_pickable(true)
