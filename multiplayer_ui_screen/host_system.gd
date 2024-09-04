extends Button

@onready var server_conf_options: OptionButton = $HostOptionsContainer/ServerConfOptions

func _on_host_confirm_button_pressed() -> void:
	var selected_config_index = server_conf_options.get_selected_id() as int
	var this_config = MultiplayerUserSystem.server_configs[selected_config_index] as ServerConfig
	
	var port = this_config.port as int
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 4)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(MultiplayerHandler.player_connected)
	
	EnvironmentLoader.load_environment("res://assets/environments/control_room.tscn")
	
	get_owner().queue_free()
