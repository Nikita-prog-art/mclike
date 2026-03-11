module entity

import gg

pub struct Particle {
pub mut:
	x     f32
	y     f32
	vx    f32
	vy    f32
	life  int
	size  f32
	color gg.Color
}
