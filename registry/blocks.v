module registry

import gg

pub fn (mut r BlockRegistry) register_pre_classic_blocks() {
	r.register(Block{id: 0, name: 'Air', is_solid: false, color: gg.Color{r: 0, g: 0, b: 0, a: 0}})
	r.register(Block{id: 1, name: 'Stone', is_solid: true, color: gg.Color{r: 120, g: 120, b: 120, a: 255}})
	r.register(Block{id: 2, name: 'Grass Block', is_solid: true, color: gg.Color{r: 34, g: 139, b: 34, a: 255}})
	r.register(Block{id: 3, name: 'Dirt', is_solid: true, color: gg.Color{r: 139, g: 69, b: 19, a: 255}})
	r.register(Block{id: 4, name: 'Oak Planks', is_solid: true, color: gg.Color{r: 205, g: 133, b: 63, a: 255}})
	r.register(Block{id: 5, name: 'Cobblestone', is_solid: true, color: gg.Color{r: 100, g: 100, b: 100, a: 255}})
	r.register(Block{id: 6, name: 'Oak Sapling', is_solid: false, color: gg.Color{r: 0, g: 255, b: 0, a: 255}})
}

pub fn (mut r BlockRegistry) register_early_classic_blocks() {
	r.register(Block{id: 7, name: 'Bedrock', is_solid: true, color: gg.Color{r: 50, g: 50, b: 50, a: 255}})
	r.register(Block{id: 8, name: 'Water', is_solid: false, color: gg.Color{r: 0, g: 0, b: 255, a: 128}})
	r.register(Block{id: 9, name: 'Lava', is_solid: false, color: gg.Color{r: 255, g: 69, b: 0, a: 255}})
	r.register(Block{id: 10, name: 'Sand', is_solid: true, color: gg.Color{r: 238, g: 214, b: 175, a: 255}})
	r.register(Block{id: 11, name: 'Gravel', is_solid: true, color: gg.Color{r: 169, g: 169, b: 169, a: 255}})
	r.register(Block{id: 12, name: 'Coal Ore', is_solid: true, color: gg.Color{r: 80, g: 80, b: 80, a: 255}})
	r.register(Block{id: 13, name: 'Iron Ore', is_solid: true, color: gg.Color{r: 180, g: 150, b: 120, a: 255}})
	r.register(Block{id: 14, name: 'Gold Ore', is_solid: true, color: gg.Color{r: 255, g: 215, b: 0, a: 255}})
	r.register(Block{id: 15, name: 'Oak Log', is_solid: true, color: gg.Color{r: 101, g: 67, b: 33, a: 255}})
	r.register(Block{id: 16, name: 'Oak Leaves', is_solid: true, color: gg.Color{r: 0, g: 100, b: 0, a: 255}})
}

pub fn (mut r BlockRegistry) register_multiplayer_test_blocks() {
	r.register(Block{id: 17, name: 'Sponge', is_solid: true, color: gg.Color{r: 255, g: 255, b: 0, a: 255}})
	r.register(Block{id: 18, name: 'Glass', is_solid: true, color: gg.Color{r: 173, g: 216, b: 230, a: 128}})
	r.register(Block{id: 19, name: 'White Cloth', is_solid: true, color: gg.Color{r: 255, g: 255, b: 255, a: 255}})
	r.register(Block{id: 20, name: 'Light Gray Cloth', is_solid: true, color: gg.Color{r: 211, g: 211, b: 211, a: 255}})
	r.register(Block{id: 21, name: 'Dark Gray Cloth', is_solid: true, color: gg.Color{r: 105, g: 105, b: 105, a: 255}})
	r.register(Block{id: 22, name: 'Red Cloth', is_solid: true, color: gg.Color{r: 255, g: 0, b: 0, a: 255}})
	r.register(Block{id: 23, name: 'Orange Cloth', is_solid: true, color: gg.Color{r: 255, g: 165, b: 0, a: 255}})
	r.register(Block{id: 24, name: 'Yellow Cloth', is_solid: true, color: gg.Color{r: 255, g: 255, b: 0, a: 255}})
	r.register(Block{id: 25, name: 'Chartreuse Cloth', is_solid: true, color: gg.Color{r: 127, g: 255, b: 0, a: 255}})
	r.register(Block{id: 26, name: 'Green Cloth', is_solid: true, color: gg.Color{r: 0, g: 128, b: 0, a: 255}})
	r.register(Block{id: 27, name: 'Spring Green Cloth', is_solid: true, color: gg.Color{r: 0, g: 255, b: 127, a: 255}})
	r.register(Block{id: 28, name: 'Cyan Cloth', is_solid: true, color: gg.Color{r: 0, g: 255, b: 255, a: 255}})
	r.register(Block{id: 29, name: 'Capri Cloth', is_solid: true, color: gg.Color{r: 0, g: 191, b: 255, a: 255}})
	r.register(Block{id: 30, name: 'Ultramarine Cloth', is_solid: true, color: gg.Color{r: 18, g: 10, b: 143, a: 255}})
	r.register(Block{id: 31, name: 'Violet Cloth', is_solid: true, color: gg.Color{r: 238, g: 130, b: 238, a: 255}})
	r.register(Block{id: 32, name: 'Purple Cloth', is_solid: true, color: gg.Color{r: 128, g: 0, b: 128, a: 255}})
	r.register(Block{id: 33, name: 'Magenta Cloth', is_solid: true, color: gg.Color{r: 255, g: 0, b: 255, a: 255}})
	r.register(Block{id: 34, name: 'Rose Cloth', is_solid: true, color: gg.Color{r: 255, g: 0, b: 127, a: 255}})
	r.register(Block{id: 35, name: 'Block of Gold', is_solid: true, color: gg.Color{r: 255, g: 215, b: 0, a: 255}})
	r.register(Block{id: 36, name: 'Dandelion', is_solid: false, color: gg.Color{r: 255, g: 255, b: 0, a: 255}})
	r.register(Block{id: 37, name: 'Rose', is_solid: false, color: gg.Color{r: 255, g: 0, b: 0, a: 255}})
	r.register(Block{id: 38, name: 'Red Mushroom', is_solid: false, color: gg.Color{r: 255, g: 0, b: 0, a: 255}})
	r.register(Block{id: 39, name: 'Brown Mushroom', is_solid: false, color: gg.Color{r: 139, g: 69, b: 19, a: 255}})
}

pub fn (mut r BlockRegistry) register_survival_test_blocks() {
	r.register(Block{id: 40, name: 'Smooth Stone Slab', is_solid: true, color: gg.Color{r: 150, g: 150, b: 150, a: 255}})
	r.register(Block{id: 41, name: 'Block of Iron', is_solid: true, color: gg.Color{r: 220, g: 220, b: 220, a: 255}})
	r.register(Block{id: 42, name: 'TNT', is_solid: true, color: gg.Color{r: 255, g: 69, b: 0, a: 255}})
	r.register(Block{id: 43, name: 'Mossy Cobblestone', is_solid: true, color: gg.Color{r: 80, g: 120, b: 80, a: 255}})
	r.register(Block{id: 44, name: 'Bricks', is_solid: true, color: gg.Color{r: 178, g: 34, b: 34, a: 255}})
	r.register(Block{id: 45, name: 'Bookshelf', is_solid: true, color: gg.Color{r: 139, g: 69, b: 19, a: 255}})
}

pub fn (mut r BlockRegistry) register_late_classic_blocks() {
	r.register(Block{id: 46, name: 'Obsidian', is_solid: true, color: gg.Color{r: 25, g: 25, b: 50, a: 255}})
}
