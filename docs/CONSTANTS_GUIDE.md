# Constants Organization Guide

## Principle: Minimize Global Namespace Pollution

Constants should live as close to their usage as possible. Only promote to global when absolutely necessary.

---

## ❌ BAD: Everything in Constants.gd

```gdscript
# constants.gd - DON'T DO THIS
const PLAYER_JUMP_VELOCITY = -400.0
const PLAYER_MOVE_SPEED = 200.0
const ENEMY_PATROL_SPEED = 100.0
const ENEMY_CHASE_SPEED = 200.0
const PADDLE_SPEED = 500.0
const BALL_SPEED = 300.0
const BRICK_HEALTH = 3
const POWERUP_DURATION = 5.0
# ... 200 more unrelated constants
```

**Problems:**
- Massive coupling - every script depends on Constants
- Hard to understand what a system actually needs
- Naming conflicts (SPEED vs MOVE_SPEED vs CHASE_SPEED)
- Changes affect unrelated systems

---

## ✅ GOOD: Localized Constants

### Example 1: Player System

```gdscript
# player.gd
extends CharacterBody2D
class_name Player

# Movement constants - only player needs these
const MOVE_SPEED = 200.0
const ACCELERATION = 50.0
const FRICTION = 30.0
const JUMP_VELOCITY = -400.0
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.15

# Animation states
enum AnimState { IDLE, WALK, RUN, JUMP, FALL, ATTACK }

# Uses global gravity from Constants
func _physics_process(delta):
    velocity.y += Constants.GRAVITY * delta
```

### Example 2: Shared System Constants (Static Class Pattern)

```gdscript
# systems/vfx_config.gd
class_name VFXConfig
extends Node

# Shared by all particle effects in your game
static var PARTICLE_LOW = 10
static var PARTICLE_MEDIUM = 25
static var PARTICLE_HIGH = 50

static var SCREEN_SHAKE_LIGHT = 2.0
static var SCREEN_SHAKE_MEDIUM = 5.0
static var SCREEN_SHAKE_HEAVY = 10.0

# Usage from anywhere:
# VFXConfig.PARTICLE_HIGH
# VFXConfig.SCREEN_SHAKE_MEDIUM
```

```gdscript
# systems/damage_config.gd
class_name DamageConfig
extends Node

enum DamageType { PHYSICAL, FIRE, ICE, ELECTRIC, POISON }

static var CRIT_MULTIPLIER = 2.0
static var CRIT_CHANCE_BASE = 0.1

# Color flash configs
static var DAMAGE_FLASH_COLOR = Color.RED
static var DAMAGE_FLASH_DURATION = 0.1
static var HEAL_FLASH_COLOR = Color.GREEN
static var HEAL_FLASH_DURATION = 0.15
```

### Example 3: Feature-Specific Config

```gdscript
# arkanoid/paddle.gd
extends CharacterBody2D

const SPEED = 500.0
const WIDTH = 100.0
const BOUNCE_ANGLE_MAX = 75.0  # Degrees

# arkanoid/ball.gd
extends CharacterBody2D

const INITIAL_SPEED = 300.0
const MAX_SPEED = 800.0
const SPEED_INCREMENT = 50.0  # Per brick hit

# arkanoid/brick.gd
extends StaticBody2D

enum BrickType { NORMAL, HARD, UNBREAKABLE }
const POINTS_PER_HIT = 10
```

---

## When to Promote to Global Constants

### ✅ Always Global:
- **Physics layers** - Used everywhere for collision detection
- **Node groups** - Referenced by multiple systems via get_tree()
- **Scene paths** - If loaded from multiple unrelated places
- **Core physics** - Gravity, terminal velocity (if consistent)

### ✅ Sometimes Global:
- **Difficulty settings** - If affecting multiple systems
- **Game state enums** - If multiple managers need to check state
- **Save slot IDs** - If referenced outside SaveManager

### ❌ Never Global:
- **Component-specific values** - Player speed, enemy health
- **UI dimensions** - Button sizes, margins
- **Animation timings** - Fade durations, tween speeds
- **Feature-specific data** - Powerup durations, combo timers

---

## Usage Patterns

### Pattern 1: Local Constants

```gdscript
# enemy_walker.gd
extends CharacterBody2D

const PATROL_SPEED = 100.0
const CHASE_SPEED = 200.0
const DETECTION_RANGE = 300.0

enum AIState { IDLE, PATROL, CHASE, ATTACK }
var current_state = AIState.PATROL
```

### Pattern 2: Static Class (Godot 4.x)

```gdscript
# config/audio_config.gd
class_name AudioConfig

static var SFX_PITCH_VARIANCE = 0.1
static var SFX_VOLUME_VARIANCE = 2.0
static var MUSIC_CROSSFADE_TIME = 1.5

# Usage from any script:
# AudioManager.play_sfx(sound, AudioConfig.SFX_PITCH_VARIANCE)
```

### Pattern 3: Global Constants (Sparingly)

```gdscript
# In player, enemies, projectiles - all need collision layers
func _ready():
    collision_layer = Constants.LAYER_PLAYER
    collision_mask = Constants.LAYER_ENEMY | Constants.LAYER_GROUND
```

---

## Project Structure Example

```
res://src/
├── autoloads/
│   ├── constants.gd           # ONLY cross-cutting values
│   ├── audio_manager.gd
│   └── ...
├── player/
│   └── player.gd              # Player-specific constants here
├── enemies/
│   ├── enemy_base.gd          # Shared enemy constants
│   ├── walker.gd              # Walker-specific constants
│   └── flyer.gd               # Flyer-specific constants
├── systems/
│   ├── vfx_config.gd          # Static class for VFX constants
│   └── damage_config.gd       # Static class for damage constants
└── arkanoid/
    ├── paddle.gd              # Arkanoid-specific constants
    ├── ball.gd
    └── brick.gd
```

---

## Benefits of This Approach

1. **Clear Dependencies** - Easy to see what each system needs
2. **Reduced Coupling** - Systems don't depend on unrelated constants
3. **Better Refactoring** - Change player speed without touching Constants.gd
4. **Self-Documenting** - Constants live next to the code that uses them
5. **Minimal Global State** - Only truly shared values are global

---

## Rule of Thumb

Ask: "If I change this constant, how many unrelated systems are affected?"
- **Zero/One system** → Keep it local
- **Two related systems** → Consider static class
- **Three+ unrelated systems** → Maybe global (but question if they should share it)

Remember: **Globals are dependencies in disguise.** Keep them minimal.