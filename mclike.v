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
	// Block size is 32x32.
	// We use precise coordinates. Since player is 20x20 centered, its coordinates are [-10, +10]
	corners := [
		[x - 10.0, y - 10.0],
		[x + 10.0, y - 10.0],
		[x - 10.0, y + 10.0],
		[x + 10.0, y + 10.0]
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

	// Resolve X and Y individually to allow sliding against walls
	// and prevent diagonal phasing through corners.

	// Check X movement
	if !check_collision(mut game, new_x, game.player_y) {
		game.player_x = new_x
	} else {
		// If collision in X, stop X movement
		new_x = game.player_x
	}

	// Check Y movement using the updated (or blocked) X position
	if !check_collision(mut game, new_x, new_y) {
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
				if block_id > 0 && block_id < game.registry.blocks.len {
					color := game.registry.blocks[block_id].color

					screen_x := (x * world.block_size) - camera_x
					screen_y := (y * world.block_size) - camera_y

					// Use exact block sizes for drawing to align perfectly. Since coordinates are floored,
					// tearing shouldn't happen with exact pixel sizes.
					game.gg.draw_rect_filled(f32(screen_x), f32(screen_y), f32(world.block_size), f32(world.block_size), color)
				}
			}
		}
	}

	// Draw player
	game.gg.draw_rect_filled(win_width / 2 - 10, win_height / 2 - 10, 20, 20, gg.Color{r: 255, g: 0, b: 0, a: 255})

	// Draw currently selected block
	if game.selected_block > 0 && game.selected_block < game.registry.blocks.len {
		b_color := game.registry.blocks[game.selected_block].color
		b_name := game.registry.blocks[game.selected_block].name

		game.gg.draw_rect_filled(10, 10, 40, 40, b_color)
		game.gg.draw_rect_empty(10, 10, 40, 40, gg.Color{r:0, g:0, b:0, a:255})

		game.gg.draw_text(60, 20, b_name, gg.TextCfg{
			color: gg.Color{r:0, g:0, b:0, a:255}
			size: 20
		})
	}

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
				if game.selected_block < game.registry.blocks.len {
					if game.registry.blocks[game.selected_block].is_solid {
						game.world.set_block(world_x, world_y, 1, game.selected_block)
					} else {
						game.world.set_block(world_x, world_y, 0, game.selected_block)
					}
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
	game.registry.register_pre_classic_blocks()
	game.registry.register_early_classic_blocks()
	game.registry.register_multiplayer_test_blocks()
	game.registry.register_survival_test_blocks()
	game.registry.register_late_classic_blocks()
	game.event_bus = core.EventBus{}

	game.gg.run()
}
