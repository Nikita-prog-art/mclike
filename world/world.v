module world

pub const chunk_size = 16

pub struct Chunk {
pub mut:
    x int
    y int
    // Двумерный массив слоев (0 - пол, 1 - объекты/стены)
    layers [2][chunk_size][chunk_size]int
}

pub struct World {
mut:
    chunks map[string]&Chunk // Ключ - координаты "x,y"
}

pub fn (mut w World) set_block(x int, y int, layer int, block_id int) {
    // Логика вычисления чанка и установки блока...
}
