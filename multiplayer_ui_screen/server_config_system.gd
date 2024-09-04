extends Panel

@onready var config_name_edit: LineEdit = $EditorArea/ConfigNameEdit
@onready var port_edit: LineEdit = $EditorArea/PortEdit
@onready var save_button: Button = $EditorArea/SaveButton
@onready var mouse_blocker: Control = $MouseBlocker

@export var config_dropdowns = [] as Array[OptionButton]

var current_index: int = 0

func _ready() -> void:
	init_dropdowns()
	config_name_edit.text = MultiplayerUserSystem.server_configs[0].config_name
	port_edit.text = str(MultiplayerUserSystem.server_configs[0].port)

func init_dropdowns():
	for config_dropdown in config_dropdowns:
		config_dropdown.clear()
		for server_config in MultiplayerUserSystem.server_configs:
			config_dropdown.add_item(server_config.config_name)

func _on_save_button_pressed() -> void:
	var overwriting: bool = false
	var this_config_name = config_name_edit.text
	if save_button.text != "Overwrite?":
		for config in MultiplayerUserSystem.server_configs:
			if config.config_name == this_config_name:
				mouse_blocker.show()
				save_button.text = "Overwrite?"
				return
	else:
		mouse_blocker.hide()
		overwriting = true
		save_button.text = "Save Config"
	
	var new_config = ServerConfig.new()
	new_config.config_name = this_config_name
	new_config.port = int(port_edit.text)
	
	DirAccess.make_dir_recursive_absolute("user://server_configs/")
	var new_config_file = FileAccess.open("user://server_configs/"+new_config.config_name+".config",FileAccess.WRITE)
	print(FileAccess.get_open_error())
	new_config_file.store_string(new_config.to_string())
	new_config_file.close()
	
	if overwriting:
		MultiplayerUserSystem.server_configs[current_index] = new_config
	else:
		MultiplayerUserSystem.server_configs.append(new_config)
		init_dropdowns()
	
	hide()

func _on_port_edit_text_changed(new_text: String) -> void:
	port_edit.text = str(int(new_text))
	port_edit.caret_column = port_edit.text.length()


func _on_config_dropdown_item_selected(index: int) -> void:
	current_index = index
	config_name_edit.text = MultiplayerUserSystem.server_configs[index].config_name
	port_edit.text = str(MultiplayerUserSystem.server_configs[index].port)

func _on_exit_button_pressed() -> void:
	hide()
