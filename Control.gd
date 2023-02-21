extends Control

const port : int = 0x4348  # "CH"

var peer := StreamPeerTCP.new()
var connected = false

# IMPORT NetAPI
const Commands = NetAPI.Commands
const Responses = NetAPI.Responses
const COMMAND_INFO = NetAPI.COMMAND_INFO
# /IMPORT NetAPI

var param_update_handlers = {}

onready var param_list = $"%ParamList"
onready var message_log = $"%MessageLog"

func _ready():
	while not peer.is_connected_to_host():
		peer.connect_to_host("127.0.0.1", port)
		while (peer.get_status() == peer.STATUS_CONNECTING):
			message_log.text = "Connecting " + [".", "..", "..."][randi()%3] 
			yield(get_tree(), "idle_frame")
		if peer.get_status() == peer.STATUS_ERROR:
			message_log.text = "Error connecting. Retrying in 5s"
			yield(get_tree().create_timer(5), "timeout")
	message_log.text = "Connected. Getting param list.."
	peer.put_var([Commands.GLOBAL_PARAM_LIST])
	# Some tests. Should fail
	peer.put_var([10, "comova", "todo", "amigo"])
	peer.put_var([Commands.GLOBAL_PARAM_GET, "bad", 10, "params"])
	peer.put_var([Commands.GLOBAL_PARAM_GET, 0])



func _process(delta):
	if not peer.is_connected_to_host():
		return
	if peer.get_available_bytes() > 0:
		var packet = peer.get_var()
		if typeof(packet) != TYPE_ARRAY:
			print("Invalid response type")
		var response : NetAPI.Response = NetAPI.Response.from_array(packet)
		match response.type:
			Responses.ERROR:
				prints("Error", response.data.message)
				message_log.text = "Error: %s" % response.data.message
			Responses.BUG:
				prints("Unknown Error", response.data)
				message_log.text = "Unknown Error. Please Report. %s" % response.data.message
			Responses.INCORRECT_PARAM_COUNT:
				prints("Incorrect param count", response.data.message)
				message_log.text = response.data.message
			Responses.INCORRECT_PARAM_TYPE:
				prints("Ivalid param type", response.data.message)
				message_log.text = response.data.message
			Responses.INVALID_COMMAND:
				prints("Invalid command", response.data.message)
				message_log.text = response.data.message
			Responses.OK:
				var event = response.data.event
				match event:
					"global_param_changed":
						print(response.data.param)
						_on_param_get(response.data.param[0], response.data.param[1])
					"global_param_list_ready":
						_populate_params_ui(response.data.list)

func _exit_tree():
	peer.disconnect_from_host()

func _populate_params_ui( property_list : Array ):
	for prop in property_list:
		var param_box = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.name = "name"
		name_label.text = (prop.name as String).trim_prefix("param_").capitalize()
		print(name_label.text)
		param_box.add_child(name_label)
		
		var value_spinbox = SpinBox.new()
		value_spinbox.name = "value"
		if prop.hint == PROPERTY_HINT_RANGE:
			var values = (prop.hint_string as String).split(",")
			value_spinbox.min_value = float(values[0])
			value_spinbox.max_value = float(values[1])
			value_spinbox.rounded = prop.type == TYPE_INT
			value_spinbox.step = float(values[2]) if values.size() == 3 else 0
		value_spinbox.connect("value_changed", self, "_on_param_set", [prop.name])
		param_box.add_child(value_spinbox)
		
		param_list.add_child(param_box)
		param_update_handlers[prop.name] = param_box
		peer.put_var([Commands.GLOBAL_PARAM_GET, prop.name])
	message_log.text = "Ready"





func _on_param_set(value, key):
	peer.put_var([Commands.GLOBAL_PARAM_SET, key, value])
	
func _on_param_get(key, value):
	var handler : HBoxContainer = param_update_handlers.get(key)
	if not  handler:
		return
	var value_node : Range = handler.get_node("value")
	value_node.set_block_signals(true)
	value_node.value = value
	value_node.set_block_signals(false)
