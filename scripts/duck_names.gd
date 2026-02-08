class_name DuckNameGenerator
extends RefCounted

const FIRST_NAMES = [
	"Quack", "Bill", "Feather", "Waddle", "Mallard", "Puddles", "Drake", "Webby",
	"Downy", "Bubbles", "Splash", "Paddles", "Ducky", "Goose", "Swan", "Teal"
]

const TITLES = [
	"Captain", "Doctor", "Sir", "Lady", "Commander", "Agent", "Professor", "Baron",
	"Duke", "Major", "Private", "General"
]

const LAST_NAMES = [
	"McQuack", "Webfoot", "Featherbottom", "Quackington", "Bills", "Waddlesworth", 
	"Puddlejumper", "Drakes", "Mallardy", "Tealfeather"
]

static func generate_name() -> String:
	var structure = randi() % 3
	
	match structure:
		0: # First Last
			return _pick(FIRST_NAMES) + " " + _pick(LAST_NAMES)
		1: # Title Last
			return _pick(TITLES) + " " + _pick(LAST_NAMES)
		2: # Title First Last
			return _pick(TITLES) + " " + _pick(FIRST_NAMES) + " " + _pick(LAST_NAMES)

	return "John Doe"

static func _pick(arr: Array):
	return arr[randi() % arr.size()]
