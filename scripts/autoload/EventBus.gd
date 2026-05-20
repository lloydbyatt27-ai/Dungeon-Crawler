extends Node
## Global signal bus for cross-system communication.
## Systems emit and listen here instead of holding direct references.
## Keeps coupling loose and makes refactoring safer.

# --- Combat ---
signal player_dealt_damage(target: Node, amount: float, is_crit: bool)
signal player_took_damage(amount: float, source: Node)
signal enemy_died(enemy: Node, position: Vector3)
signal attack_of_opportunity_window(target: Node, duration: float)

# --- Player progression ---
signal player_leveled_up(new_level: int)
signal player_xp_gained(amount: int)
signal player_gold_changed(new_total: int)
signal player_essence_changed(new_value: float)
signal player_shapeshifted(form_id: String, is_active: bool)
signal player_stats_changed

# --- Loot & items ---
signal item_dropped(item, position: Vector3)
signal item_picked_up(item)
signal item_equipped(item, slot: String)

# --- World ---
signal interactable_in_range(node: Node)
signal interactable_out_of_range(node: Node)
signal dungeon_completed(zone_id: String)
signal boss_defeated(boss: Node)

# --- UI ---
signal show_damage_number(amount: float, position: Vector3, is_crit: bool)
signal show_floating_text(text: String, position: Vector3, color: Color)
