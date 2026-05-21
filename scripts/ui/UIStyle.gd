class_name UIStyle
extends RefCounted
## Centralized UI color/size constants. Pulled from the patterns that
## evolved across PauseMenu, MainMenu, ClassSelect, Vendor, etc. — anchored
## here so future panels stay consistent.

# --- Brand / titles ---
const COL_TITLE: Color = Color(1.0, 0.78, 0.35)        # warm gold for panel titles
const COL_BRAND: Color = Color(1.0, 0.60, 0.25)        # amber used on the main menu logo
const COL_ACCENT: Color = Color(0.95, 0.70, 0.35)      # primary CTA accent

# --- Currency / resources ---
const COL_GOLD: Color = Color(1.0, 0.85, 0.30)
const COL_SHARDS: Color = Color(0.80, 0.55, 1.0)
const COL_ESSENCE: Color = Color(0.55, 0.85, 1.0)

# --- Text emphasis ---
const COL_MUTED: Color = Color(0.72, 0.72, 0.78)       # secondary labels
const COL_HINT: Color = Color(0.55, 0.55, 0.60)        # tiny hint text
const COL_GOOD: Color = Color(0.55, 0.85, 0.45)
const COL_BAD: Color = Color(0.95, 0.45, 0.45)
const COL_WARNING: Color = Color(1.0, 0.70, 0.30)

# --- Common UI metrics ---
const PRIMARY_BUTTON_HEIGHT: int = 44
const SECONDARY_BUTTON_HEIGHT: int = 36
const PANEL_DIM: Color = Color(0, 0, 0, 0.62)


## Cursor-following tooltip positioning shared by InventoryUI / VendorUI / etc.
## Clamps inside the viewport rect so the tooltip never spills off-screen.
static func position_tooltip(tooltip: Control) -> void:
	var mp: Vector2 = tooltip.get_viewport().get_mouse_position()
	var cursor_offset := Vector2(18, 18)
	var tip_size: Vector2 = tooltip.size
	var vp: Vector2 = tooltip.get_viewport().get_visible_rect().size
	var pos := mp + cursor_offset
	if pos.x + tip_size.x > vp.x:
		pos.x = mp.x - tip_size.x - 8
	if pos.y + tip_size.y > vp.y:
		pos.y = mp.y - tip_size.y - 8
	tooltip.position = pos
