module controller

import math.vec
import world

pub enum ActionType {
    none
    mine_block
    place_block
    attack
    use_item
}

pub struct Action {
pub:
    act_type ActionType
    target   vec.Vec2[f32] // Координаты в мире
    item_id  int           // С чем взаимодействуем
}

// Интерфейс управления
pub interface Controller {
mut:
    // Возвращает вектор направления (-1.0 до 1.0)
    get_movement() vec.Vec2[f32]
    // Возвращает действие (копать, строить, бить)
    get_action() Action
    // Обновление состояния ИИ (для человека можно оставить пустым)
    update(delta_time f32, world_context &world.World, entity_pos vec.Vec2[f32])
}

// --- Реальный Игрок ---
pub struct HumanController {
    // Ссылки на систему ввода (клавиатура/мышь)
}

pub fn (mut c HumanController) update(dt f32, w &world.World, pos vec.Vec2[f32]) {}

pub fn (mut c HumanController) get_movement() vec.Vec2[f32] {
    // Читаем WASD, возвращаем вектор
    return vec.Vec2[f32]{x: 1.0, y: 0.0}
}

pub fn (mut c HumanController) get_action() Action {
    // Читаем клики мыши
    return Action{act_type: .none}
}

// --- ИИ Агент ---
pub struct AIController {
mut:
    target_pos vec.Vec2[f32]
    state      string // 'mining', 'walking', 'hunting'
}

pub fn (mut c AIController) update(dt f32, w &world.World, pos vec.Vec2[f32]) {
    // Здесь ИИ использует алгоритм A* для поиска пути
    // или принимает решения на основе дерева поведений (Behavior Tree)
}

pub fn (mut c AIController) get_movement() vec.Vec2[f32] {
    // Логика движения к target_pos
    return vec.Vec2[f32]{x: 0.0, y: 1.0}
}

pub fn (mut c AIController) get_action() Action {
    // Если рядом дерево и state == 'mining' -> вернуть .mine_block
    return Action{act_type: .mine_block, target: c.target_pos}
}
