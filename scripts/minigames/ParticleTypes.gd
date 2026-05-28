class_name ParticleTypes
extends RefCounted
## Shared particle categories for microscopy (signature gameplay).

enum Class {
	METALLIC,
	FIBER,
	NON_METALLIC,
	IGNORE,
	FTIR_REQUIRED,
}


static func display_name(p_class: Class) -> String:
	match p_class:
		Class.METALLIC:
			return "Metallic"
		Class.FIBER:
			return "Fiber"
		Class.NON_METALLIC:
			return "Non-metallic"
		Class.IGNORE:
			return "Ignore"
		Class.FTIR_REQUIRED:
			return "FTIR / SEM"
	return "Unknown"


static func color_for(p_class: Class) -> Color:
	match p_class:
		Class.METALLIC:
			return Color(0.78, 0.82, 0.92)
		Class.FIBER:
			return Color(0.92, 0.52, 0.32)
		Class.NON_METALLIC:
			return Color(0.42, 0.88, 0.58)
		Class.IGNORE:
			return Color(0.5, 0.5, 0.55)
		Class.FTIR_REQUIRED:
			return Color(0.72, 0.55, 0.95)
	return Color.WHITE
