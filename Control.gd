extends Control

const port : int = 0x4348  # "CH"

var peer := StreamPeerTCP.new()
var connected = false

# IMPORT NetAPI
const Commands = NetAPI.Commands
const Responses = NetAPI.Responses
const COMMAND_INFO = NetAPI.COMMAND_INFO
# /IMPORT NetAPI

func _ready():
	print("hola")
	peer.connect_to_host("127.0.0.1", port)
	while (peer.get_status() != peer.STATUS_CONNECTED):
		yield(get_tree(), "idle_frame")
	
	peer.put_var([Commands.GLOBAL_PARAM_GET, "size"])
	peer.put_var([Commands.GLOBAL_PARAM_GET, "speed"])

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
				prints("Error", response.data)
			Responses.BUG:
				prints("Unknown Error", response.data)
			Responses.OK:
				var event = response.data.event
				match event:
					"global_param_changed":
						print(response.data.param)
						match response.data.param.keys()[0]:
							"speed":
								$VBoxContainer/HBoxContainer2/SpeedValue.text = str(response.data.param.values()[0])
							"size":
								$VBoxContainer/HBoxContainer/SizeValue.text = str(response.data.param.values()[0])


func _exit_tree():
	peer.disconnect_from_host()



func _on_SpeedButton_pressed():
	peer.put_var([Commands.GLOBAL_PARAM_SET, "speed", float($VBoxContainer/HBoxContainer2/SpeedValue.text)])



func _on_SizeButton_pressed():
	peer.put_var([Commands.GLOBAL_PARAM_SET, "size", float($VBoxContainer/HBoxContainer/SizeValue.text)])

