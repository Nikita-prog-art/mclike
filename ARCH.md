# Architecture Document: mclike

This document outlines the architecture for a top-down, extensible 2D game incorporating Minecraft-like mechanics and support for AI agents as fully privileged actors. The game is written in Vlang (V) for high performance and fast compilation, leveraging graphics modules such as `gg`.

## 1. Core Paradigm: Actor-Controller and ECS

The system employs a hybrid architectural approach to maximize flexibility and separation of concerns:

*   **Simplified ECS (Entity-Component-System):** Used for physics, rendering, and inventory management.
*   **Controller Pattern:** Separates the physical "body" of an entity from its "mind." Both human players and AI agents are different implementations of the `Controller` interface, which governs a unified `PlayerEntity` (or `Actor`).
*   **Registry Pattern:** Facilitates modding capabilities. All blocks, items, and recipes are registered during the initialization phase, allowing extensions to seamlessly introduce new content.

## 2. Module Structure

*   `mclike.v`     - Main entry point; handles window initialization and the main application loop.
*   `core/`        - Engine core (Game state, Event Bus).
*   `world/`       - World generation and storage (Chunks, Blocks).
*   `entity/`      - Entities (Player, Mobs, Items).
*   `controller/`  - Input and decision making (PlayerInput, AIBot).
*   `registry/`    - Content registries (BlockRegistry, ItemRegistry).
*   `modding/`     - API for mods and plugins (Event hooks).

## 3. System Design and Data Structures

### 3.1. Block Registry (Content Extensibility)

A central registry handles all block definitions, enabling mods to register custom blocks.

```v
module registry

import gg

pub struct Block {
pub:
    id          int
    name        string
    is_solid    bool
    color       gg.Color
    // Сюда можно добавить функции-коллбеки для модов (например, on_interact)
}

pub struct BlockRegistry {
pub mut:
    blocks []Block
    by_name map[string]int
}

pub fn (mut r BlockRegistry) register(b Block) {
    r.blocks << b
    r.by_name[b.name] = b.id
}
```

### 3.2. World Architecture (Chunks and Layers)

In a top-down perspective, verticality is simulated via layers (Z-index):

*   **Layer 0 (Ground):** Walkable surfaces (e.g., grass, sand, stone).
*   **Layer 1 (Objects):** Entities and structures with collision (e.g., walls, trees, workbenches).

```v
module world

import math

pub const chunk_size = 16
pub const block_size = 32

pub struct Chunk {
pub mut:
    x int
    y int
    layers [2][chunk_size][chunk_size]int
}

pub struct World {
pub mut:
    chunks map[string]&Chunk
}

pub fn (mut w World) get_chunk(cx int, cy int) &Chunk {
    key := '${cx},${cy}'
    if key !in w.chunks {
        mut c := &Chunk{x: cx, y: cy}
        for i in 0 .. chunk_size {
            for j in 0 .. chunk_size {
                c.layers[0][i][j] = 2 // 2 for grass block
                if i == 0 || j == 0 || i == chunk_size - 1 || j == chunk_size - 1 {
                    if cx == 0 && cy == 0 {
                        c.layers[1][i][j] = 1 // 1 for stone wall
                    }
                }
            }
        }
        w.chunks[key] = c
    }
    return w.chunks[key] or { panic("chunk not found despite being created") }
}

pub fn (mut w World) get_block(x int, y int, layer int) int {
    cx := if x < 0 { int(math.floor(f32(x) / f32(chunk_size))) } else { x / chunk_size }
    cy := if y < 0 { int(math.floor(f32(y) / f32(chunk_size))) } else { y / chunk_size }

    mut bx := x % chunk_size
    mut by := y % chunk_size
    if bx < 0 { bx += chunk_size }
    if by < 0 { by += chunk_size }

    c := w.get_chunk(cx, cy)
    return c.layers[layer][by][bx]
}

pub fn (mut w World) set_block(x int, y int, layer int, block_id int) {
    cx := if x < 0 { int(math.floor(f32(x) / f32(chunk_size))) } else { x / chunk_size }
    cy := if y < 0 { int(math.floor(f32(y) / f32(chunk_size))) } else { y / chunk_size }

    mut bx := x % chunk_size
    mut by := y % chunk_size
    if bx < 0 { bx += chunk_size }
    if by < 0 { by += chunk_size }

    mut c := w.get_chunk(cx, cy)
    c.layers[layer][by][bx] = block_id
}
```

### 3.3. Body and Mind Separation (AI Agent Support)

A unified `Controller` interface is responsible for issuing commands to entities.

```v
module controller

import math.vec
import world

pub enum ActionType {
    none
    mine_block
    place_block
    attack
    use_item
}

pub struct Action {
pub:
    act_type ActionType
    target   vec.Vec2[f32] // Coordinates in the world
    item_id  int           // Item being interacted with
}

// Control interface
pub interface Controller {
mut:
    // Returns movement vector (-1.0 to 1.0)
    get_movement() vec.Vec2[f32]
    // Returns an action (mine, build, attack)
    get_action() Action
    // Updates AI state (can be a no-op for human players)
    update(delta_time f32, world_context &world.World, entity_pos vec.Vec2[f32])
}

// --- Human Player ---
pub struct HumanController {
    // References to the input system (keyboard/mouse)
}

pub fn (mut c HumanController) update(dt f32, w &world.World, pos vec.Vec2[f32]) {}

pub fn (mut c HumanController) get_movement() vec.Vec2[f32] {
    // Reads input mappings (e.g., WASD) and returns a vector
    return vec.Vec2[f32]{x: 1.0, y: 0.0}
}

pub fn (mut c HumanController) get_action() Action {
    // Reads input interactions (e.g., mouse clicks)
    return Action{act_type: .none}
}

// --- AI Agent ---
pub struct AIController {
mut:
    target_pos vec.Vec2[f32]
    state      string // e.g., 'mining', 'walking', 'hunting'
}

pub fn (mut c AIController) update(dt f32, w &world.World, pos vec.Vec2[f32]) {
    // AI decision making (e.g., A* pathfinding, Behavior Trees)
}

pub fn (mut c AIController) get_movement() vec.Vec2[f32] {
    // Movement logic towards target_pos
    return vec.Vec2[f32]{x: 0.0, y: 1.0}
}

pub fn (mut c AIController) get_action() Action {
    // Action logic based on state and surroundings
    return Action{act_type: .mine_block, target: c.target_pos}
}
```

### 3.4. Entity Implementation

The entity (`Actor`) is decoupled from its controller, processing logic through the assigned `Controller` implementation.

```v
module entity

import controller
import math.vec
import world

pub struct Actor {
pub mut:
    id         int
    pos        vec.Vec2[f32]
    velocity   vec.Vec2[f32]
    health     int
    inventory  []int // Inventory representing Item IDs

    brain      controller.Controller // Assigned controller implementation
}

pub fn (mut a Actor) update(dt f32, w &world.World) {
    // 1. Process controller logic
    a.brain.update(dt, w, a.pos)

    // 2. Retrieve commands
    move_dir := a.brain.get_movement()
    action := a.brain.get_action()

    // 3. Apply physics and collisions to a.pos based on move_dir
    // 4. Execute actions (e.g., mine blocks in the world if action != none)
}
```

## 4. Modding and Extension API (Event Bus)

Deep modifications (e.g., custom AI, blocks, game rules) are supported via an Event Bus, allowing mods to subscribe to and react to game events.

```v
module core

// Event types
pub enum EventType {
    on_block_broken
    on_entity_spawn
    on_tick
}

pub type EventHandler = fn(data voidptr)

pub struct EventBus {
mut:
    listeners map[EventType][]EventHandler
}

pub fn (mut e EventBus) subscribe(evt EventType, handler EventHandler) {
    e.listeners[evt] << handler
}

pub fn (mut e EventBus) emit(evt EventType, data voidptr) {
    for handler in e.listeners[evt] {
        handler(data)
    }
}
```

**Example implementation for an AI Assistant Mod:**
1.  Initialize mod at game startup.
2.  Register custom summoning recipe in `ItemRegistry`.
3.  Subscribe to the `on_entity_spawn` event.
4.  Upon assistant spawn, assign a custom `AIController` with specific behavioral logic to the spawned entity.

## 5. Minecraft Mechanics in 2D (Top-Down)

*   **Mining:** Handled via a grid system. Interactions (mining/placing) check the distance `if pos.distance(target) <= reach_distance`.
*   **Lighting:** Implementable via Cellular Automata or Flood Fill algorithms, updating a lighting grid within chunks during block placement/destruction.
*   **Crafting:** Array comparisons (recipe matrix vs. crafting grid) utilizing hash tables for performant lookups.
