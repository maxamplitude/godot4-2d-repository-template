extends Node
## Global constants for cross-cutting concerns
##
## ONLY include values used by multiple unrelated systems.
## System-specific constants should live in their respective scripts.

# ============================================================================
# PHYSICS LAYERS (referenced everywhere for collision/detection)
# ============================================================================

const LAYER_WORLD = 1
const LAYER_PLAYER = 2
const LAYER_ENEMY = 3
const LAYER_PLAYER_PROJECTILE = 4
const LAYER_ENEMY_PROJECTILE = 5
const LAYER_PICKUP = 6
const LAYER_TRIGGER = 7
const LAYER_ONE_WAY_PLATFORM = 8

# ============================================================================
# PHYSICS CONSTANTS (shared across player, enemies, projectiles)
# ============================================================================

const GRAVITY = 980.0
const TERMINAL_VELOCITY = 1000.0

# ============================================================================
# SCENE PATHS (if referenced from multiple disparate locations)
# ============================================================================

const SCENE_MAIN_MENU = "res://src/ui/menus/main_menu.tscn"
const SCENE_PAUSE_MENU = "res://src/ui/menus/pause_menu.tscn"
const SCENE_SETTINGS_MENU = "res://src/ui/menus/settings_menu.tscn"
const SCENE_GAME_OVER = "res://src/ui/screens/game_over.tscn"

# ============================================================================
# NODE GROUPS (for get_tree().get_nodes_in_group())
# ============================================================================

const GROUP_PLAYER = "player"
const GROUP_ENEMIES = "enemies"
const GROUP_PROJECTILES = "projectiles"
const GROUP_PICKUPS = "pickups"
const GROUP_DESTRUCTIBLES = "destructibles"
const GROUP_SAVEABLES = "saveables"

# ============================================================================
# GAME STATE
# ============================================================================

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	CUTSCENE,
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	NIGHTMARE,
}

# ============================================================================
# COMMON ENUMS (only if used across unrelated systems)
# ============================================================================

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

# ============================================================================
# SAVE SLOT IDS (if referenced outside SaveManager)
# ============================================================================

const SAVE_SLOT_1 = 0
const SAVE_SLOT_2 = 1
const SAVE_SLOT_3 = 2
const SAVE_SLOT_AUTO = 99