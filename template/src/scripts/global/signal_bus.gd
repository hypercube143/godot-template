extends Node

@warning_ignore_start("unused_signal")

# save_manager.gd ###########################################################
signal save_created
signal delete_complete
signal delete_failed(Error)
signal save_complete
signal save_failed(Error)
signal load_complete
signal load_failed
