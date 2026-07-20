extends Resource
class_name SuspectData
## Create one .tres resource per suspect (Right-click FileSystem > New Resource > SuspectData)
## Fill these in per suspect. is_dummy is the ground truth you're hiding from the player.
@export var suspect_name: String = ""
@export var badge_id: String = ""          # e.g. "A-114"
@export var years_at_company: int = 0
@export var stated_reason: String = ""     # what they SAY when interviewed
@export var portrait: Texture2D
# Ground truth -- used to check the player's final decision, not shown directly
@export var is_dummy: bool = false
## These are the fields the player cross-checks against the leaked memo.
## For real allies, badge_id and years_at_company MATCH the memo entry.
## For dummies, seed at least one mismatch here on purpose (wrong badge_id
## or wrong years_at_company) -- that mismatch is the "tell."
@export var pc_password: String = ""
@export var parking_permit: String = ""


## Denial lines -- shown in a reaction bubble when the player finds a
## mismatch on that specific field. Write these even for real allies (a
## line should never actually fire for them if their data is clean, but
## having it set avoids an empty bubble if you flip is_dummy for testing).
@export_group("Denial Lines")
@export_multiline var denial_line_name: String = "That... that is my name."
@export_multiline var denial_line_badge: String = "My badge is in order."
@export_multiline var denial_line_years: String = "I've been here for years, I told you."
@export_multiline var denial_line_photo: String = "That photo is old, that's all."
@export_multiline var denial_line_password: String = "Am I expected to remember that?"
@export_multiline var denial_line_parking: String = "I might have mixed up."
@export_multiline var denial_line_phone: String = "I really have nothing to add."
