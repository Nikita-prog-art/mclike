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
}

fn frame(mut game Game) {
	game.gg.begin()
	// game.draw_scene()
	game.gg.end()
}

fn on_event(e &gg.Event, mut game Game) {
	if e.typ == .key_down {
		match e.key_code {
			.escape {
				game.gg.quit()
			}
			else {}
		}
	}
}

fn main() {
	mut game := &Game{}
	game.gg = gg.new_context(
		bg_color:      gg.white
		width:         win_width
		height:        win_height
		create_window: true
		window_title:  'MCLike'
		user_data:     game
		frame_fn:      frame
		event_fn:      on_event
	)

	// Initialize subsystems
	game.world = world.World{}
	game.registry = registry.BlockRegistry{}
	game.event_bus = core.EventBus{}

	game.gg.run()
}
