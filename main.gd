extends Control

var session

var waiting_for_slot = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	session = load("res://Backend.cs").new()
	session.APChatText.connect(_on_ap_chat_text)
	session.APHint.connect(_on_ap_hint)

func _exit_tree() -> void:
	$Panel/LogRichTextLabel.free()
	session.free()


func _on_connect_button_pressed() -> void:
	if $Panel/ConnectButton.text == "Connect":
		var ip = session.Connect($Panel/IPTextEdit.text)
		if ip == "Connection failed. The server may not be up!" or ip.is_empty():
			$Panel/LogRichTextLabel.add_text("Connection failed. The server may not be up!")
			$Panel/LogRichTextLabel.newline()
			return
		$Panel/IPTextEdit.editable = false
		waiting_for_slot = true
		$Panel/LogRichTextLabel.add_text(ip)
		$Panel/LogRichTextLabel.newline()
		$Panel/LogRichTextLabel.add_text("Enter a slot name:")
		$Panel/LogRichTextLabel.newline()
		$Panel/ConnectButton.text = "Disconnect"
		$Panel/TextEdit.editable = true
	elif $Panel/ConnectButton.text == "Disconnect":
		session.Disconnect()
		waiting_for_slot = false
		$Panel/IPTextEdit.editable = true
		$Panel/ConnectButton.text = "Connect"
		$Panel/LogRichTextLabel.add_text("Disconnected. Press connect to rejoin.")
		$Panel/LogRichTextLabel.newline()
		$Panel/TextEdit.editable = false



func _on_text_edit_text_submitted(new_text: String) -> void:
	$Panel/TextEdit.clear()
	if waiting_for_slot:
		session.LoginSlot(new_text)
		waiting_for_slot = false
	else:
		session.SendMSG(new_text)


func _on_ap_chat_text(text: String) -> void:
	call_deferred("_display_ap_chat_text", text)

func _display_ap_chat_text(text: String) -> void:
	$Panel/LogRichTextLabel.add_text(text)
	$Panel/LogRichTextLabel.newline()


func _on_hint_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Panel/HBoxContainer/ArchipelagoButton.button_pressed = false
		$Panel/HBoxContainer/HintButton.button_pressed = true
		$Panel/LogRichTextLabel.visible = false
		$Panel/HintPanel.visible = true
	elif !$Panel/HBoxContainer/ArchipelagoButton.button_pressed:
		$Panel/HBoxContainer/HintButton.button_pressed = true


func _on_archipelago_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Panel/HBoxContainer/ArchipelagoButton.button_pressed = true
		$Panel/HBoxContainer/HintButton.button_pressed = false
		$Panel/LogRichTextLabel.visible = true
		$Panel/HintPanel.visible = false
	elif !$Panel/HBoxContainer/HintButton.button_pressed:
		$Panel/HBoxContainer/ArchipelagoButton.button_pressed = true


func _on_ap_hint(hints: Array) -> void:
	call_deferred("_display_ap_hint", hints)

func _display_ap_hint(hints: Array) -> void:
	for hint in hints:
		if hint.is_empty():
			continue
		var box = HBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for item in hint:
			var label = Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			label.text = item
			box.add_child(label)
		$Panel/HintPanel/ScrollContainer/VBoxContainer.add_child(box)
