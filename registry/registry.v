module registry

pub struct Block {
pub:
    id          int
    name        string
    is_solid    bool
    texture_idx int
    // Сюда можно добавить функции-коллбеки для модов (например, on_interact)
}

pub struct BlockRegistry {
mut:
    blocks []Block
    by_name map[string]int
}

pub fn (mut r BlockRegistry) register(b Block) {
    r.blocks << b
    r.by_name[b.name] = b.id
}
