extends KinematicBody
 
const MOVE_SPEED = 2.6
 
onready var raycast = $RayCast
onready var anim_player = $AnimationPlayer

var health = 10
var player = null
var dead = false
var attack_timing: float = 1.8
var attack_timer: float = 0.0
 
func _ready():
	anim_player.play("walk")
	add_to_group("enemy")
	set_player(PlayerData.get_player())
 
func _physics_process(delta):
	if dead:
		return
	if player == null:
		return
	var vec_to_player = player.translation - translation
	vec_to_player = vec_to_player.normalized()
	raycast.cast_to = vec_to_player * 1.5
	move_and_collide(vec_to_player * MOVE_SPEED * delta)
	attack_timer += delta
	if attack_timer >= attack_timing:
		attack_timer = 0.0
		if raycast.is_colliding():
			var coll = raycast.get_collider()
			if coll != null and coll.name == "player":
				coll.hurt(10)

func hurt(amount, color):
	health -= amount
	if health <= 0:
		kill()
   
 
func kill():
    dead = true
    $CollisionShape.disabled = true
    anim_player.play("die")
 
func set_player(p):
    player = p