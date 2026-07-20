extends Resource
class_name DialogueData

## Create one .tres per NPC conversation (right-click FileSystem > New
## Resource > DialogueData). Lines play in array order, alternating however
## you set them up -- e.g. for your "npc, player, npc, then end" pattern,
## just add 3 DialogueLine entries: npc, player, npc.
##
## Each DialogueLine is its own sub-resource -- in the Inspector, expand
## "Lines", set the array size, then for each element click the dropdown
## and "New Resource" > DialogueLine, and fill in speaker + text.

@export var npc_name: String = ""
@export var npc_portrait: Texture2D
@export var player_portrait: Texture2D
@export var lines: Array[DialogueLine] = []
