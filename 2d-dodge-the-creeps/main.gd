extends Node

@export var mob_scene: PackedScene
var score

func _ready():
	# NUEVO: asegura que "hit" del Player siempre dispare game_over,
	# aunque la conexión manual en el editor se haya perdido.
	if not $Player.hit.is_connected(game_over):
		$Player.hit.connect(game_over)


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()


func new_game():
	get_tree().call_group(&"mobs", &"queue_free")
	score = 0
	$Player.start($StartPosition.position)
	$Player.update_score(score) # NUEVO: reinicia la puntuación que conoce el jugador
	$Player.reset_shield() # NUEVO: permite volver a usar el escudo en la nueva partida
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Music.play()


func _on_MobTimer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = get_node(^"MobPath/MobSpawnLocation")
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to a random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)


func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)
	$Player.update_score(score) # NUEVO: le avisa al jugador de la puntuación actual
	

func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
