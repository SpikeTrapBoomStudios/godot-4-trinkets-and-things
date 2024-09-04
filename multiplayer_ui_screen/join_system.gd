extends Button

@onready var join_conf_options: OptionButton = $JoinOptionsContainer/JoinConfOptions

func _on_join_confirm_button_pressed() -> void:
	var selected_server_index = join_conf_options.get_selected_id() as int
	var this_server = MultiplayerUserSystem.servers[selected_server_index] as Server
	
	var ip_address = this_server.ip_address
	var port = this_server.port as int
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(MultiplayerHandler.player_connected)
	
	EnvironmentLoader.load_environment("res://assets/environments/control_room.tscn")
	
	get_owner().queue_free()
