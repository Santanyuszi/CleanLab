class_name ParticleTypes
extends RefCounted
## Shared particle categories for microscopy (signature gameplay).

enum Class {
	REGULAR,
	METALLIC_SHINY,
	FIBER,
	SHINY_FIBER,
}


static func display_name(p_class: Class) -> String:
	match p_class:
		Class.REGULAR:
			return "Regular"
		Class.METALLIC_SHINY:
			return "Metallic shiny"
		Class.FIBER:
			return "Fiber"
		Class.SHINY_FIBER:
			return "Shiny fiber"
	return "Unknown"


static func color_for(p_class: Class) -> Color:
	match p_class:
		Class.REGULAR:
			return Color(0.28, 0.3, 0.32)
		Class.METALLIC_SHINY:
			return Color(0.78, 0.82, 0.92)
		Class.FIBER:
			return Color(0.92, 0.52, 0.32)
		Class.SHINY_FIBER:
			return Color(0.72, 0.86, 0.95)
	return Color.WHITE
