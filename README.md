# Godot Pie Chart

A simple customizable pie chart component for Godot Engine 4.

![Pie Chart Demo](https://i.imgur.com/1hulNsM.png)


## Usage

### Inspector Configuration 
1. Add the `PieChart` node to your scene
2. Select the node and set properties in the inspector:
   - **Values**: Dictionary of category names (String) and their values (float)
   - **Title**: Text to display in center (if enabled)
   - **CenterCircle**: Toggle center white circle
   - **SeparationLines**: Toggle wedge separation lines

![Inspector Properties](https://i.imgur.com/nZRtjU8.png)

### Programmatic Usage
Create and configure charts entirely through code:

```gdscript
# Create and configure a new chart
var chart = $PieChart

# Configure properties
chart.Values = {
	"Cats": 30.0,
	"Dogs": 60,
	"Fish": 6,
	"Rabbits": 5,
	"Roddents": 4.0
}
chart.Title = "Pets"
chart.CenterCircle = true
chart.SeparationLines = false
