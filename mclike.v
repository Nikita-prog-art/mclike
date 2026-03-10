module main

import gg
import core
import world
import registry

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
}

fn frame(mut game Game) {
	// Movement
	speed := f32(4.0)
	if game.keys[.w] { game.player_y -= speed }
	if game.keys[.s] { game.player_y += speed }
	if game.keys[.a] { game.player_x -= speed }
	if game.keys[.d] { game.player_x += speed }

	game.gg.begin()

	// Draw world
	camera_x := game.player_x - win_width / 2
	camera_y := game.player_y - win_height / 2

	start_x := int(camera_x / world.block_size) - 1
	start_y := int(camera_y / world.block_size) - 1
	end_x := start_x + (win_width / world.block_size) + 2
	end_y := start_y + (win_height / world.block_size) + 2

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

					game.gg.draw_rect_filled(f32(screen_x), f32(screen_y), f32(world.block_size), f32(world.block_size), color)
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
		camera_x := game.player_x - win_width / 2
		camera_y := game.player_y - win_height / 2

		world_x := int((e.mouse_x + camera_x) / world.block_size)
		world_y := int((e.mouse_y + camera_y) / world.block_size)

		if e.mouse_button == .left {
			// Mine block
			if game.world.get_block(world_x, world_y, 1) > 0 {
				game.world.set_block(world_x, world_y, 1, 0)
			}
		} else if e.mouse_button == .right {
			// Place block
			if game.world.get_block(world_x, world_y, 1) == 0 {
				game.world.set_block(world_x, world_y, 1, 2)
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
	game.event_bus = core.EventBus{}

	game.gg.run()
}
