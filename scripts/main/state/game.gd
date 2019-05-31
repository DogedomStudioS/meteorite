extends "res://scripts/fsm/fsm_state.gd"

var current_level = null # TODO why store both current_level and fsm_owner.current_level?
var player

func on_init():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	for c in get_children():
		c.queue_free()
		
	current_level = preload("res://scenes/levels/procedural_test_level.tscn").instance()
	add_child(current_level)
	fsm_owner.current_level = current_level
	
	# this will persist the state of the player
	# doesn't work when you do this in the exact same frame, need to wait 2 frames
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	Saver.do_load()
	
	# also, get rid of all pickups we already have
	
	player = PlayerData.get_player()
	var pickups = get_tree().get_nodes_in_group("pickup")
	for pickup in pickups:
		if player.is_unlocked(pickup.upgrade_name):
			print("deleted pickup ", pickup.upgrade_name)
			pickup.queue_free()
			
	# then play some music (TODO play different music depending on if boss defeated)
	Music.play("meteorite")
	if current_level.freezes_player == true:
		current_level.connect("unfreeze_player", self, "_on_unfreeze_player")

func _on_unfreeze_player():
	player.unlock_movement()
			
func on_finalize():
	current_level.queue_free()
	current_level = null
	fsm_owner.current_level = null