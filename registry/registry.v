module registry

import gg

pub struct Block {
pub:
    id          int
    name        string
    is_solid    bool
    color       gg.Color
}

pub struct BlockRegistry {
pub mut:
    blocks []Block
    by_name map[string]int
}

pub fn (mut r BlockRegistry) register(b Block) {
    r.blocks << b
    r.by_name[b.name] = b.id
}
