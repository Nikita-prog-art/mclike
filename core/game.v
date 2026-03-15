module core

import gg
import world
import registry
import entity
import math
import rand

pub const win_width = 800
pub const win_height = 600

pub struct Game {
pub mut:
	gg          &gg.Context = unsafe { nil }
	world       world.World
	registry    registry.BlockRegistry
	event_bus   EventBus

	player_x    f32 = 400
	player_y    f32 = 300

	keys        map[gg.KeyCode]bool

	selected_block int = 1

	// Touch controls
	touch_w bool
	touch_s bool
	touch_a bool
	touch_d bool
	touch_mine bool
	touch_place bool
	touch_prev bool
	touch_next bool

	android_scale f32

	particles   []entity.Particle
}

pub fn check_collision(mut game Game, x f32, y f32) bool {
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
		cx := int(corner[0]) >> 5
		cy := int(corner[1]) >> 5

		if game.world.get_block(cx, cy, 1) > 0 {
			return true // Collision with a solid block (layer 1)
		}
	}

	return false
}

pub fn frame(mut game Game) {
	// Fix Android scaling accumulation on rotation
	$if android {
		if game.android_scale == 0.0 {
			game.android_scale = gg.android_dpi_scale()
		}
		game.gg.scale = game.android_scale
	}

	// Movement
	speed := f32(4.0)

	mut new_x := game.player_x
	mut new_y := game.player_y

	if game.keys[.w] || game.keys[.up] || game.touch_w { new_y -= speed }
	if game.keys[.s] || game.keys[.down] || game.touch_s { new_y += speed }
	if game.keys[.a] || game.keys[.left] || game.touch_a { new_x -= speed }
	if game.keys[.d] || game.keys[.right] || game.touch_d { new_x += speed }

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

	ww := game.gg.window_size().width
	wh := game.gg.window_size().height

	// Draw world
	camera_x := int(game.player_x) - ww / 2
	camera_y := int(game.player_y) - wh / 2

	start_x := (camera_x >> 5) - 1
	start_y := (camera_y >> 5) - 1
	end_x := start_x + (ww / world.block_size) + 3
	end_y := start_y + (wh / world.block_size) + 3

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

	// Update and draw particles
	mut next_particles := []entity.Particle{}
	for mut p in game.particles {
		p.x += p.vx
		p.y += p.vy
		p.life--

		if p.life > 0 {
			next_particles << *p
			game.gg.draw_rect_filled(p.x - f32(camera_x), p.y - f32(camera_y), p.size, p.size, p.color)
		}
	}
	game.particles = next_particles

	// Draw player
	game.gg.draw_rect_filled(f32(ww) / 2.0 - 10.0, f32(wh) / 2.0 - 10.0, 20, 20, gg.Color{r: 255, g: 0, b: 0, a: 255})

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

	$if android {
		// D-Pad (left side)
		game.gg.draw_rect_filled(20, f32(wh - 160), 60, 60, gg.Color{r: 200, g: 200, b: 200, a: 128}) // left
		game.gg.draw_rect_filled(160, f32(wh - 160), 60, 60, gg.Color{r: 200, g: 200, b: 200, a: 128}) // right
		game.gg.draw_rect_filled(90, f32(wh - 230), 60, 60, gg.Color{r: 200, g: 200, b: 200, a: 128}) // up
		game.gg.draw_rect_filled(90, f32(wh - 90), 60, 60, gg.Color{r: 200, g: 200, b: 200, a: 128}) // down

		// Action buttons (right side)
		game.gg.draw_rect_filled(f32(ww - 180), f32(wh - 120), 70, 70, gg.Color{r: 255, g: 100, b: 100, a: 128}) // mine
		game.gg.draw_rect_filled(f32(ww - 90), f32(wh - 180), 70, 70, gg.Color{r: 100, g: 255, b: 100, a: 128}) // place

		// Block selection (top right)
		game.gg.draw_rect_filled(f32(ww - 140), 20, 50, 50, gg.Color{r: 200, g: 200, b: 200, a: 128}) // prev
		game.gg.draw_rect_filled(f32(ww - 70), 20, 50, 50, gg.Color{r: 200, g: 200, b: 200, a: 128}) // next
	}

	game.gg.end()
}

pub fn on_event(e &gg.Event, mut game Game) {
	if e.typ == .resized {
		game.touch_w = false
		game.touch_s = false
		game.touch_a = false
		game.touch_d = false
		game.touch_mine = false
		game.touch_place = false
		game.touch_prev = false
		game.touch_next = false
	}

	if e.typ == .key_down {
		game.keys[e.key_code] = true
		match e.key_code {
			.escape { game.gg.quit() }
			else {}
		}
	} else if e.typ == .key_up {
		game.keys[e.key_code] = false
	} else if e.typ == .mouse_down {
		ww := game.gg.window_size().width
		wh := game.gg.window_size().height
		camera_x := int(game.player_x) - ww / 2
		camera_y := int(game.player_y) - wh / 2

		world_x := int(e.mouse_x + f32(camera_x)) >> 5
		world_y := int(e.mouse_y + f32(camera_y)) >> 5

		if e.mouse_button == .left {
			// Mine block
			block_id := game.world.get_block(world_x, world_y, 1)
			if block_id > 0 {
				color := game.registry.blocks[block_id].color
				game.world.set_block(world_x, world_y, 1, 0)

				// Spawn particles
				for _ in 0 .. 15 {
					game.particles << entity.Particle{
						x: f32(world_x * world.block_size) + rand.f32() * f32(world.block_size)
						y: f32(world_y * world.block_size) + rand.f32() * f32(world.block_size)
						vx: (rand.f32() - 0.5) * 2.0
						vy: (rand.f32() - 0.5) * 2.0
						life: rand.int_in_range(20, 40) or { 30 }
						size: rand.f32() * 3.0 + 1.0
						color: color
					}
				}
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
	} else if e.typ == .touches_began || e.typ == .touches_moved || e.typ == .touches_ended {
		game.touch_w = false
		game.touch_s = false
		game.touch_a = false
		game.touch_d = false
		game.touch_mine = false
		game.touch_place = false
		game.touch_prev = false
		game.touch_next = false

		ww := game.gg.window_size().width
		wh := game.gg.window_size().height

		for i in 0 .. e.num_touches {
			t := e.touches[i]

			// sapp touch coordinates are in physical pixels, we need to divide by DPI scale to match gg logical pixels
			scale := game.gg.scale
			x := t.pos_x / scale
			y := t.pos_y / scale

			// Skip tracking ended touches for movement flags
			if e.typ == .touches_ended && t.changed {
				continue
			}

			// Left
			if x >= 20.0 && x <= 80.0 && y >= f32(wh - 160) && y <= f32(wh - 100) { game.touch_a = true }
			// Right
			if x >= 160.0 && x <= 220.0 && y >= f32(wh - 160) && y <= f32(wh - 100) { game.touch_d = true }
			// Up
			if x >= 90.0 && x <= 150.0 && y >= f32(wh - 230) && y <= f32(wh - 170) { game.touch_w = true }
			// Down
			if x >= 90.0 && x <= 150.0 && y >= f32(wh - 90) && y <= f32(wh - 30) { game.touch_s = true }

			// Mine
			if x >= f32(ww - 180) && x <= f32(ww - 110) && y >= f32(wh - 120) && y <= f32(wh - 50) {
				game.touch_mine = true
				if e.typ == .touches_began && t.changed {
					// Mine the block slightly above the player, or the current selected target if we had crosshairs
					world_x := int(game.player_x) >> 5
					world_y := (int(game.player_y) >> 5) - 1 // Mine above

					block_id := game.world.get_block(world_x, world_y, 1)
					if block_id > 0 {
						color := game.registry.blocks[block_id].color
						game.world.set_block(world_x, world_y, 1, 0)

						for _ in 0 .. 15 {
							game.particles << entity.Particle{
								x: f32(world_x * world.block_size) + rand.f32() * f32(world.block_size)
								y: f32(world_y * world.block_size) + rand.f32() * f32(world.block_size)
								vx: (rand.f32() - 0.5) * 2.0
								vy: (rand.f32() - 0.5) * 2.0
								life: rand.int_in_range(20, 40) or { 30 }
								size: rand.f32() * 3.0 + 1.0
								color: color
							}
						}
					}
				}
			}
			// Place
			if x >= f32(ww - 90) && x <= f32(ww - 20) && y >= f32(wh - 180) && y <= f32(wh - 110) {
				game.touch_place = true
				if e.typ == .touches_began && t.changed {
					world_x := int(game.player_x) >> 5
					world_y := (int(game.player_y) >> 5) - 1 // Place above

					// Don't place inside player
					p_x := int(game.player_x) >> 5
					p_y := int(game.player_y) >> 5
					if !(world_x == p_x && world_y == p_y) {
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
				}
			}

			// Prev block
			if x >= f32(ww - 140) && x <= f32(ww - 90) && y >= 20.0 && y <= 70.0 {
				game.touch_prev = true
				if e.typ == .touches_began && t.changed {
					game.selected_block--
					if game.selected_block < 1 {
						game.selected_block = game.registry.blocks.len - 1
					}
				}
			}
			// Next block
			if x >= f32(ww - 70) && x <= f32(ww - 20) && y >= 20.0 && y <= 70.0 {
				game.touch_next = true
				if e.typ == .touches_began && t.changed {
					game.selected_block++
					if game.selected_block >= game.registry.blocks.len {
						game.selected_block = 1
					}
				}
			}

			// Allow direct screen tapping to mine/place where crosshairs are (fallback to direct touch map)
			if !(x >= 20.0 && x <= 220.0 && y >= f32(wh - 230)) && !(x >= f32(ww - 180) && y >= f32(wh - 180)) && !(x >= f32(ww - 140) && y <= 70.0) {
				if e.typ == .touches_began && t.changed {
					camera_x := int(game.player_x) - ww / 2
					camera_y := int(game.player_y) - wh / 2

					world_x := int(x + f32(camera_x)) >> 5
					world_y := int(y + f32(camera_y)) >> 5

					// Try to mine first
					block_id := game.world.get_block(world_x, world_y, 1)
					if block_id > 0 {
						color := game.registry.blocks[block_id].color
						game.world.set_block(world_x, world_y, 1, 0)

						// Spawn particles
						for _ in 0 .. 15 {
							game.particles << entity.Particle{
								x: f32(world_x * world.block_size) + rand.f32() * f32(world.block_size)
								y: f32(world_y * world.block_size) + rand.f32() * f32(world.block_size)
								vx: (rand.f32() - 0.5) * 2.0
								vy: (rand.f32() - 0.5) * 2.0
								life: rand.int_in_range(20, 40) or { 30 }
								size: rand.f32() * 3.0 + 1.0
								color: color
							}
						}
					} else {
						// Otherwise try to place
						p_x := int(game.player_x) >> 5
						p_y := int(game.player_y) >> 5
						if !(world_x == p_x && world_y == p_y) {
							if game.selected_block < game.registry.blocks.len {
								if game.registry.blocks[game.selected_block].is_solid {
									game.world.set_block(world_x, world_y, 1, game.selected_block)
								} else {
									game.world.set_block(world_x, world_y, 0, game.selected_block)
								}
							}
						}
					}
				}
			}
		}
	}
}
