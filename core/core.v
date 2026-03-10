module core

// Типы событий
pub enum EventType {
    on_block_broken
    on_entity_spawn
    on_tick
}

pub type EventHandler = fn(data voidptr)

pub struct EventBus {
mut:
    listeners map[EventType][]EventHandler
}

pub fn (mut e EventBus) subscribe(evt EventType, handler EventHandler) {
    e.listeners[evt] << handler
}

pub fn (mut e EventBus) emit(evt EventType, data voidptr) {
    for handler in e.listeners[evt] {
        handler(data)
    }
}
