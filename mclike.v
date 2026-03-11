module main

import gg
import core
import world
import registry
import math

const win_width = 800
const win_height = 600

struct Game {
mut:
	gg          &gg.Context = unsafe { nil }
	world       world.World
	registry    registry.BlockRegistry
	event_bus   core.EventBus

	player_x    f32 = 400
	player_y    f32 = 300

	keys        map[gg.KeyCode]bool

	selected_block int = 1
}

fn check_collision(mut game Game, x f32, y f32) bool {
	// Player size is 20x20, centered at player_x, player_y
	// We check the 4 corners of the player bounding box
	corners := [
		[x - 9.0, y - 9.0],
		[x + 9.0, y - 9.0],
		[x - 9.0, y + 9.0],
		[x + 9.0, y + 9.0]
	]

	for corner in corners {
		cx := int(math.floor(corner[0] / f32(world.block_size)))
		cy := int(math.floor(corner[1] / f32(world.block_size)))

		if game.world.get_block(cx, cy, 1) > 0 {
			return true // Collision with a solid block (layer 1)
		}
	}

	return false
}

fn frame(mut game Game) {
	// Movement
	speed := f32(4.0)

	mut new_x := game.player_x
	mut new_y := game.player_y

	if game.keys[.w] || game.keys[.up] { new_y -= speed }
	if game.keys[.s] || game.keys[.down] { new_y += speed }
	if game.keys[.a] || game.keys[.left] { new_x -= speed }
	if game.keys[.d] || game.keys[.right] { new_x += speed }

	// Apply X movement if no collision
	if !check_collision(mut game, new_x, game.player_y) {
		game.player_x = new_x
	}
	// Apply Y movement if no collision
	if !check_collision(mut game, game.player_x, new_y) {
		game.player_y = new_y
	}

	game.gg.begin()

	// Draw world
	camera_x := int(math.floor(game.player_x - win_width / 2))
	camera_y := int(math.floor(game.player_y - win_height / 2))

	start_x := int(math.floor(f32(camera_x) / f32(world.block_size))) - 1
	start_y := int(math.floor(f32(camera_y) / f32(world.block_size))) - 1
	end_x := start_x + (win_width / world.block_size) + 3
	end_y := start_y + (win_height / world.block_size) + 3

	for layer in 0 .. 2 {
		for y in start_y .. end_y {
			for x in start_x .. end_x {
				block_id := game.world.get_block(x, y, layer)
				if block_id > 0 {
					mut color := gg.Color{r: 0, g: 0, b: 0, a: 255}
					if block_id == 1 { // grass
						color = gg.Color{r: 34, g: 139, b: 34, a: 255}
					} else if block_id == 2 { // wall
						color = gg.Color{r: 128, g: 128, b: 128, a: 255}
					}

					screen_x := (x * world.block_size) - camera_x
					screen_y := (y * world.block_size) - camera_y

					// Adding +1 to block size to prevent white lines/tearing due to sub-pixel rendering or floating point inaccuracies
					game.gg.draw_rect_filled(f32(screen_x), f32(screen_y), f32(world.block_size + 1), f32(world.block_size + 1), color)
				}
			}
		}
	}

	// Draw player
	game.gg.draw_rect_filled(win_width / 2 - 10, win_height / 2 - 10, 20, 20, gg.Color{r: 255, g: 0, b: 0, a: 255})

	game.gg.end()
}

fn on_event(e &gg.Event, mut game Game) {
	if e.typ == .key_down {
		game.keys[e.key_code] = true
		match e.key_code {
			.escape { game.gg.quit() }
			else {}
		}
	} else if e.typ == .key_up {
		game.keys[e.key_code] = false
	} else if e.typ == .mouse_down {
		camera_x := int(math.floor(game.player_x - win_width / 2))
		camera_y := int(math.floor(game.player_y - win_height / 2))

		world_x := int(math.floor(f32(e.mouse_x + camera_x) / f32(world.block_size)))
		world_y := int(math.floor(f32(e.mouse_y + camera_y) / f32(world.block_size)))

		if e.mouse_button == .left {
			// Mine block
			if game.world.get_block(world_x, world_y, 1) > 0 {
				game.world.set_block(world_x, world_y, 1, 0)
			}
		} else if e.mouse_button == .right {
			// Place block
			if game.world.get_block(world_x, world_y, 1) == 0 {
				if game.registry.blocks[game.selected_block].is_solid {
					game.world.set_block(world_x, world_y, 1, game.selected_block)
				} else {
					game.world.set_block(world_x, world_y, 0, game.selected_block)
				}
			}
		}
	} else if e.typ == .mouse_scroll {
		if e.scroll_y > 0 {
			game.selected_block++
			if game.selected_block >= game.registry.blocks.len {
				game.selected_block = 1
			}
		} else if e.scroll_y < 0 {
			game.selected_block--
			if game.selected_block < 1 {
				game.selected_block = game.registry.blocks.len - 1
			}
		}
	}
}

fn main() {
	mut game := &Game{
		keys: map[gg.KeyCode]bool{}
	}
	game.gg = gg.new_context(
		bg_color:      gg.Color{r: 255, g: 255, b: 255, a: 255}
		width:         win_width
		height:        win_height
		create_window: true
		window_title:  'MCLike'
		user_data:     game
		frame_fn:      frame
		event_fn:      on_event
	)

	game.world = world.World{}
	game.registry = registry.BlockRegistry{}
	// Pre-Classic blocks
	game.registry.register(registry.Block{id: 0, name: 'Air', is_solid: false, color: gg.Color{r: 0, g: 0, b: 0, a: 0}})
	game.registry.register(registry.Block{id: 1, name: 'Stone', is_solid: true, color: gg.Color{r: 120, g: 120, b: 120, a: 255}})
	game.registry.register(registry.Block{id: 2, name: 'Grass Block', is_solid: true, color: gg.Color{r: 34, g: 139, b: 34, a: 255}})
	game.registry.register(registry.Block{id: 3, name: 'Dirt', is_solid: true, color: gg.Color{r: 139, g: 69, b: 19, a: 255}})
	game.registry.register(registry.Block{id: 4, name: 'Oak Planks', is_solid: true, color: gg.Color{r: 205, g: 133, b: 63, a: 255}})
	game.registry.register(registry.Block{id: 5, name: 'Cobblestone', is_solid: true, color: gg.Color{r: 100, g: 100, b: 100, a: 255}})
	game.registry.register(registry.Block{id: 6, name: 'Oak Sapling', is_solid: false, color: gg.Color{r: 0, g: 255, b: 0, a: 255}})
	// Early Classic
	game.registry.register(registry.Block{id: 7, name: 'Bedrock', is_solid: true, color: gg.Color{r: 50, g: 50, b: 50, a: 255}})
	game.registry.register(registry.Block{id: 8, name: 'Water', is_solid: false, color: gg.Color{r: 0, g: 0, b: 255, a: 128}})
	game.registry.register(registry.Block{id: 9, name: 'Lava', is_solid: false, color: gg.Color{r: 255, g: 69, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 10, name: 'Sand', is_solid: true, color: gg.Color{r: 238, g: 214, b: 175, a: 255}})
	game.registry.register(registry.Block{id: 11, name: 'Gravel', is_solid: true, color: gg.Color{r: 169, g: 169, b: 169, a: 255}})
	game.registry.register(registry.Block{id: 12, name: 'Coal Ore', is_solid: true, color: gg.Color{r: 80, g: 80, b: 80, a: 255}})
	game.registry.register(registry.Block{id: 13, name: 'Iron Ore', is_solid: true, color: gg.Color{r: 180, g: 150, b: 120, a: 255}})
	game.registry.register(registry.Block{id: 14, name: 'Gold Ore', is_solid: true, color: gg.Color{r: 255, g: 215, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 15, name: 'Oak Log', is_solid: true, color: gg.Color{r: 101, g: 67, b: 33, a: 255}})
	game.registry.register(registry.Block{id: 16, name: 'Oak Leaves', is_solid: true, color: gg.Color{r: 0, g: 100, b: 0, a: 255}})
	// Multiplayer Test
	game.registry.register(registry.Block{id: 17, name: 'Sponge', is_solid: true, color: gg.Color{r: 255, g: 255, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 18, name: 'Glass', is_solid: true, color: gg.Color{r: 173, g: 216, b: 230, a: 128}})
	game.registry.register(registry.Block{id: 19, name: 'White Cloth', is_solid: true, color: gg.Color{r: 255, g: 255, b: 255, a: 255}})
	game.registry.register(registry.Block{id: 20, name: 'Light Gray Cloth', is_solid: true, color: gg.Color{r: 211, g: 211, b: 211, a: 255}})
	game.registry.register(registry.Block{id: 21, name: 'Dark Gray Cloth', is_solid: true, color: gg.Color{r: 105, g: 105, b: 105, a: 255}})
	game.registry.register(registry.Block{id: 22, name: 'Red Cloth', is_solid: true, color: gg.Color{r: 255, g: 0, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 23, name: 'Orange Cloth', is_solid: true, color: gg.Color{r: 255, g: 165, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 24, name: 'Yellow Cloth', is_solid: true, color: gg.Color{r: 255, g: 255, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 25, name: 'Chartreuse Cloth', is_solid: true, color: gg.Color{r: 127, g: 255, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 26, name: 'Green Cloth', is_solid: true, color: gg.Color{r: 0, g: 128, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 27, name: 'Spring Green Cloth', is_solid: true, color: gg.Color{r: 0, g: 255, b: 127, a: 255}})
	game.registry.register(registry.Block{id: 28, name: 'Cyan Cloth', is_solid: true, color: gg.Color{r: 0, g: 255, b: 255, a: 255}})
	game.registry.register(registry.Block{id: 29, name: 'Capri Cloth', is_solid: true, color: gg.Color{r: 0, g: 191, b: 255, a: 255}})
	game.registry.register(registry.Block{id: 30, name: 'Ultramarine Cloth', is_solid: true, color: gg.Color{r: 18, g: 10, b: 143, a: 255}})
	game.registry.register(registry.Block{id: 31, name: 'Violet Cloth', is_solid: true, color: gg.Color{r: 238, g: 130, b: 238, a: 255}})
	game.registry.register(registry.Block{id: 32, name: 'Purple Cloth', is_solid: true, color: gg.Color{r: 128, g: 0, b: 128, a: 255}})
	game.registry.register(registry.Block{id: 33, name: 'Magenta Cloth', is_solid: true, color: gg.Color{r: 255, g: 0, b: 255, a: 255}})
	game.registry.register(registry.Block{id: 34, name: 'Rose Cloth', is_solid: true, color: gg.Color{r: 255, g: 0, b: 127, a: 255}})
	game.registry.register(registry.Block{id: 35, name: 'Block of Gold', is_solid: true, color: gg.Color{r: 255, g: 215, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 36, name: 'Dandelion', is_solid: false, color: gg.Color{r: 255, g: 255, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 37, name: 'Rose', is_solid: false, color: gg.Color{r: 255, g: 0, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 38, name: 'Red Mushroom', is_solid: false, color: gg.Color{r: 255, g: 0, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 39, name: 'Brown Mushroom', is_solid: false, color: gg.Color{r: 139, g: 69, b: 19, a: 255}})
	// Survival Test
	game.registry.register(registry.Block{id: 40, name: 'Smooth Stone Slab', is_solid: true, color: gg.Color{r: 150, g: 150, b: 150, a: 255}})
	game.registry.register(registry.Block{id: 41, name: 'Block of Iron', is_solid: true, color: gg.Color{r: 220, g: 220, b: 220, a: 255}})
	game.registry.register(registry.Block{id: 42, name: 'TNT', is_solid: true, color: gg.Color{r: 255, g: 69, b: 0, a: 255}})
	game.registry.register(registry.Block{id: 43, name: 'Mossy Cobblestone', is_solid: true, color: gg.Color{r: 80, g: 120, b: 80, a: 255}})
	game.registry.register(registry.Block{id: 44, name: 'Bricks', is_solid: true, color: gg.Color{r: 178, g: 34, b: 34, a: 255}})
	game.registry.register(registry.Block{id: 45, name: 'Bookshelf', is_solid: true, color: gg.Color{r: 139, g: 69, b: 19, a: 255}})
	// Late Classic
	game.registry.register(registry.Block{id: 46, name: 'Obsidian', is_solid: true, color: gg.Color{r: 25, g: 25, b: 50, a: 255}})
	game.event_bus = core.EventBus{}

	game.gg.run()
}
