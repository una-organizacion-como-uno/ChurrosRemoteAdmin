extends Control

const port : int = 0x4348  # "CH"

var udp := PacketPeerUDP.new()
var connected = false

# IMPORT NetAPI
const Commands = NetAPI.Commands
const Responses = NetAPI.Responses
const COMMAND_INFO = NetAPI.COMMAND_INFO
# /IMPORT NetAPI

func _ready():
	print("hola")
	udp.connect_to_host("127.0.0.1", port)
	udp.put_var([Commands.GLOBAL_PARAM_GET, "size"])
	udp.put_var([Commands.GLOBAL_PARAM_GET, "speed"])

func _process(delta):
	if udp.get_available_packet_count() > 0:
		var packet = udp.get_var()
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
	udp.close()



func _on_SpeedButton_pressed():
	udp.put_var([Commands.GLOBAL_PARAM_SET, "speed", float($VBoxContainer/HBoxContainer2/SpeedValue.text)])



func _on_SizeButton_pressed():
	udp.put_var([Commands.GLOBAL_PARAM_SET, "size", float($VBoxContainer/HBoxContainer/SizeValue.text)])

