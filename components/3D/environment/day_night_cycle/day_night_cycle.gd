@tool
@icon("res://components/3D/environment/day_night_cycle/day_night_cycle.svg")
class_name DayNightCycle extends Node

signal changed_day_zone(previous_zone: DayZone, new_zone: DayZone)
signal changed_day(previous_day: int, new_day: int)
signal changed_hour(previous_hour: int, new_hour: int)
signal changed_minute(previous_minute: int, new_minute: int)

const MinutesPerDay: float = 1440.0
const HoursPerDay: float = 24.0
const MinutesPerHour: float = 60.0

@export var enabled: bool = true
@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var sun_configuration: DayNightCycleSunConfiguration
@export var sky_configuration: DayNightCycleSkyConfiguration
@export var show_stars_at_night: bool = true
@export var show_moon_at_night: bool = true
@export_category("Time")
## Translated seconds into real life minute. This means that each 5 seconds a minute pass in the game.
@export var real_life_seconds_to_game_minute: float = 5.0:
	set(value):
		if value != real_life_seconds_to_game_minute:
			real_life_seconds_to_game_minute = maxf(0.1, value)
			_update_time_rate()
			
@export var start_day: int = 1:
	set(value):
		current_day = maxi(1, value)
		
@export_range(0, HoursPerDay - 1, 1) var start_hour: int = 0:
	set(value):
		start_hour = value
		
		if Engine.is_editor_hint():
			change_hour(start_hour)
			
@export_range(0, MinutesPerHour - 1, 1) var start_minute: int = 0:
	set(value):
		start_minute = value
		
		if Engine.is_editor_hint():
			change_minute(start_minute)
			
@export_category("Zone hours")
@export_range(0, HoursPerDay - 1, 1, "hour") var dawn_hour: int = 6
@export_range(0, HoursPerDay - 1, 1) var day_hour: int = 12
@export_range(0, HoursPerDay - 1, 1) var dusk_hour: int = 18
@export_range(0, HoursPerDay - 1, 1) var night_hour: int = 21

enum DayZone {
	Dawn,
	Day,
	Dusk,
	Night
}

var current_day: int = 1:
	set(value):
		if current_day != value:
			var new_day: int = maxi(1, value)
			changed_day.emit(current_day, new_day)
			current_day = new_day
			
var current_hour: int = -1: ## Important to keep the default value on -1 to not trigger the round logic
	set(value):
		if current_hour != value:
			
			if current_hour == (HoursPerDay - 1) and value == HoursPerDay:
				update_day(current_day + 1)
			elif current_hour == 0 and value == (HoursPerDay - 1):
				update_day(current_day - 1)

			@warning_ignore("narrowing_conversion")
			var new_hour: int = clampi(value, 0, HoursPerDay - 1)
			changed_hour.emit(current_hour, new_hour)
			current_hour = new_hour
			
var current_minute: int = -1:## Important to keep the default value on -1 to not trigger the round logic
	set(value):
		if current_minute != value:
			if value == MinutesPerHour:
				current_hour += 1
			
			elif current_minute == 0 and value == MinutesPerHour - 1:
				current_hour -= 1
				
			@warning_ignore("narrowing_conversion")
			var new_minute: int = clampi(value, 0,  MinutesPerHour - 1)
			changed_minute.emit(current_minute, new_minute)
			current_minute = new_minute
			
var current_day_zone: DayZone = DayZone.Day:
	set(value):
		if current_day_zone != value:
			changed_day_zone.emit(current_day_zone, value)
			current_day_zone = value

var time: float = 0.0:
	set(value):
		time = clampf(value, 0.0, 1.0)
var time_rate: float = 0.0


func _ready() -> void:
	_update_time_rate()
	update_current_time(start_hour, start_minute)
	_update_time_sampler()
	call_deferred("set_process", enabled and not Engine.is_editor_hint())
	

func _process(delta: float) -> void:
	time += time_rate * delta
		
	if time >= 1.0:
		time = 0.0
	
	if Engine.get_process_frames() % 30 == 0:
		var total_minutes_in_day = time * MinutesPerDay

		var hour = floor(total_minutes_in_day / MinutesPerHour)
		var minute = fmod(total_minutes_in_day, MinutesPerHour)
		update_current_time(hour, minute)


func enable() -> void:
	enabled = true
	
	
func disable() -> void:
	enabled = false
	

func _update_time_rate(seconds_per_minute: float = real_life_seconds_to_game_minute) -> void:
	time_rate = 1.0 / (MinutesPerDay * seconds_per_minute)


func _update_time_sampler(hour: int = current_hour, minute: int = current_minute) -> void:
	time = (hour + (minute / MinutesPerHour)) / HoursPerDay


func seconds(hour: int = current_hour, minute: int = current_minute) -> int:
	@warning_ignore("narrowing_conversion")
	return (hour * MinutesPerHour * MinutesPerHour) + minute * MinutesPerHour


func time_display(hour: int = current_hour, minute: int = current_minute) -> String:
	var hour_str: String = str(hour)
	var minute_str: String = str(minute)
	
	if hour < 10:
		hour_str = "0" + str(hour)
		
	if minute < 10:
		minute_str = "0" + str(minute)
	
	return "%s:%s" % [hour_str, minute_str] 


func start(hour: int = current_hour, minute: int = current_minute) -> void:
	update_current_time(hour, minute)
	_update_time_sampler()
	call_deferred("set_process", true)


func stop() -> void:
	set_process(false)


func change_time(new_hour: int, new_minute: int) -> void:
	update_current_time(new_hour, new_minute)
	_update_time_sampler()
	

func change_hour(new_hour: int) -> void:
	update_current_time(new_hour, current_minute)
	_update_time_sampler()
	
	
func change_minute(new_minute: int) -> void:
	update_current_time(current_hour, new_minute)
	_update_time_sampler()


func update_day(day: int) -> void:
	current_day = day
	

func update_current_time(hour: int, minute: int) -> void:
	current_hour = hour
	current_minute = minute
	
	update_day_zone()
	update_sun()
	update_sky()


func update_sun(hour: int = current_hour, minute: int = current_minute) -> void:
	if sun:
		var current_time: float = hour + (minute / MinutesPerHour)
		
		if sun_configuration:
			sun.light_energy = sun_configuration.intensity.sample(current_time)
			sun.light_color = sun_configuration.color_gradient.sample(current_time / HoursPerDay)
					
		## We increase here the maximum hour to extend the visibility of the sun in the horizon
		## With default values, the sunset happens more or less at 18:30, just increase the maximum hour
		## to extend the sun visibility during the day (25.0 instead of 23.59)
		var sun_angle: float = (current_time / 25.0) * 360.0 + 90.0
		sun.rotation_degrees.x = sun_angle
		
		## Optimization to not render dynamic shadows when the sun is not in the screen
		var normalized_angle: float = fmod(sun_angle, 360.0)
		sun.shadow_enabled = normalized_angle > 169.0 and normalized_angle < 360.0
		

func update_sky(hour: int = current_hour, minute: int = current_minute) -> void:
	if world_environment and world_environment.environment:
		var sky: Sky = world_environment.environment.sky
		
		if sky:
			var sky_material: ShaderMaterial = world_environment.environment.sky.sky_material
			
			if sky_material:
				var current_time: float = hour + (minute / MinutesPerHour)
				var time_sample: float =  current_time / HoursPerDay
				
				if sky_configuration:
					world_environment.environment.background_energy_multiplier = sky_configuration.light_intensity.sample(current_time)
				
					sky_material.set_shader_parameter("sky_top_color", sky_configuration.top_color_gradient.sample(time_sample))
					sky_material.set_shader_parameter("sky_horizon_color", sky_configuration.horizon_color_gradient.sample(time_sample))
					sky_material.set_shader_parameter("ground_horizon_color", sky_configuration.ground_horizon_color_gradient.sample(time_sample))
					sky_material.set_shader_parameter("ground_bottom_color", sky_configuration.ground_bottom_color_gradient.sample(time_sample))
					sky_material.set_shader_parameter("sky_cover_modulate", sky_configuration.clouds_color_gradient.sample(time_sample))
					sky_material.set_shader_parameter("stars", show_stars_at_night and is_night())
					sky_material.set_shader_parameter("moon", show_moon_at_night and is_night())
					
					if show_moon_at_night and is_night():
						var moon_angle: float = -sun.rotation_degrees.x + 180.0
			
						# Convierte ese ángulo a una dirección 3D
						var moon_dir: Vector3 = Vector3(
							cos(deg_to_rad(moon_angle)),
							sin(deg_to_rad(moon_angle)),
							0.0
						).normalized()
			
						# Enviamos al shader
						sky_material.set_shader_parameter("moon_direction", moon_dir)


func update_day_zone(hour: int = current_hour) -> void:
	if not is_dawn() and hour >= dawn_hour and hour < day_hour:
		current_day_zone = DayZone.Dawn
		
	elif not is_day() and hour >= day_hour and hour < dusk_hour:
		current_day_zone = DayZone.Day
		
	elif not is_dusk() and hour >= dusk_hour and hour < night_hour:
		current_day_zone = DayZone.Dusk
		
	elif not is_night() and hour >= night_hour and hour <= HoursPerDay - 1:
		current_day_zone = DayZone.Night


func is_dawn() -> bool:
	return current_day_zone == DayZone.Dawn;

func is_day() -> bool:
	return current_day_zone == DayZone.Day;
	
func is_dusk() -> bool:
	return current_day_zone == DayZone.Dusk;
	
func is_night() -> bool:
	return current_day_zone == DayZone.Night;

func is_am() -> bool:
	return current_hour < (HoursPerDay / 2)

func is_pm() -> bool:
	return current_hour >= (HoursPerDay / 2)
