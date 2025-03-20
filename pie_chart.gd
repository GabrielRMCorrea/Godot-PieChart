class_name PieChart
extends Control

enum ColorScaleOptions {
	PRESET_1,
	PRESET_2,
	GRADIENT_,
	CUSTOM,
}

enum LegendStyleOptions {
	DIRECT_LINE,
	DIRECT_LABEL,
	SEPARATED_LABEL,
}

@export var elements: Dictionary[String, float]
@export var title: String
@export var legend_style: LegendStyleOptions = LegendStyleOptions.DIRECT_LINE
@export var doughnut_shape: bool = true
@export var center_text: String  # if doughnut_shape
@export var center_proportion: float = 60.0  # if doughnut_shape
@export var separation_lines: bool = false
@export var color_scale: ColorScaleOptions = ColorScaleOptions.PRESET_1
@export var custom_scale: Array[Color]  # if color_scale == CUSTOM
@export var scale_gradient: Gradient  # if color_scale == GRADIENT_

@export_group("Style Properties")
@export var title_text_color: Color = Color.WHITE
@export var title_font_size: int = 16
@export var elements_text_color: Color = Color.WHITE
@export var elements_font_size: int = 16
@export var center_color: Color = Color.WHITE
@export var center_text_color: Color = Color.BLACK
@export var center_text_font_size: int = 16
@export var line_color: Color = Color.WHITE

func draw_circle_arc_poly(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color) -> void:
	var nb_points: int = 32
	var points_arc: PackedVector2Array = PackedVector2Array()
	points_arc.push_back(center)
	
	for i in range(nb_points + 1):
		var angle_point: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	draw_colored_polygon(points_arc, color)

func _draw() -> void:
	var radius: float = min(size.x, size.y) / 4.0
	var center: Vector2 = Vector2(
		size.x / (3.0 if legend_style == LegendStyleOptions.SEPARATED_LABEL else 2.0),
		size.y / 2.0
	)
	var previous_angle: float = 0.0
	var counter: int = 0
	var values: Array = elements.values().filter(func(number): return number > 0)
	var values_size: int = values.size()
	var total: float = values.reduce(func sum(accum, number): return accum + number) if values else 0.0
	var separation_lines_parameters: Array = []
	
	for key: String in elements:
		if elements[key] <= 0.0:
			continue
		
		# Choosing color
		var color: Color
		match color_scale:
			ColorScaleOptions.PRESET_1:
				@warning_ignore("integer_division")
				color = Color.from_hsv(
					1.0 / (values_size + 1) * counter / 2 if counter % 2 == 0 
						else 1.0 / (values_size + 1) * (values_size - counter / 2),
					0.6 if counter % 4 < 2 else 0.8,
					0.9
				)
			
			ColorScaleOptions.PRESET_2:
				color = Color.from_ok_hsl(
					1.0 / values_size * counter,
					1.0,
					0.8 if counter % 2 else 0.5
				)
			
			ColorScaleOptions.GRADIENT_:
				color = scale_gradient.sample(float(counter) / (values_size - 1))
			
			ColorScaleOptions.CUSTOM:
				color = custom_scale[counter % custom_scale.size()]
		
		counter += 1
		
		# Drawing elements
		var percentage: float = elements[key] / (total / 100.0)
		var current_angle: float = 360.0 * (percentage / 100.0)
		var angle: float = deg_to_rad(current_angle + previous_angle)
		var mid_angle: float = angle - deg_to_rad(current_angle / 2.0)
		var angle_point: Vector2 = Vector2(cos(mid_angle), sin(mid_angle)) * radius
		var text: String = key + (" - " if legend_style == LegendStyleOptions.SEPARATED_LABEL else "\n") + str(snappedf(percentage,0.01)).pad_decimals(2) + "%"
		
		var label_size: Vector2 = ThemeDB.fallback_font.get_multiline_string_size(
			text, HORIZONTAL_ALIGNMENT_CENTER
		)
		var label_center: Vector2 = Vector2(label_size.x / 2.0, label_size.y / 8.0)
		var label_position: Vector2
		
		match legend_style:
			LegendStyleOptions.DIRECT_LINE:
				label_position = center - label_center + angle_point * 1.5
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
			
			LegendStyleOptions.SEPARATED_LABEL:
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
			ThemeDB.fallback_font,
			label_position,
			text,
			HORIZONTAL_ALIGNMENT_RIGHT if legend_style == LegendStyleOptions.SEPARATED_LABEL \
				else HORIZONTAL_ALIGNMENT_CENTER,
			label_size.x,
			elements_font_size,
			-1,
			elements_text_color
		)
		
		draw_circle_arc_poly(center, radius, previous_angle, previous_angle + current_angle, color)
		separation_lines_parameters.append([
			center,
			center + Vector2(cos(angle), sin(angle)) * radius,
			Color.WHITE,
			2.0,
			true
		])
		previous_angle += current_angle
	
	# Draw title
	draw_multiline_string(
		ThemeDB.fallback_font,
		Vector2(35.0, 35.0),
		title,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1.0,
		title_font_size,
		-1,
		title_text_color
	)
	
	if separation_lines:
		for params in separation_lines_parameters:
			draw_line.callv(params)
	
	if doughnut_shape:
		draw_circle(center, radius * center_proportion / 100.0, center_color)
		var label_size: Vector2 = ThemeDB.fallback_font.get_multiline_string_size(center_text)
		draw_multiline_string(
			ThemeDB.fallback_font,
			center - Vector2(label_size.x / 2.0, -label_size.y / 4.0),
			center_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			label_size.x,
			center_text_font_size,
			-1,
			center_text_color
		)
