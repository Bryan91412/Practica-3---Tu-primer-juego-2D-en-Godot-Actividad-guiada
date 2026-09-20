extends Area2D

signal hit

@export var speed = 400 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

# --- NUEVO: variables para la mecánica del escudo ---
var current_score = 0            # Puntuación actual (Main la actualiza cada punto).
var shield_active = false        # true mientras el escudo está absorbiendo un golpe.
var shield_available = false     # true cuando tienes una carga de escudo lista para usar.
var next_shield_score = 10       # Puntuación a la que se otorga la siguiente carga.
const SHIELD_SCORE_INTERVAL = 10 # Cada cuántos puntos se recarga el escudo.
# -------------------------------------------------------

func _ready():
	screen_size = get_viewport_rect().size
	hide()


func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed(&"move_right"):
		velocity.x += 1
	if Input.is_action_pressed(&"move_left"):
		velocity.x -= 1
	if Input.is_action_pressed(&"move_down"):
		velocity.y += 1
	if Input.is_action_pressed(&"move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = &"right"
		$AnimatedSprite2D.flip_v = false
		$Trail.rotation = 0
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = &"up"
		rotation = PI if velocity.y > 0 else 0


# --- NUEVO: detecta la tecla E para activar el escudo (no requiere tocar el Input Map) ---
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_try_activate_shield()


func _try_activate_shield():
	if shield_active:
		return # Ya está activo, no hace falta nada más.
	if not shield_available:
		return # No hay ninguna carga lista todavía.
	shield_active = true
	shield_available = false
	modulate = Color(0.4, 0.8, 1.0, 0.8) # Tinte azulado para avisar que el escudo está activo.


func update_score(new_score):
	current_score = new_score
	# NUEVO: cada vez que se cruza un múltiplo de SHIELD_SCORE_INTERVAL, se otorga una carga.
	while current_score >= next_shield_score:
		shield_available = true
		next_shield_score += SHIELD_SCORE_INTERVAL


func reset_shield():
	# NUEVO: llamar esto al empezar una partida nueva.
	shield_active = false
	shield_available = false
	next_shield_score = SHIELD_SCORE_INTERVAL
	modulate = Color(1, 1, 1, 1)
# --------------------------------------------------------------------------------------------


func start(pos):
	position = pos
	rotation = 0
	show()
	$CollisionShape2D.disabled = false


func _on_body_entered(_body):
	# --- NUEVO: si el escudo está activo, absorbe el golpe y se gasta ---
	if shield_active:
		shield_active = false
		modulate = Color(1, 1, 1, 1) # Vuelve al color normal, el escudo se gastó.
		return
	# ------------------------------------------------------------------------------------
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred(&"disabled", true)
