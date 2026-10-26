class_name Save extends Resource

# features of game to be saved and loaded
# IMPORTANT NOTE: all values must preceed with @export

@export var id: int = 0
@export var save_name: String = "unamed save"
@export var save_path: String = ""
@export var save_created_timestamp: float = 0
@export var save_updated_timestamp: float = 0
@export var thumbnail_path: String = ""
