# memo_data.gd
extends Resource
class_name MemoData
@export_multiline var memo_flavor_text: String = "Confidential — HR verified records for board loyalists."
var true_facts: Dictionary = {}
func _init():
	true_facts = {
		"Satoshi": {"badge_id": "6625", "years": 4, "password": "sunflower22", "parking_permit": "P-4471", "portrait": preload("res:///Assets/Suspect-1 portrait.png")},
		"Jennie": {"badge_id": "1023", "years": 2, "password": "parparrot99", "parking_permit": "F-6421", "portrait": preload("res:///Assets/Suspect-2 portrait.png")},
		"Jason": {"badge_id": "8496", "years": 1, "password": "bubblegum92", "parking_permit": "R-8493", "portrait": preload("res:///Assets/Suspect-3 portrait.png")},
		"Julia": {"badge_id": "1054", "years": 10, "password": "cious88chance", "parking_permit": "L-9626", "portrait": preload("res:///Assets/Suspect-4 portrait.png")},
		"Hugo": {"badge_id": "8973", "years": 7, "password": "dragon51kiki", "parking_permit": "S-8266", "portrait": preload("res:///Assets/Suspect-5 portrait.png")},
		# Add the remaining 4 real allies here, same shape:
		# "<claimed name>": {"badge_id": "<real badge>", "years": <int>, "portrait": <Texture2D or null>},
	}
