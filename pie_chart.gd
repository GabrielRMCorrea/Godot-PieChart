## A configurable pie/doughnut chart node with dynamic legends and color schemes.
## [b]Usage:[/b] Assign data via the [code]elements[/code] property and customize styles in the inspector.
class_name PieChart
extends Control

enum ColorScaleOptions {
	## Vibrating colors.
	ALTERNATING_HUE,
	## Pastel colors.
	OKHSL,
	## Custom gradient (assign [code]scale_gradient[/code]).
	GRADIENT_,
	## Manually specify colors in [code]custom_scale[/code] (colors will repeat itself if custom_scale array size is smaller than the number of elements with value >0).
	CUSTOM,
}

enum LegendStyleOptions {
	## Labels connected to slices with lines
	DIRECT_LINE,
	## Labels placed near slices.
	DIRECT_LABEL,
	## Legend displayed on the right side.
	SIDE_LEGEND,
}

enum LabelVisibilityOptions {
	## Labels only show percentages
	ONLY_PERCENTAGES,
	## Labels only show data distribution
	ONLY_DATA,
	## Labels shows both, data and percentages
	DATA_AND_PERCENTAGES
}
## Data to visualize. Keys are labels (e.g., "Category A"), values are numbers.
## [b]Note:[/b] Values <= 0 will be ignored.
@export var elements: Dictionary[String, float]
@export_category("Text Management")
@export var title: String
@export var legend_style: LegendStyleOptions = LegendStyleOptions.DIRECT_LINE
@export var use_translation_server: bool = true
@export var data_prefix: String = ""
@export var data_suffix: String = ""
@export var label_visibility: LabelVisibilityOptions = LabelVisibilityOptions.ONLY_PERCENTAGES
@export_category("Doughnut Shape")
@export var doughnut_shape: bool = true
## Text displayed at the center of the chart (only for doughnut shapes).
@export var center_text: String  # if doughnut_shape
@export var center_proportion: float = 60.0  # if doughnut_shape
@export_category("Color Scale")
@export var color_scale: ColorScaleOptions = ColorScaleOptions.ALTERNATING_HUE
@export var scale_gradient: Gradient  # if color_scale == GRADIENT_
@export var custom_scale: Array[Color]  # if color_scale == CUSTOM
## Border visibility toggles. All borders use [code]border_color[/code]
@export_category("Borders")
@export var outer_border : bool = false
@export var inner_border : bool = false
@export var lateral_borders : bool = false

@export_group("Style Properties")
@export var title_text_color: Color = Color.WHITE
@export var title_font_size: int = 16
@export var elements_text_color: Color = Color.WHITE
@export var elements_font_size: int = 16
@export var center_color: Color = Color.WHITE
@export var center_text_color: Color = Color.BLACK
@export var center_text_font_size: int = 16
@export var line_color: Color = Color.WHITE
@export var border_color: Color = Color.WHITE
@export var border_width: float = 1
@export var font : Font = ThemeDB.fallback_font

## Draws a chart slice between two angles.
## [b]Note:[/b] Called automatically during [method _draw].
## @param center: Chart center position in pixels.
## @param radius: Outer radius of the slice.
## @param angle_from: Starting angle (degrees).
## @param angle_to: Ending angle (degrees).
## @param color: Fill color for the slice.
func draw_slice(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color) -> void:
	var nb_points: int = round((angle_to-angle_from)/5)
	var outer_arc: Array[Vector2] = []
	var inner_arc: Array[Vector2] = []

	if doughnut_shape:
		for i in range(nb_points + 1):
			var angle_point: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
			inner_arc.push_front(center + Vector2(cos(angle_point), sin(angle_point)) * (radius*center_proportion/100))
	else:
		inner_arc.push_back(center)
	
	for i in range(nb_points + 1):
		var angle_point: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
		outer_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	draw_colored_polygon(inner_arc + outer_arc, color)
	if inner_border and doughnut_shape:
		draw_polyline(inner_arc, border_color, border_width, true)
	if outer_border:
		draw_polyline(outer_arc, border_color, border_width, true)

func _draw() -> void:
	check_warnings()
	var radius: float = min(size.x, size.y) / 4.0
	var center: Vector2 = Vector2(
		size.x / (3.0 if legend_style == LegendStyleOptions.SIDE_LEGEND else 2.0),
		size.y / 2.0
	)
	var previous_angle: float = 0.0
	var counter: int = 0
	var values: Array = elements.values().filter(func(number): return number > 0)
	var values_size: int = values.size()
	var total: float = values.reduce(func sum(accum, number): return accum + number) if values else 0.0
	var separation_lines_parameters: Array = []
	var max_decimal_step : int = values.map(func(x): return(String.num(x).rsplit(".")[1].trim_suffix("0").length() )).max()

	for key: String in elements:
		if elements[key] <= 0.0:
			continue

		# Choosing color
		var color: Color
		match color_scale:
			ColorScaleOptions.ALTERNATING_HUE:
				@warning_ignore("integer_division")
				color = Color.from_hsv(
					1.0 / (values_size + 1) * counter / 2 if counter % 2 == 0 
						else 1.0 / (values_size + 1) * (values_size - counter / 2),
					0.6 if counter % 4 < 2 else 0.8,
					0.9
				)
			
			ColorScaleOptions.OKHSL:
				color = Color.from_ok_hsl(
					1.0 / values_size * counter,
					1.0,
					0.8 if counter % 2 else 0.5
				)
			
			ColorScaleOptions.GRADIENT_:
				if scale_gradient:
					color = scale_gradient.sample(float(counter) / (values_size - 1))
			
			ColorScaleOptions.CUSTOM:
				if custom_scale:
					color = custom_scale[counter % custom_scale.size()]
		
		counter += 1
		
		# Drawing elements
		var percentage: float = elements[key] / (total / 100.0)
		var current_angle: float = 360.0 * (percentage / 100.0)
		var angle: float = deg_to_rad(current_angle + previous_angle)
		var mid_angle: float = angle - deg_to_rad(current_angle / 2.0)
		var angle_point: Vector2 = Vector2(cos(mid_angle), sin(mid_angle)) * radius
		
		# The text labels, such as Data name, Data itself and the percentage of distribution
		var text := ""
		var label_sep := " - " if legend_style == LegendStyleOptions.SIDE_LEGEND else "\n"
		text += uses_translate_server(key)
		if label_visibility in [LabelVisibilityOptions.ONLY_DATA, LabelVisibilityOptions.DATA_AND_PERCENTAGES]:
			text += label_sep + data_prefix + String.num(elements[key]).pad_decimals(max_decimal_step) + data_suffix
		if label_visibility in [LabelVisibilityOptions.ONLY_PERCENTAGES, LabelVisibilityOptions.DATA_AND_PERCENTAGES]:
			text += label_sep + str(snappedf(percentage, 0.01)).pad_decimals(2) + "%"
			
			
		var label_size: Vector2 = font.get_multiline_string_size(
			text, HORIZONTAL_ALIGNMENT_CENTER
		)
		
		var label_center: Vector2 = Vector2(label_size.x / 2.0, label_size.y / 8.0)
		var label_position: Vector2
		
		match legend_style:
			LegendStyleOptions.DIRECT_LINE:
				label_position = center - label_center + angle_point * 1.55
				draw_line(
					angle_point * 1.05 + center,
					angle_point * 1.2 + center,
					line_color,
					2.0,
					true
				)
			
			LegendStyleOptions.DIRECT_LABEL:
				var dir_sign: Vector2 = Vector2(sign(cos(mid_angle)), sign(sin(mid_angle)))
				var offset: Vector2 = Vector2(
					dir_sign.x * label_size.x / 2.0,
					dir_sign.y * label_size.y / 2.0
				)
				label_position = center - label_center + angle_point * 1.05 + offset
			
			LegendStyleOptions.SIDE_LEGEND:
				label_position.x = size.x - label_size.x - (radius / 5.0) - label_size.y
				label_position.y = label_size.y + (label_size.y + 5.0) * counter + (radius / 5.0)
				draw_rect(
					Rect2(
						Vector2(
							size.x - (radius / 7.0) - label_size.y,
							(label_size.y + 5.0) * counter + (radius / 5.0) + 5.0
						),
						Vector2.ONE * label_size.y
					),
					color
				)
		
		draw_multiline_string(
			font,
			label_position,
			text,
			HORIZONTAL_ALIGNMENT_RIGHT if legend_style == LegendStyleOptions.SIDE_LEGEND \
				else HORIZONTAL_ALIGNMENT_CENTER,
			label_size.x,
			elements_font_size,
			-1,
			elements_text_color
		)
		
		draw_slice(center, radius, previous_angle, previous_angle + current_angle, color)
		separation_lines_parameters.append([
			center + Vector2(cos(angle), sin(angle)) * (radius*center_proportion/100) if doughnut_shape else center,
			center + Vector2(cos(angle), sin(angle)) * radius,
			border_color,
			border_width,
			true
		])
		previous_angle += current_angle
	
	draw_multiline_string(
		font,
		Vector2(35.0, 35.0),
		uses_translate_server(title),
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x -40,
		title_font_size,
		-1,
		title_text_color
	)
	
	if lateral_borders:
		for params in separation_lines_parameters:
			draw_line.callv(params)
	
	if doughnut_shape:
		draw_circle(center, (radius * center_proportion / 100.0) - (border_width if inner_border else 0.0) , center_color, true, -1, true)
		var label_size: Vector2 = font.get_multiline_string_size(center_text,HORIZONTAL_ALIGNMENT_CENTER,
			radius,
			center_text_font_size,
			-1,
			TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)

		draw_multiline_string(
			font,
			center - Vector2(radius/2,(label_size.y/23 -1) * 6 -6),
			uses_translate_server(center_text),
			HORIZONTAL_ALIGNMENT_CENTER,
			radius,
			center_text_font_size,
			-1,
			center_text_color,
			TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
		)

func set_new_data(data: Dictionary[String, float]) -> void:
	elements = data
	queue_redraw()

func uses_translate_server(text: String) -> String:
	if use_translation_server:
		return tr(text)
	else:
		return text

func check_warnings() -> void:
	if not elements.values().filter(func(number): return number > 0):
		var data: Dictionary[String, float] = { #draws empty graph, instead of no graph
			"" : 0
		}
		set_new_data(data)
		push_warning("No elements to display")
	if color_scale == ColorScaleOptions.GRADIENT_ and not scale_gradient:
		push_warning("Gradient not found")
	if color_scale == ColorScaleOptions.CUSTOM and not custom_scale:
		push_warning("Custom color scale not specified")
