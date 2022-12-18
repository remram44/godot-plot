extends Control

# The font to use for the  ticks
@export var font: Font = null

# The length of the horizontal axis (usually seconds)
@export var x_axis: float = 10.0

# The speed at which the axis will adjust to changed data range
@export var lerp_axis: float = 0.1

const COLORS = [
	Color(1.0, 0.0, 0.0, 1.0),
	Color(0.0, 1.0, 0.0, 1.0),
	Color(0.0, 0.0, 1.0, 1.0),
	Color(1.0, 1.0, 0.0, 1.0),
	Color(1.0, 0.0, 1.0, 1.0),
	Color(0.0, 1.0, 1.0, 1.0),
]

var curves = {}
var curve_colors = {}
var current_time: float = 0.0
var y_min: float = INF
var y_max: float = -INF

func _process(delta):
	current_time += delta
	queue_redraw()

func get_ticks(low: float, high: float, minimum: int):
	# Choose interval
	var e = floor(log((high - low) / minimum) / log(10))
	var fmt = "%.0f"
	if e < 0:
		fmt = "%%.%df" % (-e)
	var interval = pow(10, e)
	if (high - low) / interval > 5 * minimum:
		interval *= 5

	# List ticks
	var low_i = ceil(low / interval)
	var high_i = floor(high / interval)
	var ticks = []
	for tick_i in range(low_i, high_i + 1):
		ticks.append([tick_i * interval, fmt % (tick_i * interval)])
	return ticks

func _draw():
	var new_y_min = +INF
	var new_y_max = -INF

	# Compute range of data
	for array in curves.values():
		for i in range(len(array)):
			new_y_min = min(new_y_min, array[i][1])
			new_y_max = max(new_y_max, array[i][1])

	if new_y_min == INF:
		# No data
		y_min = INF
		y_max = -INF
		return

	# Update displayed range
	if y_min == INF:
		y_min = new_y_min
		y_max = new_y_max
	else:
		y_min = lerp(y_min, new_y_min, lerp_axis)
		y_max = lerp(y_max, new_y_max, lerp_axis)

	# Compute plot area
	var area_pos = Vector2(28, 2)
	var area_size = size - Vector2(30, 17)

	# Draw axes
	draw_line(area_pos, area_pos + Vector2(0.0, area_size.y), Color(1.0, 1.0, 1.0, 1.0))
	if y_max > 0.0 and y_min < 0.0:
		var axis = y_max / (y_max - y_min) * area_size.y
		draw_line(area_pos + Vector2(0.0, axis), area_pos + Vector2(area_size.x, axis), Color(1.0, 1.0, 1.0, 1.0))
	draw_line(area_pos + Vector2(0.0, area_size.y), area_pos + area_size, Color(1.0, 1.0, 1.0, 1.0))

	# Horizontal ticks
	for tick in get_ticks(current_time - x_axis, current_time, area_size.x / 50):
		var text = tick[1]
		tick = tick[0]

		var x = (tick - (current_time - x_axis)) / x_axis * area_size.x
		draw_line(area_pos + Vector2(x, area_size.y), area_pos + Vector2(x, area_size.y + 4), Color(1.0, 1.0, 1.0, 1.0))
		draw_string(
			font,
			area_pos + Vector2(
				x - 0.5 * font.get_string_size(text).x,
				area_size.y + font.get_ascent() + 2
			),
			text,
			0, -1, 12,
			Color(1.0, 1.0, 1.0, 1.0)
		)

	# Vertical ticks
	for tick in get_ticks(y_min, y_max, area_size.y / 50):
		var text = tick[1]
		tick = tick[0]

		var y = (y_max - tick) / (y_max - y_min) * area_size.y
		draw_line(area_pos + Vector2(0.0, y), area_pos + Vector2(-4.0, y), Color(1.0, 1.0, 1.0, 1.0))
		draw_string(
			font,
			area_pos + Vector2(
				-4 - font.get_string_size(text).x,
				y + font.get_ascent() - 0.5 * font.get_height()
			),
			text,
			0, -1, 12,
			Color(1.0, 1.0, 1.0, 1.0)
		)

	for name in curves.keys():
		# Pick color
		if not curve_colors.has(name):
			for i in range(len(COLORS)):
				var in_use = false
				for c in curve_colors.values():
					if c == COLORS[i]:
						in_use = true
						break
				if not in_use:
					curve_colors[name] = COLORS[i]
					break
			if not curve_colors.has(name):
				curve_colors[name] = Color(1.0, 1.0, 1.0, 1.0)

		# Draw
		draw_curve(name, curves[name], curve_colors[name], area_pos, area_size)

func draw_curve(name: String, array: Array, color: Color, area_pos: Vector2, area_size: Vector2):
	var points = PackedVector2Array()
	for i in range(len(array)):
		var x = array[i][0]
		x = (x - (current_time - x_axis)) / x_axis * area_size.x + area_pos.x
		var y = array[i][1]
		y = (y_max - y) / (y_max - y_min) * area_size.y + area_pos.y
		points.append(Vector2(x, y))
	points.append(points[-1])

	draw_polyline(points, color)

func set_curve_color(name: String, color: Color):
	curve_colors[name] = color

# Set a whole curve at once
func set_curve(name: String, array: Array):
	var pos = 0
	while pos < len(array) and array[pos][0] < current_time - x_axis:
		pos += 1
	if pos > 0:
		array = array.slice(pos, len(array) - 1)
	curves[name] = array

# Remove a curve from the graph
func remove_curve(name: String) -> bool:
	return curves.erase(name)

# Add a point to a curve at a X position
func add_point(name: String, x_value: float, y_value: float) -> void:
	var array
	if not curves.has(name):
		array = []
		curves[name] = array
	else:
		array = curves[name]
	array.append([x_value, y_value])

	var pos = 0
	while pos < len(array) and array[pos][0] < current_time - x_axis:
		pos += 1
	if pos > 0:
		curves[name] = array.slice(pos, len(array) - 1)

# Add a point to a curve using the current time as X position
func record_point(name: String, value: float) -> void:
	add_point(name, current_time, value)
