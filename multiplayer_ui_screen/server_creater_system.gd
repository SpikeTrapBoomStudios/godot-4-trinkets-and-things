extends Panel

@onready var server_name_edit: LineEdit = $EditorArea/ServerNameEdit
@onready var address_edit: LineEdit = $EditorArea/AddressEdit
@onready var port_edit: LineEdit = $EditorArea/PortEdit
@onready var save_button: Button = $EditorArea/SaveButton
@onready var mouse_blocker: Control = $MouseBlocker

@export var server_dropdowns = [] as Array[OptionButton]

var current_index: int = 0

func _ready() -> void:
	init_dropdowns()
	server_name_edit.text = MultiplayerUserSystem.servers[0].server_name
	address_edit.text = MultiplayerUserSystem.servers[0].ip_address
	port_edit.text = str(MultiplayerUserSystem.servers[0].port)

func init_dropdowns():
	for server_dropdown in server_dropdowns:
		server_dropdown.clear()
		for server in MultiplayerUserSystem.servers:
			server_dropdown.add_item(server.server_name)

func _on_save_button_pressed() -> void:
	var overwriting: bool = false
	var this_server_name = server_name_edit.text
	if save_button.text != "Overwrite?":
		for server in MultiplayerUserSystem.servers:
			if server.server_name == this_server_name:
				mouse_blocker.show()
				save_button.text = "Overwrite?"
				return
	else:
		mouse_blocker.hide()
		overwriting = true
		save_button.text = "Save Server"
	
	var new_server = Server.new()
	new_server.server_name = this_server_name
	new_server.ip_address = address_edit.text
	new_server.port = int(port_edit.text)
	
	DirAccess.make_dir_recursive_absolute("user://servers/")
	var new_server_file = FileAccess.open("user://servers/"+new_server.server_name+".server",FileAccess.WRITE)
	print(FileAccess.get_open_error())
	new_server_file.store_string(new_server.to_string())
	new_server_file.close()
	
	if overwriting:
		MultiplayerUserSystem.servers[current_index] = new_server
	else:
		MultiplayerUserSystem.servers.append(new_server)
		init_dropdowns()
	
	hide()

func _on_port_edit_text_changed(new_text: String) -> void:
	port_edit.text = str(int(new_text))
	port_edit.caret_column = port_edit.text.length()

func _on_server_dropdown_item_selected(index: int) -> void:
	current_index = index
	server_name_edit.text = MultiplayerUserSystem.servers[index].server_name
	address_edit.text = MultiplayerUserSystem.servers[index].ip_address
	port_edit.text = str(MultiplayerUserSystem.servers[index].port)

func _on_exit_button_pressed() -> void:
	hide()

func _on_address_edit_text_changed(new_text: String) -> void:
	var fixed_text = ""
	for letter in new_text:
		if int(letter)==0 and letter!="." and letter!="0": continue
		fixed_text += letter
	address_edit.text = fixed_text
	address_edit.caret_column = fixed_text.length()
