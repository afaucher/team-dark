class_name MountableItem
extends Node2D

@export var icon: Texture2D
@export var item_name: String = "Item"

# Reference to the entity holding this item
var user: Node2D

func equip(_user: Node2D):
	user = _user
	# Visual setup if needed

func unequip():
	user = null

# Called when the mount button is pressed
func use():
	pass

# Called when the mount button is released
func stop_use():
	pass
