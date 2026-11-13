class_name UITheme
extends RefCounted

## Tema visual global "NASA Mission Control" para toda la interfaz:
## paleta oficial (azul NASA, rojo "meatball", cian de telemetría), tipografías del sistema
## con respaldo de símbolos y estilos para botones, deslizadores, barras y paneles.

const BG := Color(0.027, 0.043, 0.078)
const PANEL := Color(0.045, 0.07, 0.12, 0.97)
const PANEL_SOFT := Color(0.07, 0.105, 0.17, 1.0)
const PANEL_HI := Color(0.095, 0.14, 0.22, 1.0)
const NASA_BLUE := Color(0.043, 0.239, 0.569)
const CYAN := Color(0.33, 0.77, 0.98)
const RED := Color(0.988, 0.239, 0.129)
const GOLD := Color(0.97, 0.76, 0.29)
const GREEN := Color(0.36, 0.88, 0.55)
const PURPLE := Color(0.72, 0.47, 0.98)
const TEXT := Color(0.92, 0.95, 0.99)
const TEXT_DIM := Color(0.62, 0.69, 0.80)
const BORDER := Color(0.18, 0.26, 0.40)

static var _theme: Theme = null
static var _font_regular: Font = null
static var _font_bold: Font = null
static var _font_mono: Font = null

static func font_regular() -> Font:
	if _font_regular == null:
		_font_regular = _sys_font(["Segoe UI", "Helvetica Neue", "Arial"], 400)
	return _font_regular

static func font_bold() -> Font:
	if _font_bold == null:
		_font_bold = _sys_font(["Segoe UI", "Helvetica Neue", "Arial"], 700)
	return _font_bold

static func font_mono() -> Font:
	if _font_mono == null:
		_font_mono = _sys_font(["Consolas", "Cascadia Mono", "Courier New"], 400)
	return _font_mono

static func _sys_font(names: Array, weight: int) -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	var sym := SystemFont.new()
	sym.font_names = PackedStringArray(["Segoe UI Symbol", "Segoe UI Emoji", "Arial Unicode MS", "DejaVu Sans"])
	var fb: Array[Font] = [sym]
	f.fallbacks = fb
	return f

static func box(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 6, mx: float = 12.0, my: float = 8.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = mx
	sb.content_margin_right = mx
	sb.content_margin_top = my
	sb.content_margin_bottom = my
	sb.anti_aliasing = true
	return sb

static func card(accent: Color, bg: Color = PANEL_SOFT) -> StyleBoxFlat:
	var sb := box(bg, accent, 0, 6, 14, 10)
	sb.border_width_left = 3
	return sb

static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font_regular()
	t.default_font_size = 15

	t.set_color("font_color", "Label", TEXT)

	# --- Botones estándar ---
	t.set_stylebox("normal", "Button", box(Color(0.075, 0.125, 0.22), BORDER, 1, 6, 16, 9))
	t.set_stylebox("hover", "Button", box(Color(0.10, 0.18, 0.32), CYAN, 1, 6, 16, 9))
	t.set_stylebox("pressed", "Button", box(NASA_BLUE, CYAN, 1, 6, 16, 9))
	t.set_stylebox("hover_pressed", "Button", box(NASA_BLUE.lightened(0.1), CYAN, 1, 6, 16, 9))
	t.set_stylebox("disabled", "Button", box(Color(0.05, 0.07, 0.11), Color(0.12, 0.16, 0.24), 1, 6, 16, 9))
	var focus := box(Color(0, 0, 0, 0), CYAN, 2, 7, 16, 9)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_font("font", "Button", font_bold())
	t.set_font_size("font_size", "Button", 14)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(0.42, 0.48, 0.58))

	# --- Botón primario (rojo NASA) ---
	t.set_type_variation("PrimaryButton", "Button")
	t.set_stylebox("normal", "PrimaryButton", box(Color(0.80, 0.18, 0.10), RED, 1, 6, 20, 10))
	t.set_stylebox("hover", "PrimaryButton", box(RED, Color(1, 0.6, 0.5), 1, 6, 20, 10))
	t.set_stylebox("pressed", "PrimaryButton", box(Color(0.65, 0.14, 0.08), RED, 1, 6, 20, 10))
	t.set_stylebox("disabled", "PrimaryButton", box(Color(0.25, 0.10, 0.08), Color(0.35, 0.15, 0.12), 1, 6, 20, 10))

	# --- Botón fantasma (cerrar, pestañas) ---
	t.set_type_variation("GhostButton", "Button")
	t.set_stylebox("normal", "GhostButton", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6, 10, 6))
	t.set_stylebox("hover", "GhostButton", box(Color(1, 1, 1, 0.07), Color(0, 0, 0, 0), 0, 6, 10, 6))
	t.set_stylebox("pressed", "GhostButton", box(Color(0.33, 0.77, 0.98, 0.18), CYAN, 1, 6, 10, 6))
	t.set_stylebox("hover_pressed", "GhostButton", box(Color(0.33, 0.77, 0.98, 0.24), CYAN, 1, 6, 10, 6))
	t.set_color("font_color", "GhostButton", TEXT_DIM)
	t.set_color("font_pressed_color", "GhostButton", CYAN)
	t.set_color("font_hover_pressed_color", "GhostButton", CYAN)

	# --- CheckBox ---
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)
	t.set_color("font_pressed_color", "CheckBox", GREEN)
	t.set_color("font_hover_pressed_color", "CheckBox", GREEN)
	t.set_stylebox("normal", "CheckBox", box(Color(0.06, 0.09, 0.15), BORDER, 1, 6, 10, 6))
	t.set_stylebox("hover", "CheckBox", box(Color(0.09, 0.14, 0.24), CYAN, 1, 6, 10, 6))
	t.set_stylebox("pressed", "CheckBox", box(Color(0.06, 0.18, 0.13), GREEN, 1, 6, 10, 6))
	t.set_stylebox("hover_pressed", "CheckBox", box(Color(0.08, 0.22, 0.16), GREEN, 1, 6, 10, 6))

	# --- Deslizadores ---
	t.set_stylebox("slider", "HSlider", box(Color(0.10, 0.15, 0.25), BORDER, 1, 4, 0, 3))
	t.set_stylebox("grabber_area", "HSlider", box(CYAN, CYAN, 0, 4, 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(CYAN.lightened(0.25), CYAN, 0, 4, 0, 3))

	# --- Barras de progreso ---
	t.set_stylebox("background", "ProgressBar", box(Color(0.07, 0.11, 0.18), BORDER, 1, 5, 0, 0))
	t.set_stylebox("fill", "ProgressBar", box(CYAN, CYAN, 0, 5, 0, 0))
	t.set_color("font_color", "ProgressBar", Color.WHITE)
	t.set_font_size("font_size", "ProgressBar", 12)

	# --- Paneles, separadores, scroll y tooltips ---
	t.set_stylebox("panel", "PanelContainer", box(PANEL, BORDER, 1, 10, 16, 14))
	var sep := StyleBoxLine.new()
	sep.color = BORDER
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 10)
	t.set_stylebox("scroll", "VScrollBar", box(Color(0.06, 0.09, 0.15, 0.6), Color(0, 0, 0, 0), 0, 4, 3, 0))
	t.set_stylebox("grabber", "VScrollBar", box(Color(0.24, 0.34, 0.52), Color(0, 0, 0, 0), 0, 4, 3, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(CYAN.darkened(0.2), Color(0, 0, 0, 0), 0, 4, 3, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(CYAN, Color(0, 0, 0, 0), 0, 4, 3, 0))
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.04, 0.06, 0.10, 0.97), CYAN, 1, 6, 10, 6))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font("normal_font", "RichTextLabel", font_regular())
	t.set_font("bold_font", "RichTextLabel", font_bold())
	t.set_font("mono_font", "RichTextLabel", font_mono())

	_theme = t
	return t

## Crea una etiqueta con estilo.
static func label(text: String, size: int = 15, color: Color = TEXT, bold: bool = false, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_bold())
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Tecla estilizada tipo "keycap" para leyendas de controles.
static func keycap(key: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Color(0.12, 0.17, 0.27), Color(0.34, 0.45, 0.62), 1, 4, 7, 1))
	var l := label(key, 12, TEXT, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

## Fila "tecla + descripción".
static func key_hint(key: String, desc: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(keycap(key))
	var l := label(desc, 12, TEXT_DIM)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	return h
