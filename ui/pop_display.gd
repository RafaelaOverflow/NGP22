extends Control

enum MODE {
	JOB
}

@export var gradient : Gradient
@onready var chart: Chart = $Tab/PopGraph/HFlowContainer/Chart
@onready var label: Label = $Tab/POPs/VBoxContainer/Label

var pops
var mode = MODE.JOB

func display(_pops : Array[POP]):
	pops = _pops
	show()
	update()

func _process(delta: float) -> void:
	if visible:
		label.text = ""
		match mode:
			MODE.JOB:
				for i in 15:
					f1.__x[i] = 0
				for pop : POP in pops:
					label.text += "\n%s" % pop.get_save_data()
					f1.__x[pop.job] += pop.size
		chart.queue_redraw()
	else:
		pops = null

var f1 : Function

func update():
	#var pops = pops_ref.get_ref()
	if pops == null: return
	var x = []
	var y = []
	match mode:
		MODE.JOB:
			for i in 15:
				y.append(Global.localize("pop.job.%s" % i))
				x.append(0)
			for pop : POP in pops:
				x[pop.job] += pop.size
	# code from pie chart example ahead
	var cp: ChartProperties = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.title = "Population by job"
	cp.draw_grid_box = false
	cp.show_legend = true
	cp.interactive = true
	f1 = Function.new(
		x, y, "Job", # This will create a function with x and y values taken by the Arrays 
						# we have created previously. This function will also be named "Pressure"
						# as it contains 'pressure' values.
						# If set, the name of a function will be used both in the Legend
						# (if enabled thourgh ChartProperties) and on the Tooltip (if enabled).
		{
			gradient = gradient,
			type = Function.Type.PIE
		}
	)
	# Now let's plot our data
	chart.plot([f1], cp)

func _on_button_pressed() -> void:
	hide()
