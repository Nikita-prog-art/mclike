module entity

import controller
import math.vec
import world

pub struct Actor {
pub mut:
    id         int
    pos        vec.Vec2[f32]
    velocity   vec.Vec2[f32]
    health     int
    inventory  []int // Простой инвентарь (ID предметов)

    brain      controller.Controller // Тот самый интерфейс!
}

pub fn (mut a Actor) update(dt f32, w &world.World) {
    // 1. Даем мозгу подумать
    a.brain.update(dt, w, a.pos)

    // 2. Получаем команды
    _ = a.brain.get_movement()
    _ = a.brain.get_action()

    // 3. Применяем физику и коллизии к a.pos с учетом move_dir
    // 4. Выполняем действия (добыча блоков в мире, если action != none)
}
