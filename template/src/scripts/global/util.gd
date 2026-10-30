extends Node

# string to path name - replacing characters that don't work in a filesystem with nothing
func serialze_path_name(save_name: String):
	var serialized = ""
	save_name = save_name.replace(" ", "_")
	var allowed_chars = "abcdefghijklmnopqrstuvwxyz0123456789_"
	for c in save_name:
		if c in allowed_chars:
			serialized += c
	return serialized
	
	
# ENUM ##################################################################################################################

func enum_name_as_string(e: Dictionary, value: int) -> String:
	return e.find_key(value)

# DEBUG FUNCTIONS #######################################################################################################

enum dprint_part {LOCATION, SMILEY, PRINT_COUNT, LINE, LOCATION_AND_LINE}

var dprint_print_count: int = 0
func dprint(x: String, enabled_parts=[dprint_part.LOCATION_AND_LINE]): # d(ebug)print
	
	var stack = get_stack()
	var parts = []
	
	dprint_print_count += 1
	
	if dprint_part.LOCATION_AND_LINE in enabled_parts:
		parts.append("[color=WEB_GRAY]" + stack[1].source.split("/")[-1] + ", ln" + str(stack[1].line) + "[/color]")
	if dprint_part.LOCATION in enabled_parts:
		parts.append(stack[1].source.split("/")[-1]) # script name / location
	if dprint_part.LINE in enabled_parts:
		parts.append("line " + str(stack[1].line)) # script name / location
	if dprint_part.SMILEY in enabled_parts:
		parts.append(":)")
	if dprint_part.PRINT_COUNT in enabled_parts:
		parts.append(str(dprint_print_count))
	
	var consolidated_parts: String = ""
	if len(parts) > 0:
		consolidated_parts = "(" +  ", ".join(parts) + ") "
	print_rich("[i]" + consolidated_parts + "[/i]" + x)
