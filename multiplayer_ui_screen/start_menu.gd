extends Control

@onready var join_options_container: Panel = $UIArea/JoinGameButton/JoinOptionsContainer
@onready var host_options_container: Panel = $UIArea/HostGameButton/HostOptionsContainer
@onready var server_config_area: Panel = $ServerConfigArea
@onready var server_area: Panel = $ServerArea

func _ready() -> void:
	join_options_container.hide()
	host_options_container.hide()
	server_config_area.hide()
	server_area.hide()

func _on_join_game_button_pressed() -> void:
	join_options_container.visible = !join_options_container.visible
	host_options_container.hide()

func _on_host_game_button_pressed() -> void:
	host_options_container.visible = !host_options_container.visible
	join_options_container.hide()

func _on_create_config_text_meta_clicked(meta: Variant) -> void:
	if meta!="create_server_config": return
	server_config_area.show()

func _on_create_server_text_meta_clicked(meta: Variant) -> void:
	if meta!="create_server": return
	server_area.show()
