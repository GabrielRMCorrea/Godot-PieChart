class_name Pie_Chart
extends Control

enum ColorScaleOptions {
	HSV,
	HSL,
	Gradient_,
	Custom,
}
enum LegendStyleOptions {
	DirectLine,
	DirectLabel,
	SeparatedLabel
}
@export var Values : Dictionary[String,float]
@export var Title : String
@export var LegendStyle : LegendStyleOptions = LegendStyleOptions.DirectLine
@export var CenterCircle : bool = true
@export var CenterText : String
@export var CenterProportion : float = 60
@export var SeparationLines : bool = false
@export var ColorScale : ColorScaleOptions = ColorScaleOptions.HSV
@export var CustomScale : Array[Color]
@export var ScaleGradient : Gradient
@export var TextColor : Color = Color.WHITE
@export var CenterColor : Color = Color.WHITE
@export var CenterTextColor : Color = Color.BLACK
@export var LineColor : Color = Color.WHITE

func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points := 32
	var points_arc := PackedVector2Array()
	points_arc.push_back(center)
	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points )
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_colored_polygon(points_arc, color)

func _draw():
	var radius = min(size.x, size.y)/4 
	var center = Vector2(size.x/(3 if LegendStyle == LegendStyleOptions.SeparatedLabel else 2), size.y/2)
	var previousAngle : float = 0
	var counter : int = 0
	var valuesSize : int =Values.values().filter(func(number): return number > 0).size()
	var total : float = Values.values().reduce(func sum(accum, number): return accum + number) if Values.values() else 0
	var separationLinesParameters : Array
	for i in Values:
		if Values[i] > 0.0:
			#chosing color
			var color : Color 
			match ColorScale :
				ColorScaleOptions.HSV:
					color =  Color.from_hsv(1.0/(valuesSize+1) * counter/2 if counter%2 == 0 else 1.0/(valuesSize+1) * (valuesSize  - counter/2) ,0.6 if counter%4<2 else 0.8 ,0.9)
				ColorScaleOptions.HSL:
					color = Color.from_ok_hsl(1.0/(valuesSize) * counter ,1,0.8  if counter%2 else 0.5)
				ColorScaleOptions.Gradient_:
					color = ScaleGradient.sample(float(counter)/(valuesSize-1))
				ColorScaleOptions.Custom:
					color = CustomScale[counter%CustomScale.size()]
			counter += 1
			#drawing on the screen
			var percentage: float = Values[i]/(total/100)
			var currentAngle:float = 360 * (percentage/100)
			var angle := deg_to_rad(currentAngle + previousAngle)
			var mid_angle = angle - deg_to_rad(currentAngle / 2)
			var anglePoint : Vector2 =  Vector2( cos(mid_angle), sin(mid_angle) ) * radius
			var text = i + (" - " if LegendStyle == LegendStyleOptions.SeparatedLabel else "\n") + str(snappedf(percentage,0.01)).pad_decimals(2) + "%"
			var label_size = ThemeDB.fallback_font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER)
			var label_center =Vector2(label_size.x/2, label_size.y/8)

			var labelPosition : Vector2
			match LegendStyle:
				
				LegendStyleOptions.DirectLine:
					labelPosition = center - label_center + anglePoint * 1.5
					draw_line(anglePoint * 1.05 +center, anglePoint * 1.2 + center,LineColor, 2, true)
				
				LegendStyleOptions.DirectLabel:
					var dir_sign = Vector2( sign(cos(mid_angle)), sign(sin(mid_angle)) )
					var offset = Vector2(dir_sign.x * label_size.x / 2,	dir_sign.y * label_size.y / 2 )
					labelPosition =   center- label_center + anglePoint *1.05  +offset 
				
				LegendStyleOptions.SeparatedLabel:
					print(radius/5)
					labelPosition.x = size.x - label_size.x -(radius/5) - label_size.y
					labelPosition.y = label_size.y + label_size.y*counter +(radius/5)
					draw_rect(Rect2(Vector2(size.x -(radius/6) - label_size.y, label_size.y*counter +(radius/5) +5),Vector2.ONE * label_size.y), color )
				

			draw_multiline_string(ThemeDB.fallback_font, labelPosition, text ,HORIZONTAL_ALIGNMENT_RIGHT if LegendStyle == LegendStyleOptions.SeparatedLabel else HORIZONTAL_ALIGNMENT_CENTER, label_size.x,16,-1,TextColor)
			draw_circle_arc_poly( center, radius,previousAngle ,previousAngle + currentAngle , color)
			separationLinesParameters.append([center, center +Vector2(cos(angle), sin(angle)) * radius, Color.WHITE, 2, true])
			previousAngle += currentAngle
	
	draw_multiline_string(ThemeDB.fallback_font, Vector2(35,35), Title)
	
	if SeparationLines:
		for i in separationLinesParameters:
			draw_line.callv(i)

	if CenterCircle:
		draw_circle(center, radius*CenterProportion/100.0, CenterColor)
		var label_size = ThemeDB.fallback_font.get_multiline_string_size(Title)
		var font = ThemeDB.fallback_font
		draw_multiline_string(font, center - Vector2(label_size.x/2, -label_size.y/4), CenterText ,HORIZONTAL_ALIGNMENT_CENTER, label_size.x,16,-1, CenterTextColor)
