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
    chunks map[u64]&Chunk
}

@[inline]
pub fn get_chunk_key(cx int, cy int) u64 {
    return (u64(u32(cx)) << 32) | u64(u32(cy))
}

pub fn (mut w World) get_chunk(cx int, cy int) &Chunk {
    key := get_chunk_key(cx, cy)
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
    cx := x >> 4
    cy := y >> 4

    mut bx := x % chunk_size
    mut by := y % chunk_size
    if bx < 0 { bx += chunk_size }
    if by < 0 { by += chunk_size }

    c := w.get_chunk(cx, cy)
    return c.layers[layer][by][bx]
}

pub fn (mut w World) set_block(x int, y int, layer int, block_id int) {
    cx := x >> 4
    cy := y >> 4

    mut bx := x % chunk_size
    mut by := y % chunk_size
    if bx < 0 { bx += chunk_size }
    if by < 0 { by += chunk_size }

    mut c := w.get_chunk(cx, cy)
    c.layers[layer][by][bx] = block_id
}
