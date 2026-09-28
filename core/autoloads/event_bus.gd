extends Node

## Barramento Global de Eventos (EventBus)
## Centraliza a emissão e escuta assíncrona de sinais sem acoplamento direto entre nós.

# --- Eventos de Dimensão e Interface ---
signal dimension_changed(new_mode: GameEnums.DimensionMode)
signal scene_transition_requested(target_scene_path: String)
signal game_paused(is_paused: bool)

# --- Eventos de Necromancia e Almas (Grimório / Códice) ---
signal soul_harvested(soul_type: String, energy_value: float, origin_pos: Vector2)
signal servant_summoned(servant_node: Node2D, soul_cost: float)
signal servant_fallen(servant_node: Node2D)

# --- Eventos Táticos de Esquadrão e IA ---
signal squad_alert_changed(caller: Node, new_level: GameEnums.AlertLevel, suspected_location: Vector2)
signal tactical_token_requested(requester: Node, token_type: String)
signal tactical_token_granted(requester: Node, token_type: String)
signal tactical_pressure_updated(zone_id: String, pressure_value: float)

# --- Eventos da Tábua da Infâmia (Hierarquia Dinâmica) ---
signal warlord_encountered(warlord_data: Dictionary)
signal warlord_defeated(warlord_data: Dictionary, slayer: Node)
signal enemy_promoted(enemy_id: String, title: String, new_tier: int)
