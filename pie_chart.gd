extends Control

# Keys should be Strings and values should be numbers
@export var Values : Dictionary[String,float]
@export var Title : String
@export var CenterCircle : bool = true
@export var SeparationLines : bool = false

func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PackedVector2Array()
	points_arc.push_back(center)
	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points )
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_colored_polygon(points_arc, color)

func _draw():
	for i in $Labels.get_children():
		i.free()
	var center = Vector2(size.x/2, size.y/2)	
	var radius = min(size.x, size.y)/4 
	var previousAngle : float = 0
	var counter : int = 0
	var valuesSize : int =Values.values().filter(func(number): return number > 0).size() 
	var total : float = Values.values().reduce(func sum(accum, number): return accum + number)
	for i in Values:
		if Values[i] > 0.0:
			#chosing color
			var color : Color =  Color.from_hsv(1.0/(valuesSize+1) * counter/2 if counter%2 == 0 else 1.0/(valuesSize+1) * (valuesSize  - counter/2) ,0.6 if counter%4<2 else 0.8 ,0.9)
			counter += 1
			#drawing on the screen
			var percentage: float = Values[i]/(total/100)
			var currentAngle:float = 360 * (percentage/100)
			var angle := deg_to_rad(currentAngle + previousAngle)
			var anglePoint : Vector2 =  Vector2( cos(angle - deg_to_rad(currentAngle/2)), sin(angle - deg_to_rad(currentAngle/2) ) ) * radius
			var label = Label.new()
			label.text = i + "\n" + str(snappedf(percentage,0.01)).pad_decimals(2) + "%"
			label.vertical_alignment = 1
			label.horizontal_alignment = 1
			$Labels.add_child(label)
			label.position =  center - label.size/2 + anglePoint  * 1.5
			draw_line(anglePoint * 1.05 +center, anglePoint * 1.2 + center,Color.WHITE, 2, true)
			draw_circle_arc_poly( center, radius,previousAngle ,previousAngle + currentAngle , color)
			if SeparationLines:
				draw_line(center, center +Vector2(cos(angle), sin(angle)) * radius, Color.WHITE, 2, true)
			previousAngle += currentAngle
	var titleLabel := $TitleLabel
	if CenterCircle:
		titleLabel.visible = true
		draw_circle(center, radius*0.60, Color.WHITE)
		titleLabel.text = Title
		titleLabel.size = Vector2(radius,radius) 
		titleLabel.position = center - titleLabel.size/2
	else :
		titleLabel.visible = false
