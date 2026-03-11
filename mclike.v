module main

import gg
import core
import world
import registry

fn main() {
	mut game := &core.Game{
		keys: map[gg.KeyCode]bool{}
	}
	game.gg = gg.new_context(
		bg_color:      gg.Color{r: 255, g: 255, b: 255, a: 255}
		width:         core.win_width
		height:        core.win_height
		create_window: true
		window_title:  'MCLike'
		user_data:     game
		frame_fn:      core.frame
		event_fn:      core.on_event
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
