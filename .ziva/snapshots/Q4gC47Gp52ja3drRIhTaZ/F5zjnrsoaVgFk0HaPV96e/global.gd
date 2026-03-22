extends Node

signal window_opened(window_node: Control)
signal window_closed(window_node: Control)

func register_window(window: Control):
	window_opened.emit(window)

func unregister_window(window: Control):
	window_closed.emit(window)
